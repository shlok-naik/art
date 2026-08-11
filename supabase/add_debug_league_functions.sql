-- ============================================================
-- Debug-only companions to public.get_or_create_current_league(), for
-- tool/simulate_league.dart. That tool authenticates with just the app's
-- anon key (no real user login — see its header comment), so it can't
-- call the real functions the app uses: those require auth.uid() to be
-- set and are granted only to `authenticated`.
--
-- These are granted to anon instead, with no auth check. Not meant to be
-- reachable from the app itself — only from the local test-mode
-- controller. Run once in the Supabase SQL Editor.
-- ============================================================

create or replace function public.debug_get_or_create_current_league(p_region text)
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

grant execute on function public.debug_get_or_create_current_league(text) to anon;

-- Overwrites a league's phase boundaries so the test-mode controller can
-- fast-forward submissions -> voting -> closed. Bypasses the table's own
-- `starts_at < submissions_close_at < voting_closes_at <= ends_at` check
-- constraint the same way any direct update would — the caller (the debug
-- tool) is responsible for passing sane timestamps.
create or replace function public.debug_set_league_window(
  p_league_id uuid,
  p_submissions_close_at timestamptz,
  p_voting_closes_at timestamptz
)
returns public.leagues
language plpgsql
security definer
set search_path = public
as $$
declare
  v_league public.leagues%rowtype;
begin
  update public.leagues
  set submissions_close_at = p_submissions_close_at,
      voting_closes_at = p_voting_closes_at
  where id = p_league_id
  returning * into v_league;

  if not found then
    raise exception 'League % not found', p_league_id;
  end if;

  return v_league;
end;
$$;

grant execute on function public.debug_set_league_window(uuid, timestamptz, timestamptz) to anon;
