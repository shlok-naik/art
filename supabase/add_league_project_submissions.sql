-- ============================================================
-- Additive migration on top of add_league_tables.sql — lets a league
-- submission point at an entire *project* (browsable session-by-session)
-- instead of a single session, and lets one user submit more than one
-- project to the same league.
--
-- Changes:
--   - league_submissions gains project_id (FK to projects). The old
--     session_id column is left in place for any existing rows but is no
--     longer written by the app.
--   - The old "one submission per user per league" constraint is replaced
--     by "one submission per project per league" — a user can now submit
--     several of their projects, but not the same project twice.
--   - Insert/update policies also require the submitter to own project_id.
--   - league_submission_details gains project_id/title/completion/finished
--     columns so the UI can open a project's full session history.
--
-- Safe to run against an existing database: does not drop existing rows.
-- Existing rows keep project_id = null until resubmitted. Run once in the
-- Supabase SQL Editor, after add_league_tables.sql.
-- ============================================================

alter table public.league_submissions
  add column if not exists project_id uuid references public.projects (id) on delete cascade;

-- Replace the one-per-user constraint with one-per-project (Postgres'
-- default name for the original inline `unique (league_id, user_id)`).
alter table public.league_submissions
  drop constraint if exists league_submissions_league_id_user_id_key;

alter table public.league_submissions
  drop constraint if exists league_submissions_league_id_project_id_key;

alter table public.league_submissions
  add constraint league_submissions_league_id_project_id_key unique (league_id, project_id);

drop policy if exists "users submit to a league while it is open" on public.league_submissions;
create policy "users submit to a league while it is open"
  on public.league_submissions for insert
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.projects p where p.id = project_id and p.user_id = auth.uid())
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.ends_at
    )
  );

drop policy if exists "users update their own submission while the league is open" on public.league_submissions;
create policy "users update their own submission while the league is open"
  on public.league_submissions for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.projects p where p.id = project_id and p.user_id = auth.uid())
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.ends_at
    )
  );

-- ---------- league_submission_details (view) ----------
-- Recreated with project columns appended at the end — CREATE OR REPLACE
-- VIEW requires existing column names/positions to stay put, so the
-- original columns are listed first, unchanged, then the new ones.
create or replace view public.league_submission_details
  with (security_invoker = true) as
  select
    ls.id,
    ls.league_id,
    ls.user_id,
    p.username as artist_username,
    ls.photo_url,
    ls.caption,
    ls.created_at,
    coalesce(vc.votes, 0) as votes,
    ls.project_id,
    proj.title as project_title,
    proj.completion_percent as project_completion_percent,
    proj.finished_status as project_finished_status
  from public.league_submissions ls
  join public.profiles p on p.id = ls.user_id
  left join public.projects proj on proj.id = ls.project_id
  left join (
    select submission_id, count(*) as votes
    from public.league_votes
    group by submission_id
  ) vc on vc.submission_id = ls.id;
