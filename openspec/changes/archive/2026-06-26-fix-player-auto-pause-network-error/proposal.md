**Status:** archived (2026-06-26)

# Proposal: Fix Player Auto-Pause on Network Error

## Intent

When auto-skip triggers during a transient network error, `playByIndex()` in `audio_handler.dart:464-466` clears the playlist **before** resolving the stream URL. If the URL resolution fails (`playable == false`), the playlist is empty, `currentSongUrl` is null, and playback freezes permanently — no auto-advance, no recovery. The user must manually pause/play to "unstick" it.

## Scope

### In Scope
- Reorder `_playList.clear()` in `playByIndex` to execute **after** the `playable` check
- Add 1 retry (1.5s backoff) when `playable == false` before falling to error
- Fix `onError` in `playbackEventStream` to `await` the `customAction('playByIndex')` call

### Out of Scope
- Redesign of the retry/backoff system (single retry is sufficient)
- Changes to `StreamProvider.fetch()`, `youtube_explode_dart`, or audio backend
- Changes to `notifyPlayError` UX, snackbar text, or localization

## Capabilities

### New Capabilities
None. No new spec-level capability is introduced.

### Modified Capabilities
None. No existing OpenSpec spec is affected — change is internal to `audio_handler.dart`.

## Approach

**A+B combined** (defensive ordering + retry with backoff):

1. **Defensive clear** (`audio_handler.dart:464-466`): Move `_playList.clear()` after the `streamInfo.playable` check at line 481. If not playable, leave playlist intact — no data loss, no frozen state.

2. **Retry on failure** (`audio_handler.dart:472`): When `!streamInfo.playable`, wait 1.5s and call `checkNGetUrl()` once more. Success → continue normally. Failure → set error state with playlist and queue intact (from fix 1). Player is recoverable via play/skip without manual intervention.

3. **Await in onError** (`audio_handler.dart:191`): Add `await` before `customAction('playByIndex', ...)` to eliminate race condition with the subsequent `_player.seek()`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/services/audio_handler.dart:464-466` | Modified | Defer `_playList.clear()` after playability check |
| `lib/services/audio_handler.dart:472-481` | Modified | Add retry block after first `!streamInfo.playable` |
| `lib/services/audio_handler.dart:191` | Modified | Add `await` to `customAction` call in `onError` |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Double playback if clear deferred during fast skips | Low | Guard `_playList.add()` with `children.isNotEmpty` — already present |
| Retry adds 1.5s latency when network is genuinely down | Low | User sees error snackbar; 1.5s is imperceptible in error context |
| Race between concurrent `playByIndex` calls | Low | Early return on `songIndex != currentIndex` (line 470) already guards |

## Rollback Plan

Revert changes in `audio_handler.dart`: restore `_playList.clear()` to pre-fetch position, remove retry block, remove `await` in `onError`. Single file, no migration needed.

## Dependencies

None.

## Success Criteria

- [ ] Player auto-advances after transient network error (no freeze)
- [ ] Player does not show empty playlist state after network error during auto-skip
- [ ] No regression: manual skip, play, pause continue to work correctly
- [ ] Error snackbar displays but recovery is automatic within 1.5s
