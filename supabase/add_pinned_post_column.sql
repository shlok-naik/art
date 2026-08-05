-- ============================================================
-- Additive migration — adds the pinned_post_id column used by the
-- public profile's pinned post feature.
--
-- Safe to run against an existing database: does not drop or
-- rewrite any existing data. Run once in the Supabase SQL Editor.
-- ============================================================

alter table public.profiles
  add column if not exists pinned_post_id uuid references public.sessions (id) on delete set null;
