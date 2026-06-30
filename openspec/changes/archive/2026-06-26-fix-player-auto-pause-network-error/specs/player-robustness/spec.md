# Spec: Player Robustness on Network Errors

## Purpose

`playByIndex` in `audio_handler.dart` clears the internal `_playList` before confirming the next song's URL is playable. When a network error causes `StreamProvider.fetch` to return `playable: false`, the playlist is already empty and the player enters a frozen state — no auto-skip, no recovery, user must manually pause/play to unstick. This spec defines the correct failure-recovery contract.

## Requirements

### Requirement: Auto-skip MUST recover from transient network errors

The player SHALL retry stream URL resolution once when the first attempt fails due to a network error during auto-skip. If the retry succeeds, playback SHALL continue seamlessly without user-visible error. If the retry fails, the player SHALL advance to the next queued song and SHALL NOT remain frozen.

#### Scenario: Auto-skip retry succeeds after transient network error

- GIVEN a non-empty playback queue with at least two songs
- WHEN auto-skip triggers AND `checkNGetUrl()` fails with `playable == false` due to `SocketException`
- THEN the player waits 1.5s and calls `checkNGetUrl()` a second time
- AND if the retry returns `playable == true`, playback continues to the next song
- AND no error snackbar is shown

#### Scenario: Auto-skip retry fails — advance to next song

- GIVEN a non-empty playback queue with at least two songs
- WHEN auto-skip triggers AND `checkNGetUrl()` fails AND the retry also fails
- THEN the player skips the failed song and advances to the following song in queue
- AND the failed song is marked as unavailable
- AND the error snackbar "Network error! Check your network connection." is displayed exactly once
- AND the player is NOT in a frozen/empty-playlist state

#### Scenario: Single song in queue — retry fails

- GIVEN the playback queue contains exactly one song
- WHEN the song finishes AND `checkNGetUrl()` fails for the next (same) song AND the retry also fails
- THEN the player transitions to `AudioProcessingState.error` with the error snackbar
- AND the player SHALL NOT crash or enter an unrecoverable state

#### Scenario: Repeat-one mode — retry fails

- GIVEN repeat-one mode is active
- WHEN the current song finishes AND `checkNGetUrl()` fails on re-resolve AND the retry also fails
- THEN the player stops and displays the error snackbar
- AND the player SHALL NOT enter an infinite retry loop

### Requirement: Playback queue integrity on URL resolve failure

The player SHALL preserve the `_playList` contents until stream URL resolution confirms `playable == true`. The playlist SHALL NOT be cleared before that confirmation.

#### Scenario: Clear deferred until playable confirmed

- GIVEN `playByIndex` is invoked (auto-skip or manual play)
- WHEN `checkNGetUrl()` returns `playable == true`
- THEN `_playList.clear()` executes AND the new `AudioSource` is added
- AND the current playback queue is replaced with the resolved song

#### Scenario: Playlist preserved when URL not playable

- GIVEN `playByIndex` is invoked AND the current `_playList` is non-empty
- WHEN `checkNGetUrl()` returns `playable == false`
- THEN `_playList.clear()` SHALL NOT execute
- AND the existing playlist remains intact for recovery via manual play/skip

### Requirement: Async error handler MUST await navigation action

The `playbackEventStream` error handler SHALL `await` the `customAction('playByIndex')` call before executing the subsequent `_player.seek()`.

#### Scenario: Seek waits for playByIndex completion

- GIVEN `playbackEventStream` emits an error event (e.g., 403)
- WHEN the handler invokes `customAction('playByIndex', ...)`
- THEN the call is awaited (`await`) before `_player.seek()` executes
- AND no race condition occurs between `playByIndex` setup and the seek position
