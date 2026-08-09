-- Unfinished / art: destructive Supabase reset
--
-- Run this entire file in the Supabase SQL Editor. It deletes every object
-- and row in the public schema.
-- It intentionally does NOT delete auth.users; delete test accounts from
-- Supabase Dashboard > Authentication > Users if you also want new accounts.
-- Supabase blocks direct SQL deletion of Storage files. To erase uploaded
-- images too, delete the `session-photos` bucket in Dashboard > Storage before
-- running this script; this script then recreates that bucket.

begin;

-- Start with a genuinely clean application database. `cascade` also removes
-- views, functions, policies, triggers, indexes, and dependent data.
drop schema if exists public cascade;
create schema public;
grant usage on schema public to anon, authenticated, service_role;
grant all on schema public to postgres, service_role;

create extension if not exists pgcrypto;

-- Core profiles and creative-work data -------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 3 and 30),
  display_name text not null check (char_length(display_name) between 1 and 80),
  bio text,
  visible_stats text[] not null default '{}',
  pinned_post_id uuid,
  region text check (region in (
    'north_america', 'south_america', 'europe', 'middle_east_africa',
    'south_asia', 'east_asia', 'southeast_asia_oceania'
  )),
  created_at timestamptz not null default now(),
  unique (username)
);
create unique index profiles_username_lower_key on public.profiles (lower(username));

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 140),
  finished_status boolean not null default false,
  completion_percent smallint not null default 0 check (completion_percent between 0 and 100),
  created_at timestamptz not null default now()
);
create index projects_user_id_created_at_idx on public.projects (user_id, created_at desc);

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text,
  stage text,
  tools_used text[] not null default '{}',
  difficulty smallint check (difficulty between 1 and 10),
  duration bigint not null default 0 check (duration >= 0),
  photo_url text,
  view_count bigint not null default 0 check (view_count >= 0),
  created_at timestamptz not null default now()
);
create index sessions_project_id_created_at_idx on public.sessions (project_id, created_at desc);
create index sessions_user_id_created_at_idx on public.sessions (user_id, created_at desc);

alter table public.profiles
  add constraint profiles_pinned_post_id_fkey
  foreign key (pinned_post_id) references public.sessions(id) on delete set null;
create index profiles_pinned_post_id_idx on public.profiles (pinned_post_id)
  where pinned_post_id is not null;

-- Social interactions -------------------------------------------------------
create table public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followee_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_id_idx on public.follows (followee_id);

create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction_type text not null check (reaction_type in ('up', 'down', 'heart', 'laugh', 'wow', 'sad', 'angry')),
  kind text not null check (kind in ('vote', 'emoji')),
  created_at timestamptz not null default now(),
  unique (session_id, user_id, kind),
  check (
    (kind = 'vote' and reaction_type in ('up', 'down')) or
    (kind = 'emoji' and reaction_type in ('heart', 'laugh', 'wow', 'sad', 'angry'))
  )
);
create index reactions_session_id_idx on public.reactions (session_id);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index comments_session_id_created_at_idx on public.comments (session_id, created_at);
create index comments_user_id_idx on public.comments (user_id);

create table public.comment_reports (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.comments(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  unique (comment_id, reporter_id)
);

create table public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_key text not null,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_key)
);

-- Regional weekly league ----------------------------------------------------
create table public.leagues (
  id uuid primary key default gen_random_uuid(),
  period_index integer not null,
  region text not null check (region in (
    'north_america', 'south_america', 'europe', 'middle_east_africa',
    'south_asia', 'east_asia', 'southeast_asia_oceania'
  )),
  theme_title text not null,
  theme_description text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  submissions_close_at timestamptz not null,
  voting_closes_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (period_index, region),
  check (starts_at < submissions_close_at and submissions_close_at < voting_closes_at and voting_closes_at <= ends_at)
);

create table public.league_submissions (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  photo_url text not null check (char_length(photo_url) > 0),
  caption text,
  created_at timestamptz not null default now(),
  unique (league_id, project_id)
);
create index league_submissions_project_id_idx on public.league_submissions (project_id);

