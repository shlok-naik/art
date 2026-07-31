-- ============================================================
-- Unfinished — full schema reset
--
-- Drops and recreates profiles, projects, sessions, reactions,
-- and the reaction_counts view with tightened types/constraints
-- and RLS policies matching what the Flutter client actually does.
--
-- DESTROYS ALL EXISTING DATA IN THESE TABLES. Run only in the
-- Supabase SQL Editor after confirming that's acceptable.
-- ============================================================

begin;

drop view if exists public.reaction_counts;
drop table if exists public.reactions;
drop table if exists public.sessions;
drop table if exists public.projects;
drop table if exists public.profiles;

-- ---------- profiles ----------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade default auth.uid(),
  username text not null unique,
  display_name text not null,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are publicly readable"
  on public.profiles for select
  using (true);

create policy "users insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "users update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------- projects ----------
create table public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  title text not null,
  finished_status boolean not null default false,
  completion_percent smallint not null default 0
    check (completion_percent between 0 and 100),
  league_id uuid, -- reserved for the future league feature; no FK yet, that table doesn't exist
  created_at timestamptz not null default now()
);

alter table public.projects enable row level security;

create policy "projects are publicly readable"
  on public.projects for select
  using (true);

create policy "users insert their own projects"
  on public.projects for insert
  with check (auth.uid() = user_id);

create policy "users update their own projects"
  on public.projects for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users delete their own projects"
  on public.projects for delete
  using (auth.uid() = user_id);

-- ---------- sessions ----------
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  name text,
  stage text check (
    stage is null or stage in ('Sketching', 'Outlining', 'Coloring', 'Rendering', 'Finishing Touches')
  ),
  tools_used text[] not null default '{}',
  difficulty smallint check (difficulty is null or difficulty between 1 and 10),
  duration bigint not null default 0 check (duration >= 0),
  photo_url text,
  created_at timestamptz not null default now()
);

alter table public.sessions enable row level security;

create policy "sessions are publicly readable"
  on public.sessions for select
  using (true);

create policy "users insert sessions on their own projects"
  on public.sessions for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.projects p
      where p.id = project_id and p.user_id = auth.uid()
    )
  );

create policy "users update their own sessions"
  on public.sessions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users delete their own sessions"
  on public.sessions for delete
  using (auth.uid() = user_id);

-- ---------- reactions ----------
create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  reaction_type text not null
    check (reaction_type in ('up', 'down', 'heart', 'laugh', 'wow', 'sad', 'angry')),
  kind text not null check (kind in ('vote', 'emoji')),
  created_at timestamptz not null default now(),
  unique (session_id, user_id, kind)
);

alter table public.reactions enable row level security;

create policy "reactions are publicly readable"
  on public.reactions for select
  using (true);

create policy "users insert their own reactions"
  on public.reactions for insert
  with check (auth.uid() = user_id);

create policy "users update their own reactions"
  on public.reactions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users delete their own reactions"
  on public.reactions for delete
  using (auth.uid() = user_id);

-- ---------- reaction_counts (view) ----------
create view public.reaction_counts
  with (security_invoker = true) as
  select session_id, reaction_type, count(*) as count
  from public.reactions
  group by session_id, reaction_type;

commit;
