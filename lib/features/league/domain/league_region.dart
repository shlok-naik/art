/// Curated list of broad regions leagues are scoped to — deliberately
/// coarse (continent-ish groupings, not countries) so no region's weekly
/// league is left too thin to feel like a competition. Keys are stored in
/// `profiles.region` / `leagues.region`; never rename an existing key, only
/// add new ones, or existing picks and past leagues orphan.
const leagueRegions = <String, String>{
  'north_america': 'North America',
  'south_america': 'South America',
  'europe': 'Europe',
  'middle_east_africa': 'Middle East & Africa',
  'south_asia': 'South Asia',
  'east_asia': 'East Asia',
  'southeast_asia_oceania': 'Southeast Asia & Oceania',
};

String leagueRegionLabel(String key) => leagueRegions[key] ?? key;

/// Thrown by [currentLeagueProvider] when the signed-in user hasn't picked
/// a region yet — distinct from a real fetch failure so the league screen
/// can show a region picker instead of an error state.
class NoRegionSelectedException implements Exception {
  const NoRegionSelectedException();
}
