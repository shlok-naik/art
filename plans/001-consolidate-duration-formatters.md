# Plan 001: Consolidate duplicated duration/time formatting into lib/shared/formatters.dart

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dac5b6..HEAD -- lib/shared/formatters.dart lib/features/feed/domain/feed_post.dart lib/features/analytics/presentation/hourly_rose_chart.dart lib/features/analytics/presentation/projects_analytics_screen.dart lib/features/analytics/presentation/time_analytics_screen.dart lib/features/pro/presentation/art_wrapped_screen.dart lib/features/profile/presentation/stats_screen.dart lib/features/feed/presentation/comments_sheet.dart lib/features/league/presentation/league_chat_screen.dart`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: tech-debt

## Why this matters

`lib/shared/formatters.dart` already exists specifically to prevent per-screen duplication of display formatting (its own file header says so: "previously copy-pasted as private helpers in half a dozen screens... keep any new formatting rule here"). Despite that, duration/time formatting has drifted back into 8 files as private `_format*` helpers, and the copies have already diverged in behavior (some round to whole minutes, some to `Xh Ym`, thresholds differ). Consolidating them means a future formatting change (e.g. "always show seconds" or a locale change) happens in one place and every screen updates together, and it makes the existing duplication-prevention convention actually hold.

## Current state

Two independent duplication clusters exist:

**Cluster A — minutes-to-"Xh Ym" duration formatting.** Four files have this *exact* body (byte-for-byte identical):

- `lib/features/analytics/presentation/projects_analytics_screen.dart:11-19`
- `lib/features/analytics/presentation/time_analytics_screen.dart:10-18`
- `lib/features/pro/presentation/art_wrapped_screen.dart:10-18`

```dart
String _formatMinutes(double minutes) {
  if (minutes <= 0) return '0m';
  final totalMinutes = minutes.round();
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}
```

Two more files have near-identical variants that differ slightly (no `<= 0` guard, different rounding order):

- `lib/features/profile/presentation/stats_screen.dart:13` —
  ```dart
  String _formatMinutes(double minutes) {
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
  ```
- `lib/features/analytics/presentation/hourly_rose_chart.dart:114` —
  ```dart
  String _formatMinutes(double totalMinutes) {
    final minutes = totalMinutes.round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }
  ```
  Note this one renders `'$minutes min'` (with a space, word "min") instead of `'${mins}m'` — a real visible inconsistency, not just duplication.

- `lib/features/feed/domain/feed_post.dart:3-9` formats *seconds* (not minutes) the same shape:
  ```dart
  String _formatTimeTaken(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    return '${minutes}m';
  }
  ```
  Note this one zero-pads minutes when hours > 0 (`'2h 05m'`) — another visible inconsistency vs. the cluster above (`'2h 5m'`).

**Cluster B — "day month, HH:mm" timestamp formatting.** Exact duplicates:

- `lib/features/feed/presentation/comments_sheet.dart:16-21`
- `lib/features/league/presentation/league_chat_screen.dart:17-22`

```dart
String _formatCommentTime(DateTime time) {   // and _formatMessageTime — identical body
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthNames[local.month - 1]}, $hour:$minute';
}
```
Both files also each define their own private `_monthNames` list — `lib/shared/formatters.dart:7-10` already has one; check each file for a local `const _monthNames = [...]` before removing.

**Target file** — `lib/shared/formatters.dart` (39 lines total today):
```dart
/// "01:23:45" — elapsed-time format used by the session timer and session
/// lists.
String formatDurationHms(Duration duration) { ... }
```
Follow this file's existing doc-comment style (one-line description + example output in quotes) for every function you add.

## Commands you will need

| Purpose   | Command                       | Expected on success |
|-----------|--------------------------------|----------------------|
| Analyze   | `flutter analyze`              | "No issues found!"   |
| Tests     | `flutter test`                 | all pass             |
| Search    | `grep -rn "_formatMinutes\|_formatTimeTaken\|_formatCommentTime\|_formatMessageTime" lib/` | no matches after step 3 |

## Scope

**In scope** (the only files you should modify):
- `lib/shared/formatters.dart` (add functions)
- `lib/features/analytics/presentation/projects_analytics_screen.dart`
- `lib/features/analytics/presentation/time_analytics_screen.dart`
- `lib/features/pro/presentation/art_wrapped_screen.dart`
- `lib/features/profile/presentation/stats_screen.dart`
- `lib/features/analytics/presentation/hourly_rose_chart.dart`
- `lib/features/feed/domain/feed_post.dart`
- `lib/features/feed/presentation/comments_sheet.dart`
- `lib/features/league/presentation/league_chat_screen.dart`
- `test/unit/formatters_test.dart` (create)

**Out of scope** (do NOT touch, even though they look related):
- `lib/shared/sparkline.dart` and any chart axis-label formatting not listed above — different concern (numeric axis ticks, not duration/time display).
- Any change to the *visible output* of `stats_screen.dart` or `hourly_rose_chart.dart` beyond what's needed to route through the shared function — see Step 2's explicit decision on which behavior wins.

## Git workflow

- Branch: `advisor/001-consolidate-duration-formatters`
- Commit per step; message style matches `git log` (short imperative summary, e.g. "Consolidate duplicated duration formatters into shared formatters.dart")
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add the two new shared functions

In `lib/shared/formatters.dart`, add:

1. `String formatMinutesCompact(num minutes)` — the winning behavior is the 4-file identical version (the majority pattern): guards `minutes <= 0` → `'0m'`, otherwise rounds to whole minutes, `${hours}h` when no remainder, `${hours}h ${mins}m` when hours and minutes, `${mins}m` when under an hour. Use this exact body (adapted to take `num` so both `int` and `double` callers work):
   ```dart
   String formatMinutesCompact(num minutes) {
     if (minutes <= 0) return '0m';
     final totalMinutes = minutes.round();
     final hours = totalMinutes ~/ 60;
     final mins = totalMinutes % 60;
     if (hours == 0) return '${mins}m';
     if (mins == 0) return '${hours}h';
     return '${hours}h ${mins}m';
   }
   ```
2. `String formatDurationCompact(Duration duration)` — the "Xh YYm" (zero-padded minutes when hours present) shape used by `feed_post.dart`, for seconds-based durations:
   ```dart
   String formatDurationCompact(Duration duration) {
     final hours = duration.inHours;
     final minutes = duration.inMinutes.remainder(60);
     if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
     return '${minutes}m';
   }
   ```
3. `String formatShortTimestamp(DateTime time)` — Cluster B's body, moved verbatim (reuse the existing `_monthNames` constant already in this file — do not add a second one):
   ```dart
   String formatShortTimestamp(DateTime time) {
     final local = time.toLocal();
     final hour = local.hour.toString().padLeft(2, '0');
     final minute = local.minute.toString().padLeft(2, '0');
     return '${local.day} ${_monthNames[local.month - 1]}, $hour:$minute';
   }
   ```

Add a one-line doc comment above each, matching the existing style in the file (e.g. `/// "2h 5m" / "45m" — compact duration used by analytics summaries.`).

