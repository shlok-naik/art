-- ============================================================
-- Additive migration on top of add_league_tables.sql and
-- add_league_project_submissions.sql — switches the league cycle from a
-- fixed 14-day period to a weekly one with two phases inside it, and
-- replaces the single "one pick per league" vote with 1-5 star ratings
-- on every submission.
--
-- New weekly schedule, computed in Europe/London local time so British
-- Summer Time shifts the UTC instants automatically:
--   Monday 00:00           -> Friday 14:00   : submissions open ("it runs")
--   Friday 14:00           -> Sunday 00:00   : voting open (rate 1-5 stars)
--   Sunday 00:00           -> next Monday 00:00 : closed, waiting for the
--                                                  next week's league
--
-- Changes:
--   - leagues gains submissions_close_at / voting_closes_at (Friday 14:00
--     and Sunday 00:00 London time for that week).
--   - get_or_create_current_league() is rewritten around Monday-anchored
--     weeks instead of the old 14-day epoch.
--   - league_votes (one pick per user per league) is dropped and replaced
--     by league_ratings (one 1-5 star rating per user per submission —
--     a voter rates as many submissions as they browse).
--   - league_submissions insert/update/delete policies now gate on
--     submissions_close_at instead of ends_at.
--   - league_submission_details.votes becomes .stars (sum of ratings,
--     not a count), and league_champions is reordered by stars.
--
-- DESTROYS existing rows in leagues (cascades to league_submissions and
-- the old league_votes) — the old 14-day period_index values are not
-- compatible with the new weekly numbering, and this is pre-launch data.
-- Run once in the Supabase SQL Editor, after the two migrations above.
-- ============================================================

begin;

truncate table public.leagues cascade;

alter table public.leagues
  add column if not exists submissions_close_at timestamptz,
  add column if not exists voting_closes_at timestamptz;

alter table public.leagues
  alter column submissions_close_at set not null,
  alter column voting_closes_at set not null;

create or replace function public.get_or_create_current_league()
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  -- Any Monday works as the epoch — arithmetic below only ever compares
  -- whole weeks against it, which stays exact regardless of which Monday
  -- is picked.
  v_epoch_monday date := date '2024-01-01';
  v_week_start date;
  v_period_index bigint;
  v_starts_at timestamptz;
  v_ends_at timestamptz;
  v_submissions_close_at timestamptz;
  v_voting_closes_at timestamptz;
  v_theme_count int;
  v_theme public.league_themes;
  v_league public.leagues;
begin
  -- Anchor the week boundary to Europe/London wall-clock time so the
  -- Mon/Fri/Sun cutoffs land on the right local time year-round; casting
  -- back "at time zone" turns each local wall-clock instant into the
  -- correct UTC timestamptz, GMT/BST included.
  v_week_start := date_trunc('week', now() at time zone 'Europe/London')::date;

  v_starts_at := (v_week_start::timestamp) at time zone 'Europe/London';
  v_ends_at := ((v_week_start + 7)::timestamp) at time zone 'Europe/London';
  v_submissions_close_at := ((v_week_start + 4)::timestamp + time '14:00') at time zone 'Europe/London';
  v_voting_closes_at := ((v_week_start + 6)::timestamp) at time zone 'Europe/London';

  v_period_index := (v_week_start - v_epoch_monday) / 7;

  select * into v_league from public.leagues where period_index = v_period_index;
  if found then
    return v_league;
  end if;

  select count(*) into v_theme_count from public.league_themes;
  if v_theme_count = 0 then
    raise exception 'league_themes is empty — seed at least one theme';
  end if;

  select * into v_theme from public.league_themes
    order by cycle_index
    offset (mod(v_period_index, v_theme_count)) limit 1;

  insert into public.leagues (
    period_index, theme_title, theme_description,
    starts_at, ends_at, submissions_close_at, voting_closes_at
  )
  values (
    v_period_index, v_theme.title, v_theme.description,
    v_starts_at, v_ends_at, v_submissions_close_at, v_voting_closes_at
  )
  on conflict (period_index) do nothing
  returning * into v_league;

  if v_league.id is null then
    -- Lost a race with a concurrent caller that inserted first.
    select * into v_league from public.leagues where period_index = v_period_index;
  end if;

  return v_league;
