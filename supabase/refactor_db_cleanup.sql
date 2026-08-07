-- ============================================================
-- Database refactor / cleanup migration — companion to the client-side
-- consistency pass (unified project views, star ratings, real league rank).
--
-- What it does:
--   1. Drops two dead columns the app never reads or writes:
--        - projects.league_id      (reserved pre-league, superseded by
--                                   league_submissions.project_id)
--        - league_submissions.session_id  (legacy single-session entries;
--                                   every row since the weekly-phases
--                                   migration is project-based)
--   2. Tightens league_submissions.project_id to NOT NULL — the app always
--      writes it, and the weekly-phases migration truncated any older rows
--      that predated it.
--   3. Makes usernames unique case-insensitively ("Bob" can no longer
--      coexist with "bob").
--   4. Adds the missing indexes behind the app's hot queries and FK
--      cascades — Postgres does not index FK columns automatically.
--   5. Adds a latest_league_champion view so "Last Season's Champion" is
--      one round trip instead of two (past-league lookup + champion
--      lookup), keeping that logic in the database instead of the client.
--
-- Safe to run against the existing database: no user data is dropped
-- (the two dropped columns are entirely unused). Run once in the
-- Supabase SQL Editor, after all migrations up to
-- add_league_weekly_phases_and_ratings.sql.
-- ============================================================

begin;

-- ---------- 1. dead columns ----------
alter table public.projects
  drop column if exists league_id;

-- league_submission_details doesn't select session_id, so the view is
-- unaffected by this drop.
alter table public.league_submissions
  drop column if exists session_id;

-- ---------- 2. project_id is now mandatory ----------
alter table public.league_submissions
  alter column project_id set not null;

-- ---------- 3. case-insensitive username uniqueness ----------
-- The plain unique constraint on username stays (PostgREST upserts key on
-- it); this index additionally blocks case-variant duplicates.
create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(username));

-- ---------- 4. missing indexes ----------
-- sessions: fetched per project (project detail, galleries) and per user
-- (stats, analytics), both ordered newest-first.
create index if not exists sessions_project_id_created_at_idx
  on public.sessions (project_id, created_at desc);
create index if not exists sessions_user_id_created_at_idx
  on public.sessions (user_id, created_at desc);

-- projects: fetched per user (Projects tab, profile circles).
create index if not exists projects_user_id_idx
  on public.projects (user_id);

-- follows: the PK (follower_id, followee_id) only serves follower-side
-- lookups; follower counts and mutuals filter by followee_id.
create index if not exists follows_followee_id_idx
  on public.follows (followee_id);

-- league_submissions: project_id is the second column of its unique
-- constraint, so project cascades/joins need their own index.
create index if not exists league_submissions_project_id_idx
  on public.league_submissions (project_id);

-- league_ratings: the stars aggregate in league_submission_details groups
-- by submission_id, which the PK (league_id, rater_id, submission_id)
-- doesn't cover.
create index if not exists league_ratings_submission_id_idx
  on public.league_ratings (submission_id);

-- profiles.pinned_post_id: its ON DELETE SET NULL means every session
-- delete scans profiles for a matching pin without this.
create index if not exists profiles_pinned_post_id_idx
  on public.profiles (pinned_post_id)
  where pinned_post_id is not null;

-- ---------- 5. latest_league_champion (view) ----------
-- The champion of the most recently *ended* league, if any — replaces the
-- client's two-step "find latest past league, then fetch its champion".
create or replace view public.latest_league_champion
  with (security_invoker = true) as
  select lc.*
  from public.league_champions lc
  join public.leagues l on l.id = lc.league_id
  where l.ends_at < now()
  order by l.ends_at desc
  limit 1;

commit;
