# Plan 002: Standardize action-error handling and stop leaking raw exception text to users

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dac5b6..HEAD -- lib/shared/app_styles.dart lib/features/projects/presentation/projects_screen.dart`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: tech-debt

## Why this matters

The app already has a good, consistent pattern for *query* errors — `.when(data:, loading:, error:)` on an `AsyncValue`, rendering `AppErrorState`/`AppErrorText` from `lib/shared/app_styles.dart:292` and `:331` (used across 28 files). But *action* errors (submitting a form, deleting something, finishing a project) have no equivalent: there are 38 raw `try { } catch (e) { }` blocks across 19 files, surfaced three different ways — inline `setState` text (e.g. `login_screen.dart`), `ScaffoldMessenger` snackbars (13 files), and `showDialog` (8 files) — with no single convention. Worse, several `ScaffoldMessenger` call sites interpolate the raw exception directly into user-facing text (e.g. `'Failed to finish project: $e'`), bypassing the friendly-message logic (`appErrorMessage()`) that query errors already get. This plan gives actions the same one-function friendliness query errors have, and removes the raw-exception leaks, without forcing every screen onto one visual widget (a snackbar and an inline error text serve different UX moments and both can stay).

**Correction to the original audit finding this plan is based on**: the audit report claimed "23 uses of `AsyncValue.guard`" — that pattern does not exist anywhere in this codebase (`grep -rn "AsyncValue.guard" lib` returns zero matches). Do not introduce `AsyncValue.guard` as part of this plan; it was a hallucinated detail. The real, verified pattern split is: `.when()` for queries (already consistent, out of scope here) vs. ad hoc `try/catch` for actions (in scope here).

## Current state

- `lib/shared/app_styles.dart:307-323` — the existing friendly-message function, already used by query error states:
  ```dart
  /// A human-readable message for a failed request. Network-level failures
  /// (offline, DNS, refused connection, timeout) get a friendly explanation
  /// instead of a raw exception string; anything else falls back to the raw
  /// error so real bugs stay diagnosable.
  String appErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || ...) {
      return 'No internet connection — check your network and try again.';
    }
    if (text.contains('TimeoutException') || text.contains('timed out')) {
      return 'The server took too long to respond — try again in a moment.';
    }
    return text;
  }
  ```
- `lib/features/projects/presentation/projects_screen.dart:87-89` and `:125-127` — two sites that show the *raw* exception to the user, bypassing `appErrorMessage`:
  ```dart
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to finish project: $e')),
  );
  ```
  (and the equivalent for delete, at line 125). Both are representative of the pattern repeated in the other 12 files using `ScaffoldMessenger` — grep for `SnackBar(content: Text('Failed` / `'.*\$e` in those files to find each site.
- The 19 files with raw `try/catch` around an action (verified via `grep -rln "} catch (e) {" lib --include=*.dart` — re-run this yourself before starting, in case it has drifted): `lib/features/auth/presentation/login_screen.dart`, `sign_up_screen.dart`, `lib/features/feed/presentation/comments_sheet.dart`, `feed_screen.dart`, `lib/features/feed/providers.dart`, `lib/features/followed/presentation/followed_screen.dart`, `lib/features/league/presentation/league_chat_screen.dart`, `league_screen.dart`, `league_voting_feed_screen.dart`, `submit_to_league_screen.dart`, `lib/features/posts/presentation/post_detail_screen.dart`, `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/presentation/edit_profile_screen.dart`, `profile_setup_screen.dart`, `public_profile_screen.dart`, `stats_visibility_screen.dart`, `lib/features/projects/presentation/projects_screen.dart`, `project_detail_screen.dart`, `session_capture.dart`. Note `lib/features/pro/presentation/pro_screen.dart` has **no** catch block — it was wrongly included in an earlier draft of this list; do not spend time looking for an action-error site there.

## Commands you will need

| Purpose   | Command            | Expected on success |
|-----------|---------------------|----------------------|
| Analyze   | `flutter analyze`   | "No issues found!"   |
| Tests     | `flutter test`      | all pass             |

## Scope

**In scope**:
- `lib/shared/app_styles.dart` — no new widget needed; `appErrorMessage()` already exists and is the tool for this plan. Do not add a new snackbar/toast widget class — see STOP conditions.
- Every `SnackBar(content: Text('...$e...'))` or `Text('...$e...')` site in the 19 files listed above where the raw caught exception (`e`, or `error`) is interpolated directly into user-facing text.
- `showDialog` sites in those files, same rule: if the dialog body interpolates the raw exception, route it through `appErrorMessage()`.

**Out of scope** (do NOT touch, even though they look related):
- Any `.when()`/`AsyncValue` query-error site — those already use `AppErrorState`/`AppErrorText` correctly and are not part of this finding.
- Any `catch` block whose message is already a static, friendly string not containing the raw exception (e.g. `login_screen.dart`'s generic `catch (e) { setState(() => _errorText = 'Something went wrong. Please try again.'); }`) — that one is already fine, leave it.
- Consolidating `ScaffoldMessenger` vs. `showDialog` vs. inline `setState` text into one single widget/pattern — that is a larger UX decision explicitly deferred (see Maintenance notes), not part of this plan. This plan only fixes *what text gets shown*, not *how* it's shown.

## Git workflow

- Branch: `advisor/002-standardize-action-error-handling`
- Commit per file or small logical group; message style matches `git log` (e.g. "Route action-error messages through appErrorMessage()")
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Enumerate every raw-exception-interpolation site

Run `grep -rn "\$e\b\|\${e}\|\$error\b\|\${error}" lib/features --include=*.dart | grep -iE "snackbar|text\(|content:|showdialog"` and manually confirm each hit is inside a `catch` block that's about to show that text to the user (not, e.g., a debug print or log call — those are out of scope, leave them). Build a list of `file:line` sites.

**Verify**: you have a concrete list of sites (expect roughly a dozen, concentrated in the `ScaffoldMessenger` files) before proceeding — do not guess at this list.

### Step 2: Fix `projects_screen.dart` first as the reference case

Change both sites (`:87-89` and `:125-127`) from:
```dart
SnackBar(content: Text('Failed to finish project: $e')),
```
to:
```dart
SnackBar(content: Text(appErrorMessage(e))),
```
Add the import for `app_styles.dart` if not already present in the file (check first — many screens already import it for `kInkColor`/theme tokens).

**Verify**: `flutter analyze lib/features/projects/presentation/projects_screen.dart` → "No issues found!"

### Step 3: Apply the same fix to every other site from Step 1's list

For each site: replace the raw `$e`/`$error` interpolation with `appErrorMessage(e)` (or `appErrorMessage(error)`, matching the caught variable's name), preserving the surrounding "Failed to X" prefix text where one exists (e.g. `'Failed to finish project: ${appErrorMessage(e)}'` if the plain message alone would lose useful context — use judgment per site, but never show the raw `e.toString()` unfiltered).

**Verify** after each file: `grep -n "\$e\b\|\${e}\|\$error\b\|\${error}" <file>` shows no remaining raw interpolations inside a user-facing `Text`/`SnackBar`/dialog body.

## Test plan

- This is a text-only change with no new branching logic, so no new unit tests are required — `appErrorMessage()` itself is already implicitly covered by existing behavior and doesn't change.
- If any touched file has an existing widget test that asserts on the exact old error string, update the expected string to match the new `appErrorMessage()` output rather than skipping the test. Check `test/main_shell_overflow_test.dart` and any per-feature test files for such assertions before finishing.

## Done criteria

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] `grep -rn "\$e\b\|\${e}\|\$error\b\|\${error}" lib/features --include=*.dart | grep -iE "snackbar|text\(|content:|showdialog"` returns no remaining raw-exception interpolations
- [ ] No files outside the in-scope list are modified (`git status`)
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:
- You find yourself wanting to introduce `AsyncValue.guard` — it does not exist in this codebase; do not add it as part of this plan (see the correction note above).
- You find yourself wanting to create a new shared snackbar/toast helper widget to unify `ScaffoldMessenger`/`showDialog`/inline-text call sites into one mechanism — that's a larger, separate decision (see Maintenance notes), out of scope here.
- Any site's caught exception is intentionally shown raw for a debugging/dev-only surface (check for a `kDebugMode` guard nearby) — leave those alone and note them instead of "fixing".
- A step's verification fails twice after a reasonable fix attempt.

## Maintenance notes

- Deferred by design: picking one winner among `ScaffoldMessenger` / `showDialog` / inline-text for *how* action errors are surfaced (not just what text they show) is a UX decision for the maintainer, not this plan. A follow-up plan could tackle it once this text-level fix has landed and the call sites are easier to audit.
- Any new action handler added after this lands should call `appErrorMessage(e)` rather than interpolating `e` directly — this is the convention this plan establishes.
- A reviewer should scrutinize: sites where the "Failed to X: " prefix plus `appErrorMessage()` output might read awkwardly together (e.g. "Failed to finish project: No internet connection — check your network and try again.") — consider dropping the prefix at those specific sites case by case rather than mechanically appending.
