# Plan 004: Document the data/domain/presentation convention and close the undocumented layering gap

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0dac5b6..HEAD -- CLAUDE.md lib/features/followed/ lib/features/home/ lib/features/posts/ lib/features/analytics/`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plans/003-split-analytics-providers.md (analytics should have its own `data/` folder before this plan documents the convention it now follows)
- **Category**: docs

## Why this matters

Six of ten features (`achievements`, `auth`, `feed`, `league`, `profile`, `projects`) follow a `data/` (repository) + `domain/` (models) + `presentation/` (screens) split — screens never call Supabase directly, they go through a named `*Repository` exposed via a `Provider`. Four features (`followed`, `home`, `posts`, `analytics`) currently have no `data/` folder and instead import a repository provider from whichever feature owns the data they need (e.g. `followed_screen.dart:180` uses `followsRepositoryProvider` from `profile`, `post_detail_screen.dart` uses `sessionsRepositoryProvider` from `projects`). That's a reasonable choice today — these screens genuinely don't own their own backend data — but the convention that makes it safe (never call Supabase directly from `presentation/`) is nowhere written down. Without it, the next person adding a feature to one of these four folders has no signal that they should reach for an existing repository provider rather than writing `Supabase.instance.client.from(...)` straight into a screen, which is exactly the layering violation the other six features already avoid. This plan documents the rule so it stays true on purpose, not by accident.

## Current state

- `CLAUDE.md` (repo root, already exists as of this plan) has an "Architecture" section describing the `data`/`domain`/`presentation` split, but its current wording only says "not every feature has all three" without explaining *when* that's acceptable or what the alternative is. The relevant paragraph today:
  > `domain/` — plain Dart model classes with a `fromRow(Map)` factory that parses a Supabase/PostgREST row.
  > `data/` — a `*Repository` class wrapping a `SupabaseClient`, one method per query/RPC call. Repositories talk to Supabase directly (`.from(table).select()...` or `.rpc(name, params: {...})`) — there is no separate API/service layer.
  > `presentation/` — screens and widgets, consuming state via Riverpod.
- Confirmed today (verify these are still accurate — `find lib/features -maxdepth 1 -type d` then check each for a `data/` subfolder):
  - `lib/features/followed/presentation/followed_screen.dart:180` — `ref.read(followsRepositoryProvider)`, imported from the `profile` feature.
  - `lib/features/posts/presentation/post_detail_screen.dart:51,109,149` — `ref.read(sessionsRepositoryProvider)`, imported from the `projects` feature.
  - `lib/features/home/` and `lib/features/analytics/` — after plan 003 lands, `analytics` will have its own `data/` folder (aggregation providers over `allSessionsProvider`); `home/presentation/home_screen.dart` currently has no direct repository or Supabase usage found — confirm with `grep -n "Repository\|Supabase" lib/features/home/presentation/home_screen.dart` before writing about it (it may just compose other screens/widgets and own no data access at all).
- No repo-wide lint rule currently forbids `import 'package:supabase_flutter/supabase_flutter.dart'` inside a `presentation/` folder — this plan adds a comment-level convention only (see Scope); an enforced lint is explicitly out of scope (see below).

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Analyze | `flutter analyze` | "No issues found!" (docs-only change, should be a no-op) |
| Confirm no direct Supabase use in presentation | `grep -rln "package:supabase_flutter" lib/features/*/presentation/` | Should return **no matches** — if it does, that's a pre-existing violation to report, not silently fix (see STOP conditions) |

## Scope

**In scope**:
- `CLAUDE.md` — expand the "Architecture" section's feature-layout paragraph.

**Out of scope** (do NOT touch, even though they look related):
- Writing an actual Dart/CI lint rule (e.g. a custom `analysis_options.yaml` rule or import-linter) to enforce the convention mechanically — this plan is documentation only. If you believe a mechanical check is worth adding, note it in the plan's Maintenance notes for a future plan instead of adding it here.
- Any code change to `followed/`, `home/`, `posts/`, or `analytics/` — if the `grep` verification above finds an existing violation (a direct Supabase call in a `presentation/` file), do not fix it as part of this plan; report it and stop (see STOP conditions).

## Git workflow

- Branch: `advisor/004-document-data-layer-convention`
- Single commit; message style matches `git log` (e.g. "Document data-layer convention for features without a local data/ folder")
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Confirm the current facts

Run `find lib/features -maxdepth 1 -type d` and, for each feature, check for a `data/` subfolder. Run `grep -rln "package:supabase_flutter" lib/features/*/presentation/` and confirm it returns no matches (if it does, stop — see STOP conditions). Run `grep -n "Repository\|Supabase" lib/features/home/presentation/home_screen.dart` to confirm whether `home` reads any repository at all.

**Verify**: you have an accurate, current list of which features have `data/` and which don't, and whether `home` uses any repository — do not rely solely on the "Current state" section above without re-checking, since plan 003 may have already changed `analytics`.

### Step 2: Expand the CLAUDE.md architecture section

In `CLAUDE.md`, immediately after the existing bullet list describing `domain/`/`data/`/`presentation/`, add a new paragraph (adjust the feature list based on Step 1's findings):

```markdown
Not every feature needs its own `data/` folder: `followed`, `home`, and `posts`
have no backend access of their own and instead read a named repository
provider from the feature that owns that data (e.g. `followed_screen.dart`
reads `followsRepositoryProvider` from `profile`; `post_detail_screen.dart`
reads `sessionsRepositoryProvider` from `projects`). **The rule this depends
on**: a `presentation/` file may call `ref.read`/`ref.watch` on another
feature's repository provider, but must never call Supabase directly
(`Supabase.instance`, `.from(...)`, `.rpc(...)`) — if a feature's screens need
a new kind of backend access that no existing repository provides, add a
`data/` folder to that feature rather than reaching for Supabase inline.
```

**Verify**: `flutter analyze` → "No issues found!" (docs-only, should not affect analysis).

## Test plan

No tests apply — this is a documentation-only change.

## Done criteria

- [ ] `CLAUDE.md`'s Architecture section documents the no-`data/`-folder convention and the "never call Supabase from presentation/" rule
- [ ] `grep -rln "package:supabase_flutter" lib/features/*/presentation/` confirmed empty before finishing (if not empty, this plan stops instead — see STOP conditions)
- [ ] No files outside `CLAUDE.md` are modified
- [ ] `plans/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:
- `grep -rln "package:supabase_flutter" lib/features/*/presentation/` finds an existing direct-Supabase-call in a presentation file — this is a real, separate finding (a layering violation already exists, contradicting the "no violation currently exists" assumption this plan was written under). Report the exact file:line and do not attempt to fix it as part of this documentation-only plan.
- Plan 003 has not landed yet and you're unsure whether `analytics` should be listed as having a `data/` folder — check `plans/README.md`'s status table for plan 003 before writing the CLAUDE.md paragraph; if plan 003 is not DONE, list `analytics` alongside `followed`/`home`/`posts` as still not having one, and note in your commit that this paragraph will need a follow-up edit once plan 003 lands.

## Maintenance notes

- Consider a future plan to add a mechanical check (a Dart custom lint rule, or a simple CI grep step) that fails the build if `package:supabase_flutter` is imported inside any `*/presentation/` file — this plan only documents the rule, it doesn't enforce it.
- If a fifth feature is later added without its own `data/` folder, this CLAUDE.md paragraph should be updated to include it, so the documented list stays accurate.
