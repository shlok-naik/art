-- ============================================================
-- Additive migration — adds the bio column used by the profile
-- header (public profile and edit profile).
--
-- Safe to run against an existing database: does not drop or
-- rewrite any existing data. Run once in the Supabase SQL Editor.
-- ============================================================

alter table public.profiles
  add column if not exists bio text;
