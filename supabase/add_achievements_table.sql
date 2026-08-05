-- ============================================================
-- Additive migration — creates user_achievements, the persisted
-- record of which achievements a user has actually unlocked. The
-- achievement catalog itself (key, title, description, unlock
-- condition) lives in the Flutter client (lib/features/achievements),
-- same as most apps; this table only needs to record *that* and
-- *when* a given user cleared one.
--
-- Safe to run against an existing database: does not drop or rewrite
-- any existing data. Run once in the Supabase SQL Editor.
-- ============================================================

create table if not exists public.user_achievements (
  user_id uuid not null references auth.users (id) on delete cascade,
  achievement_key text not null,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_key)
);

alter table public.user_achievements enable row level security;

create policy "user achievements are publicly readable"
  on public.user_achievements for select
  using (true);

create policy "users unlock their own achievements"
  on public.user_achievements for insert
  with check (auth.uid() = user_id);