create table public.league_ratings (
  league_id uuid not null references public.leagues(id) on delete cascade,
  rater_id uuid not null references auth.users(id) on delete cascade,
  submission_id uuid not null references public.league_submissions(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (league_id, rater_id, submission_id)
);
create index league_ratings_submission_id_idx on public.league_ratings (submission_id);

-- Read models the Flutter app queries --------------------------------------
create view public.reaction_counts as
  select session_id, reaction_type, count(*)::bigint as count
  from public.reactions
  group by session_id, reaction_type;

create view public.follow_counts as
  select p.id as profile_id,
         (select count(*) from public.follows f where f.followee_id = p.id)::bigint as followers_count,
         (select count(*) from public.follows f where f.follower_id = p.id)::bigint as following_count
  from public.profiles p;

create view public.league_submission_details as
  select s.id, s.league_id, s.user_id, p.username as artist_username,
         s.photo_url, s.caption, s.created_at,
         coalesce(sum(r.rating), 0)::bigint as stars,
         pr.id as project_id, pr.title as project_title,
         pr.completion_percent as project_completion_percent,
         pr.finished_status as project_finished_status
  from public.league_submissions s
  join public.profiles p on p.id = s.user_id
  join public.projects pr on pr.id = s.project_id
  left join public.league_ratings r on r.submission_id = s.id and r.league_id = s.league_id
  group by s.id, p.username, pr.id;

create view public.league_champions as
  with ranked as (
    select d.*, l.ends_at,
           row_number() over (partition by d.league_id order by d.stars desc, d.created_at asc, d.id asc) as rank
    from public.league_submission_details d
    join public.leagues l on l.id = d.league_id
    where l.ends_at <= now()
  )
  select league_id, id as submission_id, user_id, artist_username, photo_url, stars
  from ranked
  where rank = 1;

create view public.league_trophies as
  select c.league_id, c.submission_id, c.user_id, c.artist_username, c.photo_url, c.stars,
         l.theme_title, l.theme_description, l.period_index, l.starts_at
  from public.league_champions c
  join public.leagues l on l.id = c.league_id;

-- Functions used by LeagueRepository ---------------------------------------
create or replace function public.get_or_create_current_league(p_region text)
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  v_starts_at timestamptz;
  v_period_index integer;
  v_theme_title text;
  v_theme_description text;
  v_league public.leagues%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_region not in ('north_america', 'south_america', 'europe', 'middle_east_africa', 'south_asia', 'east_asia', 'southeast_asia_oceania') then
    raise exception 'Unknown league region';
  end if;

  v_starts_at := date_trunc('week', timezone('Europe/London', now())) at time zone 'Europe/London';
  v_period_index := floor((v_starts_at::date - date '2024-01-01') / 7.0)::integer;
  case mod(v_period_index, 8)
    when 0 then v_theme_title := 'Small Wonders'; v_theme_description := 'Make something inspired by an overlooked detail.';
    when 1 then v_theme_title := 'After Dark'; v_theme_description := 'Create a piece shaped by the night.';
    when 2 then v_theme_title := 'In Motion'; v_theme_description := 'Capture movement, change, or momentum.';
    when 3 then v_theme_title := 'A Place Remembered'; v_theme_description := 'Turn a meaningful place into art.';
    when 4 then v_theme_title := 'Colour Study'; v_theme_description := 'Let one colour lead the work.';
    when 5 then v_theme_title := 'Made by Hand'; v_theme_description := 'Celebrate texture, process, and craft.';
    when 6 then v_theme_title := 'Future Relic'; v_theme_description := 'Imagine an object found years from now.';
    when 7 then v_theme_title := 'Open Edition'; v_theme_description := 'Make anything you want this week.';
  end case;

  insert into public.leagues (
    period_index, region, theme_title, theme_description,
    starts_at, ends_at, submissions_close_at, voting_closes_at
  ) values (
    v_period_index, p_region, v_theme_title, v_theme_description,
    v_starts_at, v_starts_at + interval '7 days',
    v_starts_at + interval '4 days 14 hours', v_starts_at + interval '7 days'
  )
  on conflict (period_index, region) do update set region = excluded.region
  returning * into v_league;
  return v_league;
end;
$$;

create or replace function public.latest_league_champion(p_region text)
returns public.league_champions
language sql
stable
security definer
set search_path = public
as $$
  select c.*
  from public.league_champions c
  join public.leagues l on l.id = c.league_id
  where l.region = p_region
  order by l.ends_at desc
  limit 1;
$$;

-- An aggregate counter is deliberately used instead of a per-viewer event
-- table. The security-definer function can only add one view per call; app
-- clients cannot directly set a session's count.
create or replace function public.record_session_view(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.sessions
  set view_count = view_count + 1
  where id = p_session_id;
end;
$$;

-- Policies ------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.sessions enable row level security;
alter table public.follows enable row level security;
alter table public.reactions enable row level security;
alter table public.comments enable row level security;
alter table public.comment_reports enable row level security;
alter table public.user_achievements enable row level security;
alter table public.leagues enable row level security;
alter table public.league_submissions enable row level security;
alter table public.league_ratings enable row level security;

create policy "signed-in users read profiles" on public.profiles for select using (auth.uid() is not null);
create policy "create own profile" on public.profiles for insert with check (id = auth.uid());
create policy "update own profile" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy "signed-in users read projects" on public.projects for select using (auth.uid() is not null);
create policy "create own projects" on public.projects for insert with check (user_id = auth.uid());
create policy "update own projects" on public.projects for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "delete own projects" on public.projects for delete using (user_id = auth.uid());

create policy "signed-in users read sessions" on public.sessions for select using (auth.uid() is not null);
create policy "create sessions on own active project" on public.sessions for insert with check (
  user_id = auth.uid() and exists (
    select 1 from public.projects p
    where p.id = project_id and p.user_id = auth.uid() and not p.finished_status
  )
);
create policy "update own sessions" on public.sessions for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "delete own sessions" on public.sessions for delete using (user_id = auth.uid());

create policy "signed-in users read follows" on public.follows for select using (auth.uid() is not null);
create policy "create own follows" on public.follows for insert with check (follower_id = auth.uid());
create policy "delete own follows" on public.follows for delete using (follower_id = auth.uid());

create policy "signed-in users read reactions" on public.reactions for select using (auth.uid() is not null);
create policy "create own reactions" on public.reactions for insert with check (user_id = auth.uid());
create policy "update own reactions" on public.reactions for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "delete own reactions" on public.reactions for delete using (user_id = auth.uid());

create policy "signed-in users read comments" on public.comments for select using (auth.uid() is not null);
create policy "create own comments" on public.comments for insert with check (user_id = auth.uid());
create policy "delete own comments" on public.comments for delete using (
  user_id = auth.uid() or exists (select 1 from public.sessions s where s.id = session_id and s.user_id = auth.uid())
);

create policy "report comments as self" on public.comment_reports for insert with check (reporter_id = auth.uid());
create policy "signed-in users read achievements" on public.user_achievements for select using (auth.uid() is not null);
create policy "unlock own achievements" on public.user_achievements for insert with check (user_id = auth.uid());

create policy "signed-in users read leagues" on public.leagues for select using (auth.uid() is not null);
create policy "signed-in users read league submissions" on public.league_submissions for select using (auth.uid() is not null);
create policy "submit own regional project while open" on public.league_submissions for insert with check (
  user_id = auth.uid()
  and exists (select 1 from public.projects p where p.id = project_id and p.user_id = auth.uid())
  and exists (
    select 1 from public.leagues l join public.profiles p on p.id = auth.uid()
    where l.id = league_id and l.region = p.region and now() < l.submissions_close_at
  )
);
create policy "update own league submission while open" on public.league_submissions for update using (user_id = auth.uid()) with check (
  user_id = auth.uid()
  and exists (select 1 from public.projects p where p.id = project_id and p.user_id = auth.uid())
  and exists (
    select 1 from public.leagues l join public.profiles p on p.id = auth.uid()
    where l.id = league_id and l.region = p.region and now() < l.submissions_close_at
  )
);
create policy "delete own league submission while open" on public.league_submissions for delete using (
  user_id = auth.uid() and exists (select 1 from public.leagues l where l.id = league_id and now() < l.submissions_close_at)
);

create policy "signed-in users read league ratings" on public.league_ratings for select using (auth.uid() is not null);
create policy "rate other regional submissions during voting" on public.league_ratings for insert with check (
  rater_id = auth.uid() and exists (
    select 1 from public.league_submissions s
    join public.leagues l on l.id = s.league_id
    join public.profiles p on p.id = auth.uid()
    where s.id = submission_id and s.league_id = league_ratings.league_id
      and s.user_id <> auth.uid() and l.region = p.region
      and now() >= l.submissions_close_at and now() < l.voting_closes_at
  )
);
create policy "change own rating during voting" on public.league_ratings for update using (rater_id = auth.uid()) with check (
  rater_id = auth.uid() and exists (
    select 1 from public.league_submissions s
    join public.leagues l on l.id = s.league_id
    join public.profiles p on p.id = auth.uid()
    where s.id = submission_id and s.league_id = league_ratings.league_id
      and s.user_id <> auth.uid() and l.region = p.region
      and now() >= l.submissions_close_at and now() < l.voting_closes_at
  )
);
create policy "delete own rating during voting" on public.league_ratings for delete using (
  rater_id = auth.uid() and exists (
    select 1 from public.leagues l
    where l.id = league_id and now() >= l.submissions_close_at and now() < l.voting_closes_at
  )
);

grant select on all tables in schema public to authenticated;
grant insert, update, delete on public.profiles, public.projects, public.sessions,
  public.follows, public.reactions, public.comments,
  public.comment_reports, public.user_achievements, public.league_submissions,
  public.league_ratings to authenticated;
grant select on all tables in schema public to authenticated;
grant execute on function public.get_or_create_current_league(text), public.latest_league_champion(text),
  public.record_session_view(uuid) to authenticated;

-- The app uploads and reads session photos from this public bucket. Storage
-- files cannot be deleted from SQL; preserve them if the bucket still exists.
insert into storage.buckets (id, name, public)
values ('session-photos', 'session-photos', true)
on conflict (id) do update set public = excluded.public;

-- Storage is outside `public`, so drop these explicitly to make the reset
-- safe to run again.
drop policy if exists "public read session photos" on storage.objects;
drop policy if exists "upload own session photos" on storage.objects;
drop policy if exists "update own session photos" on storage.objects;
drop policy if exists "delete own session photos" on storage.objects;
create policy "public read session photos" on storage.objects for select using (bucket_id = 'session-photos');
create policy "upload own session photos" on storage.objects for insert to authenticated with check (
  bucket_id = 'session-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy "update own session photos" on storage.objects for update to authenticated using (
  bucket_id = 'session-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy "delete own session photos" on storage.objects for delete to authenticated using (
  bucket_id = 'session-photos' and (storage.foldername(name))[1] = auth.uid()::text
);

commit;
