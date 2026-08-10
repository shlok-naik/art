-- ============================================================
-- Additive migration — aligns league_submissions/league_votes RLS with the
-- real three-phase weekly league already live in get_or_create_current_league()
-- (Mon start -> Fri 2pm submissions_close_at -> Sun voting_closes_at -> Mon
-- ends_at), which predates this repo's add_league_tables.sql and was never
-- reflected in it. Previously these policies gated everything on
-- `now() < ends_at`, which let submissions/votes through the whole week
-- instead of locking submissions at Friday 2pm and votes at Sunday.
--
-- Safe to run against an existing database: policy-only change, no data
-- touched. Run once in the Supabase SQL Editor, after add_league_tables.sql
-- and add_league_project_submissions.sql.
-- ============================================================

drop policy if exists "users submit to a league while it is open" on public.league_submissions;
create policy "users submit to a league while submissions are open"
  on public.league_submissions for insert
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.projects p where p.id = project_id and p.user_id = auth.uid())
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.submissions_close_at
    )
  );

drop policy if exists "users update their own submission while the league is open" on public.league_submissions;
create policy "users update their own submission while submissions are open"
  on public.league_submissions for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.projects p where p.id = project_id and p.user_id = auth.uid())
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.submissions_close_at
    )
  );

drop policy if exists "users delete their own submission while the league is open" on public.league_submissions;
create policy "users delete their own submission while submissions are open"
  on public.league_submissions for delete
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.submissions_close_at
    )
  );

drop policy if exists "users vote once per league, not for themselves" on public.league_votes;
create policy "users vote once per league, not for themselves"
  on public.league_votes for insert
  with check (
    auth.uid() = voter_id
    and exists (
      select 1 from public.league_submissions s
      join public.leagues l on l.id = s.league_id
      where s.id = submission_id
        and s.league_id = league_id
        and s.user_id <> auth.uid()
        and now() < l.voting_closes_at
    )
  );

drop policy if exists "users change their own vote while the league is open" on public.league_votes;
create policy "users change their own vote while voting is open"
  on public.league_votes for update
  using (auth.uid() = voter_id)
  with check (
    auth.uid() = voter_id
    and exists (
      select 1 from public.league_submissions s
      join public.leagues l on l.id = s.league_id
      where s.id = submission_id
        and s.league_id = league_id
        and s.user_id <> auth.uid()
        and now() < l.voting_closes_at
    )
  );

drop policy if exists "users retract their own vote while the league is open" on public.league_votes;
create policy "users retract their own vote while voting is open"
  on public.league_votes for delete
  using (
    auth.uid() = voter_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.voting_closes_at
    )
  );
