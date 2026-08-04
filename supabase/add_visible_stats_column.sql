-- ============================================================
-- Additive migration — adds the visible_stats column used by the
-- profile Stats page (lets a user choose which stats are public).
--
-- Safe to run against an existing database: does not drop or
-- rewrite any existing data. Run once in the Supabase SQL Editor.
-- ============================================================

alter table public.profiles
  add column if not exists visible_stats text[] not null default '{posts,followers,following}';
