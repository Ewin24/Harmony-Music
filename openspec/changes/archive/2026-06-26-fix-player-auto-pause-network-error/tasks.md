# Tasks: Fix Player Auto-Pause on Network Error

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~18 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single commit |
| Delivery strategy | N/A (local fix) |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | All 4 changes in `audio_handler.dart` + manual verify | Single commit | All in one file, ~18 lines, no split needed |

## ✅ 1. Defer `_playList.clear()` until playability confirmed

Move the `_playList.clear()` call from before `checkNGetUrl()` to after the `streamInfo.playable == true` check so the playlist is never discarded when URL resolution fails.

**Files:**
- `lib/services/audio_handler.dart` (lines 464–466 → moved after line 481)

**Changes:**
- Remove `if (_playList.children.isNotEmpty) { await _playList.clear(); }` block from lines 464–466 (before `futureStreamInfo`)
- Re-insert the same block between line 481 and 482 — after the `!streamInfo.playable` return guard, before `currentSongUrl = [...]`
- No other logic changes; the clear still fires on the happy path, just later

**Acceptance Criteria:**
- Covers spec scenarios "Clear deferred until playable confirmed" and "Playlist preserved when URL not playable" (Requirement: Playback queue integrity on URL resolve failure)
- Successful resolution: `_playList.clear()` then `_playList.add(source)` — same as today (no regression)
- Failed resolution (`playable == false`): `_playList.clear()` NOT executed, existing playlist remains intact
- Player can recover from error via manual play/skip without frozen/empty state

**Depends on:** none

**Estimated size:** XS (~3 lines moved)

## ✅ 2. Fix missing `await` in `playbackEventStream.onError`

The error handler at line 191 calls `customAction("playByIndex", ...)` without `await`, creating a race with the subsequent `_player.seek()`. Add the missing `await` so playlist rebuild completes before seek.

**Files:**
- `lib/services/audio_handler.dart` (line 191)

**Changes:**
- Prepend `await` keyword: `customAction("playByIndex", ...)` → `await customAction("playByIndex", ...)`

**Acceptance Criteria:**
- Covers spec scenario "Seek waits for playByIndex completion" (Requirement: Async error handler MUST await navigation action)
- `_player.seek()` executes only after `playByIndex` completes its setup
- No race condition between playlist rebuild and seek position
- Single-keyword change, no behavioral regression on happy path

**Depends on:** none

**Estimated size:** XS (~1 character)

## ✅ 3. Add snackbar cooldown to prevent UI spam on rapid failures

When skipping through multiple songs that fail rapidly, each `notifyPlayError` call stacks snackbars. Add a timestamp guard to throttle network-error snackbars to at most one per 3-second window.

**Files:**
- `lib/services/audio_handler.dart` (field at line ~62, guard before `notifyPlayError` calls)

**Changes:**
- Add `DateTime? _lastNetworkErrorShownAt;` field to `MyAudioHandler` (near line 62)
- Before calling `Get.find<PlayerController>().notifyPlayError(...)`, check: if `_lastNetworkErrorShownAt != null && DateTime.now().difference(_lastNetworkErrorShownAt!) < 3s`, skip the call
- After showing the snackbar, update `_lastNetworkErrorShownAt = DateTime.now();`
- Non-network errors (`VideoUnavailableException`, etc.) are NOT throttled — always show

**Acceptance Criteria:**
- Covers the "no UI spam" sub-criterion of spec Requirement 1 (Auto-skip MUST recover)
- First network error: snackbar shown immediately
- Second network error within 3s: no snackbar (silently suppressed)
- Network error after 3s+ cooldown expired: snackbar shown again
- Non-network errors always bypass cooldown

**Depends on:** none

**Estimated size:** XS (~5 lines)

## ✅ 4. Implement retry with 1.5s backoff and skip-to-next on final failure

When `checkNGetUrl()` returns `playable == false` with `statusMSG == "networkError"`, retry once after 1.5s with `generateNewUrl: true`. If retry succeeds, continue playback normally. If it fails, skip to the next queued song — unless `loopModeEnabled` (repeat-one) or queue has only one song.

**Files:**
- `lib/services/audio_handler.dart` (the `!streamInfo.playable` branch, lines 472–481)

**Changes:**
- Inside the `!streamInfo.playable` block (line 472), add a guard: if `streamInfo.statusMSG == "networkError"`, attempt retry before falling to error
- Retry: `await Future.delayed(const Duration(milliseconds: 1500))`, guard against stale call (`if (songIndex != currentIndex) return;`), then `await checkNGetUrl(currentSong.id, generateNewUrl: true)`. If retry succeeds, reassign `streamInfo` and fall through to the play path (deferred clear + add + play)
- If retry still fails OR error is non-network: show error snackbar (with cooldown from Task 3), then skip-to-next if `!loopModeEnabled && queue.value.length > 1`, else pause with error
- Remove `currentSongUrl = null;` in the final error path — `_playList` is intact from Task 1

**Acceptance Criteria:**
- Covers spec scenario "Auto-skip retry succeeds after transient network error" (Requirement 1): retry succeeds → play continues, no snackbar
- Covers spec scenario "Auto-skip retry fails — advance to next song" (Requirement 1): retry fails, multi-song queue → skip to next, one snackbar
- Covers spec scenario "Single song in queue — retry fails" (Requirement 1): single-song queue → pause with snackbar, no crash, no infinite loop
- Covers spec scenario "Repeat-one mode — retry fails" (Requirement 1): repeat-one active → stop with snackbar, no infinite loop
- Non-network errors (e.g., video unavailable) skip retry immediately — go straight to error path

**Depends on:** Task 1 (reordered `_playList.clear()`), Task 3 (snackbar cooldown)

**Estimated size:** S (~12 lines)

---

## Implementation Status

All 4 tasks implemented in a single pass. See [apply-progress] in Engram for details.
