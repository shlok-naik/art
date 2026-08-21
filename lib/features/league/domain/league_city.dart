/// Free-text city users compete by — leagues are matched automatically to
/// everyone who entered the same city, rather than picked from a fixed
/// region list. Keys are stored in `profiles.city` / `leagues.city`.

/// Normalizes a user-entered city name into the canonical form used for
/// storage and matching, so "new york", "New York ", and "NEW  YORK" all
/// resolve to the same league: trimmed, single-spaced, and title-cased.
String normalizeCityName(String raw) {
  final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  return collapsed
      .split(' ')
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

/// Thrown by [currentLeagueProvider] when the signed-in user hasn't picked
/// a city yet — distinct from a real fetch failure so the league screen
/// can show a city picker instead of an error state.
class NoCitySelectedException implements Exception {
  const NoCitySelectedException();
}