end;
$$;

grant execute on function public.get_or_create_current_league() to authenticated;

-- ---------- league_submissions: gate phase on submissions_close_at ----------
drop policy if exists "users submit to a league while it is open" on public.league_submissions;
create policy "users submit to a league while it is open"
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
create policy "users update their own submission while the league is open"
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
create policy "users delete their own submission while the league is open"
  on public.league_submissions for delete
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.submissions_close_at
    )
  );

-- ---------- drop the old single-pick vote system ----------
-- Superseded by league_ratings below.
drop view if exists public.league_champions;
drop view if exists public.league_submission_details;
drop table if exists public.league_votes;

-- ---------- league_ratings ----------
-- One 1-5 star rating per (rater, submission) — a voter rates as many
-- submissions as they browse the voting feed, unlike the old one-pick-
-- per-league model. Self-rating is blocked by policy, and rating is only
-- allowed during that league's voting phase (submissions_close_at through
-- voting_closes_at).
create table public.league_ratings (
  league_id uuid not null references public.leagues (id) on delete cascade,
  rater_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  submission_id uuid not null references public.league_submissions (id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (league_id, rater_id, submission_id)
);

alter table public.league_ratings enable row level security;

create policy "league ratings are publicly readable"
  on public.league_ratings for select
  using (true);

create policy "users rate submissions during the voting phase, not their own"
  on public.league_ratings for insert
  with check (
    auth.uid() = rater_id
    and exists (
      select 1 from public.league_submissions s
      join public.leagues l on l.id = s.league_id
      where s.id = submission_id
        and s.league_id = league_id
        and s.user_id <> auth.uid()
        and now() >= l.submissions_close_at
        and now() < l.voting_closes_at
    )
  );

create policy "users change their own rating during the voting phase"
  on public.league_ratings for update
  using (auth.uid() = rater_id)
  with check (
    auth.uid() = rater_id
    and exists (
      select 1 from public.league_submissions s
      join public.leagues l on l.id = s.league_id
      where s.id = submission_id
        and s.league_id = league_id
        and s.user_id <> auth.uid()
        and now() >= l.submissions_close_at
        and now() < l.voting_closes_at
    )
  );

create policy "users retract their own rating during the voting phase"
  on public.league_ratings for delete
  using (
    auth.uid() = rater_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id
        and now() >= l.submissions_close_at
        and now() < l.voting_closes_at
    )
  );

-- ---------- league_submission_details (view) ----------
-- Recreated fresh (not CREATE OR REPLACE) since the vote count column is
-- renamed votes -> stars, which CREATE OR REPLACE VIEW disallows.
create view public.league_submission_details
  with (security_invoker = true) as
  select
    ls.id,
    ls.league_id,
    ls.user_id,
    p.username as artist_username,
    ls.photo_url,
    ls.caption,
    ls.created_at,
    coalesce(rc.stars, 0) as stars,
    ls.project_id,
    proj.title as project_title,
    proj.completion_percent as project_completion_percent,
    proj.finished_status as project_finished_status
  from public.league_submissions ls
  join public.profiles p on p.id = ls.user_id
  left join public.projects proj on proj.id = ls.project_id
  left join (
    select submission_id, sum(rating) as stars
    from public.league_ratings
    group by submission_id
  ) rc on rc.submission_id = ls.id;

-- ---------- league_champions (view) ----------
-- The top-starred submission per league (ties broken by earliest
-- submission) — used for "Last Season's Champion".
create view public.league_champions
  with (security_invoker = true) as
  select distinct on (league_id)
    league_id,
    id as submission_id,
    user_id,
    artist_username,
    photo_url,
    stars
  from public.league_submission_details
  order by league_id, stars desc, created_at asc;

commit;
