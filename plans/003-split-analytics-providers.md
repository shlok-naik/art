# Plan 003: Split lib/features/analytics/providers.dart into per-insight domain/data files

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dac5b6..HEAD -- lib/features/analytics/`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: tech-debt

## Why this matters

`lib/features/analytics/providers.dart` is 707 lines — about 5.8x the repo's median Dart file size (~121 lines) — and mixes 10+ unrelated domain model classes with 7 independent `FutureProvider.autoDispose` aggregation blocks (difficulty analytics, projects overview, time analytics, pro insights ×2, Art Wrapped). None of these providers depend on each other's *models* (only on the shared `allSessionsProvider` fetch), so the file has no real cohesion — it's one file because everything happened to be "analytics", not because the code needs to be together. Every change to one insight (e.g. tweaking the streak calculation) requires navigating past six unrelated ones, and git blame/history on this file will mix unrelated feature work. Splitting it makes each insight independently reviewable and testable, and follows the `data/domain/presentation` layering every other multi-file feature (`league`, `profile`, `projects`) already uses.

## Current state

`lib/features/analytics/providers.dart` (707 lines) currently has this shape, in order:

- **Lines 1-4**: imports — `flutter_riverpod`, `../projects/presentation/session_details_form.dart show kSessionStages`, `../projects/providers.dart` (this is where the underlying session data comes from — there is no `analytics/data/` layer today; `allSessionsProvider` below does its own aggregation over the projects feature's data).
- **Lines 6-114**: shared model classes used across multiple insights — `ProjectDifficulty`, `StageDifficulty`, `DifficultyAnalytics`, `_StageAccumulator`, `SessionRecord` — plus `allSessionsProvider` (line 90), the single batched fetch of every session across every project that every other provider in this file builds on. **This block must not be split apart from the providers below it without care** — `SessionRecord` and `allSessionsProvider` are shared infrastructure, not one insight's private model.
- **Lines 115-179**: `difficultyAnalyticsProvider` — free-tier difficulty analytics.
- **Lines 180-285**: `RadarComparison`, `MonthlyDifficulty`, `DifficultyProInsights` models + `difficultyProInsightsProvider` — Pro-only difficulty insights.
- **Lines 286-406**: `ProjectStats`, `StatusCount`, `FastestFinish`, `ProjectsOverview` models + `projectsOverviewProvider` — free-tier projects overview.
- **Lines 407-538**: `StageTime`, `LongestSession`, `TimeAnalytics` models + `timeAnalyticsProvider` — free-tier time analytics.
- **Lines 539-659**: `ToolUsage`, `ActivityDay`, `NeedsAttentionProject`, `ProjectsProInsights` models + `projectsProInsightsProvider` — Pro-only project insights.
- **Lines 660-707**: `ArtWrappedStats` model + `artWrappedProvider` — Pro-only recap, which composes data from the other providers (check its body for which other providers it `ref.watch`s — this is the one cross-insight dependency in the file, so it must import from the split-out files rather than duplicating their logic).

Exemplar for the target layering convention (feature with its own `data/`+`domain/`+providers.dart split): `lib/features/league/providers.dart` wires a repository into a `Provider`, then exposes `FutureProvider`s that consumers watch — screens never touch the repository directly. Match that shape: put models in `domain/`, the aggregation-provider bodies read like a "repository" over `allSessionsProvider`'s data even though there's no Supabase call in most of them.

## Commands you will need

| Purpose   | Command            | Expected on success |
|-----------|---------------------|----------------------|
| Analyze   | `flutter analyze`   | "No issues found!"   |
| Tests     | `flutter test`      | all pass             |

## Scope

**In scope**:
- `lib/features/analytics/providers.dart` (split into the files below; this file may end up deleted or reduced to re-exports — see Step 6)
- New files under `lib/features/analytics/domain/` and `lib/features/analytics/data/` (created by this plan)
- Import statements in any file under `lib/features/analytics/presentation/` that currently do `import '../providers.dart'` (update to the new locations, or keep working via a re-export — see Step 6)

**Out of scope** (do NOT touch, even though they look related):
- Any screen file's UI code or logic beyond fixing its import statement.
- `lib/features/projects/providers.dart` — `allSessionsProvider`'s upstream dependency; do not modify it.
- Renaming any provider or public class — this plan moves code, it does not rename the public API. Every provider name (`difficultyAnalyticsProvider`, `projectsOverviewProvider`, etc.) and every model class name must remain identical so no call site outside this plan's scope needs a rename.

## Git workflow

- Branch: `advisor/003-split-analytics-providers`
- Commit per step (one insight moved per commit is reasonable); message style matches `git log` (e.g. "Split difficulty analytics out of analytics/providers.dart")
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Create the shared infrastructure file

Create `lib/features/analytics/data/session_records.dart` containing: the imports from the top of the original file, `SessionRecord` (lines 52-79 of the original), `_StageAccumulator` (lines 47-51, if only used here — check for other usages first with `grep -rn "_StageAccumulator" lib/features/analytics/`; if it's private and used elsewhere in the original file, keep a copy local to whichever new file uses it, per Dart's file-private `_` semantics — do not try to export a `_`-prefixed name), and `allSessionsProvider` (lines 87-114).

**Verify**: `flutter analyze lib/features/analytics/data/session_records.dart` → "No issues found!" (expect unused-import warnings until later steps wire it in — re-check at the end instead if so).

### Step 2: Split out difficulty analytics

Create `lib/features/analytics/domain/difficulty_analytics.dart` with `ProjectDifficulty`, `StageDifficulty`, `DifficultyAnalytics`, `RadarComparison`, `MonthlyDifficulty`, `DifficultyProInsights` (lines 6-46 and 180-237 of the original — both the free and pro difficulty models, since `DifficultyProInsights` composes on `DifficultyAnalytics`-shaped data).

Create `lib/features/analytics/data/difficulty_analytics_provider.dart` with `difficultyAnalyticsProvider` (lines 115-179) and `difficultyProInsightsProvider` (lines 241-285), importing `SessionRecord`/`allSessionsProvider` from `session_records.dart` and the models from `domain/difficulty_analytics.dart`.

**Verify**: `flutter analyze lib/features/analytics/domain/difficulty_analytics.dart lib/features/analytics/data/difficulty_analytics_provider.dart` → "No issues found!"

### Step 3: Split out projects overview and time analytics

Same pattern:
- `lib/features/analytics/domain/projects_overview.dart` — `ProjectStats`, `StatusCount`, `FastestFinish`, `ProjectsOverview` (lines 286-340).
- `lib/features/analytics/data/projects_overview_provider.dart` — `projectsOverviewProvider` (lines 344-406).
- `lib/features/analytics/domain/time_analytics.dart` — `StageTime`, `LongestSession`, `TimeAnalytics` (lines 407-487).
- `lib/features/analytics/data/time_analytics_provider.dart` — `timeAnalyticsProvider` (lines 492-538).

**Verify**: `flutter analyze lib/features/analytics/domain/ lib/features/analytics/data/` → "No issues found!"

### Step 4: Split out Pro project insights and Art Wrapped

- `lib/features/analytics/domain/projects_pro_insights.dart` — `ToolUsage`, `ActivityDay`, `NeedsAttentionProject`, `ProjectsProInsights` (lines 539-589).
- `lib/features/analytics/data/projects_pro_insights_provider.dart` — `projectsProInsightsProvider` (lines 593-659).
- `lib/features/analytics/domain/art_wrapped_stats.dart` — `ArtWrappedStats` (lines 660-681).
- `lib/features/analytics/data/art_wrapped_provider.dart` — `artWrappedProvider` (lines 684-707). Check this provider's body for `ref.watch(...)` calls on the other providers split out above and import from their new `data/` locations accordingly.

**Verify**: `flutter analyze lib/features/analytics/` → "No issues found!"

### Step 5: Update every consumer's import

Run `grep -rln "features/analytics/providers.dart\|'../providers.dart'" lib/features/analytics/presentation/` to find every screen importing the old file, and update each to import the specific new `data/*_provider.dart` file(s) it actually uses (a screen using `difficultyAnalyticsProvider` imports `data/difficulty_analytics_provider.dart`, not all five new files).

**Verify**: `flutter analyze` (whole project) → "No issues found!"

### Step 6: Remove the original file

Delete `lib/features/analytics/providers.dart` once no file imports it (`grep -rln "features/analytics/providers.dart" lib/` returns nothing outside itself).

**Verify**: `grep -rln "features/analytics/providers.dart" lib/` → no matches. `flutter analyze` → "No issues found!". `flutter test` → all pass.

## Test plan

- No new tests are required by this plan — it's a pure move/split with identical provider names and model shapes, verified by `flutter analyze` (import correctness) and the existing test suite (behavioral regression, if any of the 4 existing test files touch analytics — check `grep -rln "analytics" test/` first).
- If any existing test does exercise an analytics provider, re-run it after each step to catch a broken import early rather than only at the end.

## Done criteria

- [ ] `flutter analyze` exits 0, "No issues found!"
- [ ] `flutter test` exits 0
- [ ] `lib/features/analytics/providers.dart` no longer exists
- [ ] Every provider/model name is unchanged (`grep -c "final .*Provider" lib/features/analytics/data/*.dart` sums to 7)
- [ ] No files outside `lib/features/analytics/` are modified except the presentation-file import updates from Step 5
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:
- The code at the line ranges in "Current state" doesn't match the excerpts (the file has drifted since this plan was written — re-derive the split boundaries from the live file's actual class/provider order instead of assuming these line numbers still hold, but confirm with the operator if the overall shape has changed significantly).
- `artWrappedProvider`'s body depends on internals of another provider in a way that isn't a simple `ref.watch(otherProvider.future)` — if it reaches into private accumulator state or similar, stop rather than guessing how to wire the cross-file dependency.
- A step's verification fails twice after a reasonable fix attempt.
- Any provider needs to change its public name or type to make the split work — that would break consumers outside this plan's scope.

## Maintenance notes

- After this split, a new analytics insight should get its own `domain/<name>.dart` + `data/<name>_provider.dart` pair, following the pattern this plan establishes — not be added back into a single shared file.
- A reviewer should scrutinize `art_wrapped_provider.dart` specifically — it's the one file with a real cross-insight dependency, and is the most likely place for a subtle behavior change to hide during the split.
- Deferred: this plan does not touch the *screens* that consume these providers (`lib/features/analytics/presentation/*_screen.dart`) beyond fixing imports — several of those are also large (see plan 005, `stage_radar_screen.dart`) but that's separate work.