**Verify**: `flutter analyze lib/shared/formatters.dart` → "No issues found!"

### Step 2: Repoint the 4 identical `_formatMinutes` call sites

In `projects_analytics_screen.dart`, `time_analytics_screen.dart`, `art_wrapped_screen.dart`: delete the private `_formatMinutes` function, add `import '../../../shared/formatters.dart';` (adjust relative path per file's location) if not already imported, and replace all call sites `_formatMinutes(x)` → `formatMinutesCompact(x)`.

**Verify**: `grep -rn "_formatMinutes" lib/features/analytics/presentation/projects_analytics_screen.dart lib/features/analytics/presentation/time_analytics_screen.dart lib/features/pro/presentation/art_wrapped_screen.dart` → no matches.

### Step 3: Repoint `stats_screen.dart` and `hourly_rose_chart.dart`

These two have behavior that differs slightly from the winning `formatMinutesCompact` (see "Current state" — no `<=0` guard, and `hourly_rose_chart.dart` uses `'N min'` word form instead of `'Nm'`). Replace both private `_formatMinutes` with calls to `formatMinutesCompact` — this is an intentional, visible behavior change (unifying to one format), which is the point of this plan. Do not try to preserve their old output shape.

**Verify**: `grep -rn "_formatMinutes" lib/features/profile/presentation/stats_screen.dart lib/features/analytics/presentation/hourly_rose_chart.dart` → no matches.

### Step 4: Repoint `feed_post.dart`

Delete `_formatTimeTaken` from `lib/features/feed/domain/feed_post.dart`, import `../../../shared/formatters.dart`, replace `_formatTimeTaken(durationSeconds)` at line 68 with `formatDurationCompact(Duration(seconds: durationSeconds))`.

**Verify**: `grep -n "_formatTimeTaken" lib/features/feed/domain/feed_post.dart` → no matches.

### Step 5: Repoint Cluster B (comments_sheet.dart, league_chat_screen.dart)

In each file: delete the private `_formatCommentTime`/`_formatMessageTime` function, delete the file's own private `const _monthNames = [...]` if present (confirm it's unused elsewhere in the file first — `grep -n "_monthNames" <file>`), import `../../../shared/formatters.dart`, replace call sites with `formatShortTimestamp(...)`.

