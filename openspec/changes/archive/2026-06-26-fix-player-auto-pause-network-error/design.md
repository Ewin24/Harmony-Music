# Design: Fix Player Auto-Pause on Network Error

## Context

When auto-skip triggers, `playByIndex()` (`audio_handler.dart:464-466`) calls `_playList.clear()` **before** awaiting `checkNGetUrl()`. If that URL resolution returns `playable: false` (e.g., `SocketException` from `youtube_explode_dart`), the playlist is already empty, `currentSongUrl` is null, and the player is frozen — no audio, no auto-advance, no recovery. Manual pause/play unblocks it because `PlayerController.play()` re-invokes `playByIndex()` when `currentSongUrl == null` (`player_controller.dart:325-332`). This behavior is incorrect: a transient network error must not permanently stall playback.

Additionally, `onError` in `playbackEventStream` (`audio_handler.dart:191`) calls `customAction("playByIndex", ...)` without `await`, creating a race condition with the subsequent `_player.seek()`.

## Goals / Non-Goals

**Goals:**
- Player never freezes on transient network error during auto-skip
- `_playList` integrity preserved when URL resolution fails
- Async error handler has no race condition
- User feedback is clear on terminal errors (after retry)
- Snackbar cooldown prevents UI spam on rapid skips

**Non-Goals:**
- No global retry system redesign
- No change to `youtube_explode_dart` or audio backend
- No change to `notifyPlayError` public contract or `playByIndex` signature
- No telemetry, analytics, or circuit breaker

## Architecture Decisions

### D1: Defer `_playList.clear()` after playability check

| Option | Trade-off | Decision |
|--------|-----------|----------|
| Keep clear before validation (current) | Simple but broken on network error | ❌ Rejected |
| Defer clear after `playable == true` check | Slightly larger diff; playlist never lost on failure | ✅ **Adopted** |
| Clear early + restore from cache on error | Complex restore logic, race-prone | ❌ Rejected |

**Rationale**: Move lines 464-466 (`if (_playList.children.isNotEmpty) { await _playList.clear(); }`) to execute **after** the `streamInfo.playable` check (between lines 481 and 482). If resolution fails, `_playList` still holds the previous song — the player can recover via skip or manual play.

### D2: Retry once (1.5s backoff) only on network errors

| Option | Trade-off | Decision |
|--------|-----------|----------|
| No retry | Fast failure but transient blip kills playback | ❌ Rejected |
| 1 retry, 1.5s backoff | Simple, covers ~90% of transient errors; 1.5s delay only on error path | ✅ **Adopted** |
| Exponential backoff (3+ retries) | Overkill for auto-skip; user can manually retry via play | ❌ Rejected |

**Rationale**: Retry **only** when `streamInfo.statusMSG == "networkError"` (maps to `SocketException` in `StreamProvider.fetch`). Permanent errors (`VideoUnavailableException`, `VideoRequiresPurchaseException`, etc.) are not retried. The retry calls `checkNGetUrl(songId, generateNewUrl: true)` to bypass any cached failure from the first attempt.

### D3: On final failure, skip to next queue item (with guards)

| Option | Trade-off | Decision |
|--------|-----------|----------|
| Pause with error (current) | Frozen player, UX expects auto-advance | ❌ Rejected |
| Skip to next in queue | Non-frozen, matches streaming UX | ✅ **Adopted** |
| Loop current with infinite retry | Wastes bandwidth, user can't escape | ❌ Rejected |

**Rationale**: After retry failure, call `skipToNext()` which delegates to `_getNextSongIndex()` → `playByIndex(nextIndex)`. **Guards**: (1) if `loopModeEnabled` (repeat-one), do NOT skip — stop with error snackbar; (2) if queue has only 1 song, do NOT skip — same behavior as end-of-queue.

### D4: `await` in `onError` handler

**Choice**: Add `await` before `customAction("playByIndex", ...)` at `audio_handler.dart:191`.

**Rationale**: `customAction` returns `Future<dynamic>`. Without `await`, `_player.seek()` on the next line races against `playByIndex` setup (which clears/rebuilds `_playList`). The `onError` handler is already `async` — this is a missing `await` bug, not a design choice.

### D5: Snackbar cooldown

**Choice**: Track `DateTime? _lastNetworkErrorShownAt` in `MyAudioHandler`; skip `notifyPlayError()` if called within 3s of last network error.

