import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/league_repository.dart';
import 'domain/league.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(ref.watch(supabaseClientProvider));
});

/// The current 2-week league — materialized lazily server-side the first
/// time anyone asks (see get_or_create_current_league() in
/// add_league_tables.sql), so this is safe to watch from app start with no
/// separate "is there a league yet?" check.
final currentLeagueProvider = FutureProvider.autoDispose<League>((ref) {
  return ref.watch(leagueRepositoryProvider).fetchCurrentLeague();
});

/// Submissions for [leagueId], highest-voted first.
final leagueSubmissionsProvider =
    FutureProvider.autoDispose.family<List<LeagueSubmission>, String>((ref, leagueId) {
  return ref.watch(leagueRepositoryProvider).fetchSubmissions(leagueId);
});

/// The submission id the signed-in user has voted for in [leagueId], or
/// null if they haven't voted yet.
final myLeagueVoteProvider = FutureProvider.autoDispose.family<String?, String>((ref, leagueId) {
  return ref.watch(leagueRepositoryProvider).fetchMyVote(leagueId);
});

/// The signed-in user's own submission to [leagueId], or null if they
/// haven't entered this league yet.
final myLeagueSubmissionProvider =
    FutureProvider.autoDispose.family<LeagueSubmission?, String>((ref, leagueId) {
  return ref.watch(leagueRepositoryProvider).fetchMySubmission(leagueId);
});

/// The winning entry from the most recently ended league, if any.
final latestLeagueChampionProvider = FutureProvider.autoDispose<LeagueChampion?>((ref) {
  return ref.watch(leagueRepositoryProvider).fetchLatestChampion();
});
