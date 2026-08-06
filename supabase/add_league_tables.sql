-- ============================================================
-- Additive migration — creates the league feature's tables:
-- league_themes (curated, admin-managed catalog), leagues (one
-- materialized row per 2-week period), league_submissions, and
-- league_votes, plus the get_or_create_current_league() function
-- and supporting views.
--
-- Scheduling design: leagues run in a fixed 14-day cadence anchored
-- to a Friday-noon-UTC epoch (_LEAGUE_EPOCH below), so "which league
-- is this?" is pure date arithmetic — no cron job is needed to keep
-- it correct even if nothing has called the app in a while. The
-- get_or_create_current_league() function computes the current
-- period from now(), picks that period's theme (cycling through
-- league_themes by index), and lazily inserts the leagues row for it
-- the first time anyone asks. It's security definer so an ordinary
-- authenticated client can call it without needing insert rights on
-- leagues directly — a malicious client can't forge a bogus period
-- boundary or theme this way, since all of that is computed
-- server-side from now() rather than trusted from the request.
--
-- Safe to run against an existing database: does not drop or rewrite
-- any existing data. Run once in the Supabase SQL Editor.
-- ============================================================

-- ---------- league_themes ----------
-- Curated rotation of themes, cycling in cycle_index order. Managed by
-- hand (SQL Editor / dashboard) — no client-facing insert policy, since
-- these are our content, not user data. Add more rows any time; running
-- out just means the rotation wraps back to cycle_index 0.
create table if not exists public.league_themes (
  cycle_index int primary key,
  title text not null,
  description text not null
);

alter table public.league_themes enable row level security;

insert into public.league_themes (cycle_index, title, description) values
  (0, 'Neon Dreams', 'Paint a scene lit entirely by neon — cities, creatures, or anything that glows.'),
  (1, 'Underwater Ruins', 'A sunken city, a forgotten temple, or anything reclaimed by the sea.'),
  (2, 'Cozy Autumn', 'Warm colors, falling leaves, and the feeling of a good sweater.'),
  (3, 'Robot Companion', 'Design a mechanical friend — helpful, mischievous, or somewhere in between.'),
  (4, 'Floating Islands', 'Landmasses adrift in the sky, connected by nothing but imagination.'),
  (5, 'Midnight Market', 'A bustling bazaar that only opens after dark.'),
  (6, 'Tiny World', 'Something enormous, but drawn as if it fits in the palm of a hand.'),
  (7, 'Storm Chaser', 'Lightning, wind, and the moment right before the sky breaks open.')
on conflict (cycle_index) do nothing;

-- ---------- leagues ----------
-- One row per 2-week period, lazily created by
-- get_or_create_current_league() the first time it's needed.
create table if not exists public.leagues (
  id uuid primary key default gen_random_uuid(),
  period_index bigint not null unique,
  theme_title text not null,
  theme_description text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.leagues enable row level security;

create policy "leagues are publicly readable"
  on public.leagues for select
  using (true);

-- No insert/update/delete policy for leagues: rows are only ever created
-- by get_or_create_current_league(), which runs as security definer.

create or replace function public.get_or_create_current_league()
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  -- 2026-01-02 12:00 UTC — a Friday. Every period boundary is this instant
  -- plus a whole multiple of 14 days, so periods always start Friday noon.
  v_epoch timestamptz := '2026-01-02 12:00:00+00';
  v_period_seconds bigint := 14 * 24 * 3600;
  v_period_index bigint;
  v_starts_at timestamptz;
  v_ends_at timestamptz;
  v_theme_count int;
  v_theme public.league_themes;
  v_league public.leagues;
begin
  v_period_index := floor(extract(epoch from (now() - v_epoch)) / v_period_seconds);
  v_starts_at := v_epoch + (v_period_index * v_period_seconds) * interval '1 second';
  v_ends_at := v_starts_at + v_period_seconds * interval '1 second';

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

  insert into public.leagues (period_index, theme_title, theme_description, starts_at, ends_at)
  values (v_period_index, v_theme.title, v_theme.description, v_starts_at, v_ends_at)
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

-- ---------- league_submissions ----------
-- One entry per user per league. photo_url is copied from the submitted
-- session at submission time so it stays stable even if that session is
-- later deleted (session_id then goes null, photo_url does not).
create table if not exists public.league_submissions (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  session_id uuid references public.sessions (id) on delete set null,
  photo_url text not null,
  caption text,
  created_at timestamptz not null default now(),
  unique (league_id, user_id)
);

alter table public.league_submissions enable row level security;

create policy "league submissions are publicly readable"
  on public.league_submissions for select
  using (true);

create policy "users submit to a league while it is open"
  on public.league_submissions for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.ends_at
    )
  );

create policy "users update their own submission while the league is open"
  on public.league_submissions for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.ends_at
    )
  );

create policy "users delete their own submission while the league is open"
  on public.league_submissions for delete
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.ends_at
    )
  );

-- ---------- league_votes ----------
-- One vote per user per league (not per submission) — casting a new vote
-- means changing your pick, not adding a second one.
create table if not exists public.league_votes (
  league_id uuid not null references public.leagues (id) on delete cascade,
  voter_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  submission_id uuid not null references public.league_submissions (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (league_id, voter_id)
);

alter table public.league_votes enable row level security;

create policy "league votes are publicly readable"
  on public.league_votes for select
  using (true);

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
        and now() < l.ends_at
    )
  );

create policy "users change their own vote while the league is open"
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
        and now() < l.ends_at
    )
  );

create policy "users retract their own vote while the league is open"
  on public.league_votes for delete
  using (
    auth.uid() = voter_id
    and exists (
      select 1 from public.leagues l
      where l.id = league_id and now() < l.ends_at
    )
  );

-- ---------- league_submission_details (view) ----------
-- Submissions joined with the artist's username and live vote count —
-- the single query the submissions grid needs.
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
    coalesce(vc.votes, 0) as votes
  from public.league_submissions ls
  join public.profiles p on p.id = ls.user_id
  left join (
    select submission_id, count(*) as votes
    from public.league_votes
    group by submission_id
  ) vc on vc.submission_id = ls.id;

-- ---------- league_champions (view) ----------
-- The top-voted submission per league (ties broken by earliest
-- submission) — used for "Last Season's Champion".
create view public.league_champions
  with (security_invoker = true) as
  select distinct on (league_id)
    league_id,
    id as submission_id,
    user_id,
    artist_username,
    photo_url,
    votes
  from public.league_submission_details
  order by league_id, votes desc, created_at asc;
