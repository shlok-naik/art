# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"Unfinished" — a Flutter app for tracking creative projects, sharing progress, and connecting with other artists. Ships to Android (physical device or emulator); no local backend — the app talks to Supabase directly.

## Commands

```bash
flutter pub get              # install dependencies
flutter run                  # run on connected device/emulator (hot reload: r, hot restart: R)
flutter test                 # full test suite
flutter test test/unit/reactions_test.dart   # single test file
flutter analyze              # static analysis / lint
```

Requires a `.env` file in the project root (gitignored) with `SUPABASE_URL` and `SUPABASE_ANON_KEY` — see [README.md](README.md) for the full setup walkthrough. There is no local/staging backend; `flutter run` talks directly to the Supabase project referenced in `.env`.

Tests: `test/unit/` holds offline unit tests (no device/backend needed) for app logic like profile models, reaction rules, and stage-completion recommendations. `test/main_shell_overflow_test.dart` is a widget test.

## Architecture

**Feature-first layout.** Each feature under `lib/features/<name>/` follows a `data` / `domain` / `presentation` split (not every feature has all three — e.g. `analytics` and `home` are presentation-only, reading through other features' providers):

- `domain/` — plain Dart model classes with a `fromRow(Map)` factory that parses a Supabase/PostgREST row.
- `data/` — a `*Repository` class wrapping a `SupabaseClient`, one method per query/RPC call. Repositories talk to Supabase directly (`.from(table).select()...` or `.rpc(name, params: {...})`) — there is no separate API/service layer.
- `presentation/` — screens and widgets, consuming state via Riverpod.
- `providers.dart` (feature root) — wires the repository into a `Provider`, then exposes `FutureProvider`/`FutureProvider.autoDispose.family` etc. for the data screens watch. This is the seam between data and presentation; screens never construct repositories directly.

State management is Riverpod throughout (`flutter_riverpod`), via `ConsumerWidget`/`ConsumerStatefulWidget` and `ref.watch`/`ref.listen` — no other state solution is used.

**App shell / auth flow** (`lib/app.dart`): `App` builds `MaterialApp` and gates on `AuthGate`, which watches `authStateChangesProvider` and shows `LoginScreen` when signed out. Once signed in, `_ProfileGate` watches `currentProfileProvider` and routes between `OnboardingScreen` → `ProfileSetupScreen` → `MainShell` depending on profile completeness. `lib/main.dart` does startup wiring (dotenv, Supabase.initialize, RevenueCat, ads, dark-mode preference) before `runApp`.

**Server-side business logic**: non-trivial rules (e.g. league period boundaries, "get or create this week's league") live in Postgres functions (`supabase/reset_schema.sql` plus incremental `supabase/add_*.sql` files) and are called via `.rpc(...)` rather than reimplemented client-side — repositories are thin wrappers around these RPCs and direct table reads, not where business logic lives.

**Theming**: `lib/shared/app_theme.dart` builds light/dark `ThemeData`; `lib/shared/app_styles.dart` exposes module-level color tokens (e.g. `kInkColor`, `kSurfaceColor`) that resolve against a global `appBrightness` variable set in `App.build` — this lets widgets read theme-aware colors as plain field accesses without threading `BuildContext`. Dark-mode preference persists via `theme_store.dart` and is exposed to the widget tree via `theme_providers.dart`; toggling it remounts the whole tree (see the `ValueKey(brightness)` in `app.dart`) so stale colors don't linger.

**Monetization/native integrations** live in `lib/shared/` as singleton services (`RevenueCatService`, `AdsService`, `JokeNotificationService`) initialized once in `main.dart`/`app.dart` rather than through Riverpod providers.
