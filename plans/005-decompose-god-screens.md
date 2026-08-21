# Plan 005: Decompose the three largest screen files into per-widget files

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dac5b6..HEAD -- lib/features/profile/presentation/public_profile_screen.dart lib/features/league/presentation/league_screen.dart lib/features/analytics/presentation/stage_radar_screen.dart`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P3
- **Effort**: L
- **Risk**: MED
- **Depends on**: plans/003-split-analytics-providers.md (do this after the analytics providers split, since `stage_radar_screen.dart` consumes providers plan 003 relocates)
- **Category**: tech-debt

## Why this matters

Three screen files are 5-7x the repo's median file size (~121 lines): `public_profile_screen.dart` (869 lines), `league_screen.dart` (757 lines), `stage_radar_screen.dart` (633 lines). All three are already internally well-factored into multiple private widget classes (`_FollowButton`, `_ProjectsRow`, `_PostsSection`, etc. in the profile screen; `_CountdownTimer`, `_Leaderboard`, `_SubmissionCard`, etc. in the league screen; `_ActivityHeatmap`, `_ProInsights`, etc. in the radar screen) — the problem isn't tangled logic, it's that every one of those already-separate widgets lives in the same file. That means any change to, say, the follow button touches a file that also contains the posts section, the achievements row, and the mutual-followers line, inflating diff noise and merge-conflict surface for unrelated changes. This plan is a mechanical extraction: move each private widget class to its own file, no behavior change.

## Current state

**`lib/features/profile/presentation/public_profile_screen.dart`** (869 lines) — top-level class plus 8 private widgets, each already a self-contained class:
```
26:  class PublicProfileScreen extends ConsumerWidget      (keep in this file)
245: class _FollowButton extends ConsumerStatefulWidget
254: class _FollowButtonState extends ConsumerState<_FollowButton>
318: class _ProjectsRow extends ConsumerWidget
362: class _ProjectCircle extends StatelessWidget
422: class _AchievementsRow extends ConsumerWidget
480: class _MutualFollowersLine extends ConsumerWidget
512: class _PinnedPostCard extends StatelessWidget
587: class _PostsSection extends ConsumerStatefulWidget
606: class _PostsSectionState extends ConsumerState<_PostsSection>
805: class _ThemedMenuButton<T> extends StatelessWidget
```

**`lib/features/league/presentation/league_screen.dart`** (757 lines):
```
22:  class LeagueScreen extends ConsumerWidget                (keep in this file)
70:  class _RegionPickerPrompt extends ConsumerStatefulWidget
145: class _LeagueBody extends ConsumerStatefulWidget
285: class _ThemeBanner extends StatelessWidget
330: class _CountdownTimer extends StatefulWidget
409: class _CountdownUnit extends StatelessWidget
437: class _Leaderboard extends StatelessWidget
493: class _LeaderboardRow extends StatelessWidget
559: class _PastChampionCard extends ConsumerWidget
596: class _SubmissionCard extends ConsumerStatefulWidget
```
Note: `_RegionPickerPrompt` is a leftover name from before the city-picker migration (commit `84f6c4b`) — it likely still functions correctly (region/city rename may only have changed the data layer), but confirm what it actually prompts for before moving it; do not rename it as part of this plan (renaming is out of scope — see Scope), just move it as-is and note the stale name in your commit if you notice it.

**`lib/features/analytics/presentation/stage_radar_screen.dart`** (633 lines):
```
18:  class StageRadarScreen extends ConsumerWidget    (keep in this file)
110: class _DifficultyProInsights extends StatelessWidget
231: class _ProInsights extends StatelessWidget
394: class _ActivityHeatmap extends StatelessWidget
476: class _SessionLengthTrend extends StatelessWidget
516: class _ProjectTimeline extends StatelessWidget
608: class _NeedsAttentionRow extends StatelessWidget
```

Exemplar for the target shape (a screen file that imports its sub-widgets from sibling files rather than defining them inline): check `lib/features/achievements/presentation/` for how `all_achievements_screen.dart` and `achievement_chip.dart` are already split as separate files in this repo — follow that same file-per-widget convention name-wise (e.g. `_ProjectsRow` → `presentation/projects_row.dart` exporting a public `ProjectsRow` class, since a private `_`-prefixed class cannot be used outside its own file).

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Analyze | `flutter analyze` | "No issues found!" |
| Tests | `flutter test` | all pass |

## Scope

**In scope**:
- `lib/features/profile/presentation/public_profile_screen.dart` and new sibling files it spawns
- `lib/features/league/presentation/league_screen.dart` and new sibling files it spawns
- `lib/features/analytics/presentation/stage_radar_screen.dart` and new sibling files it spawns

**Out of scope** (do NOT touch, even though they look related):
- Renaming `_RegionPickerPrompt` or fixing its stale naming — a separate, smaller cleanup not part of this plan.
- Any change to widget behavior, layout, or the actual UI tree structure — this is a file-move only. If a widget genuinely needs restructuring (not just relocating), stop and report rather than improvising a redesign.
- The three files' respective provider/data layers (`lib/features/profile/providers.dart`, `lib/features/league/providers.dart`, `lib/features/analytics/data/*` from plan 003) — this plan only moves presentation-layer widget classes.

## Git workflow

- Branch: `advisor/005-decompose-god-screens`
- Commit one screen's decomposition at a time (3 commits total, or one per widget extracted if you prefer finer granularity); message style matches `git log` (e.g. "Extract PublicProfileScreen's sub-widgets into separate files")
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Decompose `public_profile_screen.dart`

For each private widget class listed above (`_FollowButton`+`_FollowButtonState`, `_ProjectsRow`, `_ProjectCircle`, `_AchievementsRow`, `_MutualFollowersLine`, `_PinnedPostCard`, `_PostsSection`+`_PostsSectionState`, `_ThemedMenuButton`): create a new file `lib/features/profile/presentation/<snake_case_name>.dart`, move the class (and its State class, if any) there, rename the class to drop the leading underscore (making it a public, exported class — e.g. `_FollowButton` → `FollowButton`), and update every internal reference (the class's own State class name, and any place `public_profile_screen.dart` instantiates it) to the new public name. Add `import '<snake_case_name>.dart';` to `public_profile_screen.dart` for each extracted widget. Keep `PublicProfileScreen` itself (the top-level `ConsumerWidget`) in the original file.

If two widgets reference each other (e.g. `_ProjectsRow` uses `_ProjectCircle`), the file containing the "row" widget should import the "circle" widget's new file.

**Verify**: `flutter analyze lib/features/profile/presentation/` → "No issues found!"

### Step 2: Decompose `league_screen.dart`

Same process for `_RegionPickerPrompt`+`_RegionPickerPromptState`, `_LeagueBody`+`_LeagueBodyState`, `_ThemeBanner`, `_CountdownTimer`+`_CountdownTimerState`, `_CountdownUnit`, `_Leaderboard`, `_LeaderboardRow`, `_PastChampionCard`, `_SubmissionCard`+`_SubmissionCardState`. Keep `LeagueScreen` in the original file.

**Verify**: `flutter analyze lib/features/league/presentation/` → "No issues found!"

### Step 3: Decompose `stage_radar_screen.dart`

Same process for `_DifficultyProInsights`, `_ProInsights`, `_ActivityHeatmap`, `_SessionLengthTrend`, `_ProjectTimeline`, `_NeedsAttentionRow`. Keep `StageRadarScreen` in the original file.

**Verify**: `flutter analyze lib/features/analytics/presentation/` → "No issues found!"

### Step 4: Full-project check

**Verify**: `flutter analyze` (whole project, no path argument) → "No issues found!". `flutter test` → all pass, in particular re-run `test/main_shell_overflow_test.dart` since it may render one of these three screens — check its contents first (`grep -n "PublicProfile\|LeagueScreen\|StageRadar" test/main_shell_overflow_test.dart`) to know if it's affected.

## Test plan

- No new tests required — this is a structural move with no behavior change.
- If `test/main_shell_overflow_test.dart` renders any of the three screens, it must still pass unmodified after the split — a failure here means a widget's public API changed unintentionally during extraction (e.g. a constructor parameter was dropped), which is a bug in the extraction, not an expected change.

## Done criteria

- [ ] `flutter analyze` exits 0, "No issues found!"
- [ ] `flutter test` exits 0
- [ ] `public_profile_screen.dart`, `league_screen.dart`, `stage_radar_screen.dart` each contain only their top-level screen `ConsumerWidget` class (plus imports)
- [ ] Every extracted class is renamed from `_Name` to `Name` (no leading underscore) and used consistently
- [ ] No behavior change — `git diff` on the moved code shows only the class-name-underscore removal and import churn, not logic changes
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:
- The class list at the line numbers in "Current state" doesn't match the live file (drift since this plan was written) — re-derive the class list from `grep -n "^class " <file>` instead of trusting the line numbers, but if the *set* of classes has materially changed, stop and confirm before proceeding.
- Two widgets have a circular reference (A's file needs to import B, and B's file needs to import A) — Dart doesn't support circular imports; stop and report which two classes, rather than merging them back together or guessing a resolution.
- A step's verification fails twice after a reasonable fix attempt.
- Renaming a class from `_Name` to `Name` collides with an existing public name already in scope in that feature's `presentation/` folder.

## Maintenance notes

- Any new large screen added later should apply this same per-widget-file pattern from the start, rather than growing back into one file — this plan is a one-time cleanup, not an enforced rule (no lint currently checks file size).
- A reviewer should scrutinize: that the diff for each extraction is purely mechanical (class body unchanged apart from the name) — a genuine logic change hiding inside an "extraction" commit is the main risk this plan's Risk: MED rating is about.
- Deferred: `_RegionPickerPrompt`'s stale name (see "Current state") — worth a follow-up rename once someone confirms what it currently prompts for.