**Verify**: `grep -rn "_formatCommentTime\|_formatMessageTime" lib/` → no matches.

## Test plan

- Create `test/unit/formatters_test.dart`, modeled after the existing style in `test/unit/reactions_test.dart` (plain `test()`/`group()` blocks, no widget pump needed since these are pure functions).
- Cases for `formatMinutesCompact`: `0` → `'0m'`, negative → `'0m'`, `45` → `'45m'`, `60` → `'1h'`, `125` → `'2h 5m'`.
- Cases for `formatDurationCompact`: `Duration(seconds: 0)` → `'0m'`, `Duration(minutes: 5)` → `'5m'`, `Duration(hours: 2, minutes: 5)` → `'2h 05m'`.
- Cases for `formatShortTimestamp`: a fixed `DateTime` (e.g. `DateTime(2026, 8, 7, 9, 5)`) → `'7 August, 09:05'`.
- Verification: `flutter test test/unit/formatters_test.dart` → all pass.

## Done criteria

- [ ] `flutter analyze` exits 0, "No issues found!"
- [ ] `flutter test` exits 0, including new `formatters_test.dart` cases
- [ ] `grep -rn "_formatMinutes\|_formatTimeTaken\|_formatCommentTime\|_formatMessageTime" lib/` returns no matches
- [ ] No files outside the in-scope list are modified (`git status`)
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:
- Any of the excerpts in "Current state" don't match the live file content.
- `hourly_rose_chart.dart` or `stats_screen.dart` turn out to have call sites relying on their old output shape in a snapshot/golden test — check `test/` for any golden test referencing these screens before changing their output.
- A step's verification fails twice after a reasonable fix attempt.

## Maintenance notes

- Any *new* screen needing duration/time display should import from `formatters.dart`, not write a local `_format*` helper — this plan exists specifically because that convention wasn't being followed.
- A reviewer should scrutinize: the Step 2/3 distinction (4 files got a no-op refactor, 2 files got a small visible behavior change) — confirm the PR description calls out which screens' displayed text changes.
- Deferred: this plan does not add a `formatCount`-style test for the existing `formatCount`/`formatDateValue`/`formatMonthDayYear` functions already in the file — only the newly-added ones are required to have tests here.
