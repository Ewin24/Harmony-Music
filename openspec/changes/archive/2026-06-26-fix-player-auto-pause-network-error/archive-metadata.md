# Archive Metadata

- **date_archived:** 2026-06-26
- **status:** completed
- **summary:** Fix player freeze on transient network error during auto-skip. Defers `_playList.clear()` until after playability is confirmed, adds a single retry with 1.5s backoff for network errors, and fixes a missing `await` in the error handler race condition.
- **final_lines_changed:** 36 (net)
- **spec_scenarios_passed:** 7/7
- **tasks_completed:** 4/4