**Rationale**: When skipping through multiple failing songs, `notifyPlayError` fires for each failure in rapid succession, stacking snackbars. The cooldown throttles to at most one network-error snackbar per 3s window.

## Architecture / Flow

**Before (broken):**

```
playByIndex(index)
  ├─ _playList.clear()              ← playlist now empty
  ├─ await checkNGetUrl()
  ├─ if (!playable) → error, return ← playlist EMPTY, player FROZEN
  └─ _playList.add(source)          ← never reached if error
```

**After (fixed):**

```
playByIndex(index)
  ├─ await checkNGetUrl()
  ├─ if (playable):
  │    ├─ _playList.clear()         ← only now, confirmed playable
  │    └─ _playList.add(source)
  ├─ else if (!playable && networkError):
  │    ├─ Future.delayed(1.5s)
  │    ├─ await checkNGetUrl(retry)
  │    ├─ if (playable) → play normally
  │    └─ else → skip-to-next if guards pass
  └─ else (permanent error):
       └─ show error, skip-to-next if guards pass
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/services/audio_handler.dart` | Modify | Reorder `_playList.clear()`, add retry+skip logic, fix `await` in `onError`, add snackbar cooldown field |

### Specific changes in `audio_handler.dart`

**1. `playByIndex` case (lines 453-509): Reorder + retry + skip**

Current (broken, lines 464-481):
```dart
if (_playList.children.isNotEmpty) {
  await _playList.clear();
}
// ...
final streamInfo = await futureStreamInfo;
if (songIndex != currentIndex) {
  return;
} else if (!streamInfo.playable) {
  currentSongUrl = null;
  // ... error state ...
  return;
}
```

New structure:
```dart
final streamInfo = await futureStreamInfo;
if (songIndex != currentIndex) {
  return;
} else if (!streamInfo.playable) {
  // Retry if network error
  if (streamInfo.statusMSG == "networkError") {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (songIndex != currentIndex) return;
    final retryInfo = await checkNGetUrl(currentSong.id, generateNewUrl: true);
    if (retryInfo.playable) {
      // fall through to play logic below
      streamInfo = retryInfo; // pseudo — actually restructure
    }
  }
  if (!streamInfo.playable) {
    showErrorWithCooldown(streamInfo.statusMSG);
    if (!loopModeEnabled && queue.value.length > 1) {
      skipToNext(); // delegates to playByIndex(nextIndex)
    }
    return;
  }
}
// clear AFTER playable confirmed
if (_playList.children.isNotEmpty) {
  await _playList.clear();
}
currentSongUrl = currentSong.extras!['url'] = streamInfo.audio!.url;
// ... rest of playback setup ...
```

**2. `onError` handler (line 191): Add `await`**

```dart
// Before (line 191):
customAction("playByIndex", {'index': currentIndex, 'newUrl': true});

// After:
await customAction("playByIndex", {'index': currentIndex, 'newUrl': true});
```

**3. Field addition:**

Add `DateTime? _lastNetworkErrorShownAt;` to `MyAudioHandler` class (around line 62).

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Manual regression | Normal playlist playback, skip, pause, play | Verify no regression on happy path |
| Manual error | Force network error at auto-skip moment | Verify retry then skip |
| Manual edge | Single-song queue + error; repeat-one + error | Verify graceful pause (no crash, no loop) |
| Manual UI | Rapid successive errors | Verify snackbar cooldown (max 1 per 3s) |

`strict_tdd: false` — no automated test infrastructure available (Flutter SDK not in env).

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Race between retry and user play/pause | Low | `songIndex != currentIndex` guard (line 470) handles re-entrant calls |
| Double audio if `_playList.clear()` deferred and user skips fast | Low | Clear executes before `_playList.add()` — no window for double-add |
| 1.5s latency added on real errors | Low | Acceptable in error context; user sees snackbar |
| Recursive `playByIndex` via `skipToNext` → `customAction` | Low | Dart event loop handles async re-entry; guard at line 470 prevents stale execution |

## Migration / Rollback

**Migration**: None — single-file internal change, no schema or public API.

**Rollback**: `git revert` of the commit. Original frozen-state behavior returns (not worse than before).

## Open Questions

None — spec covers all scenarios (7 scenarios across 3 requirements).
