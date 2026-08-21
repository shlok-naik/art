import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/league.dart';

class LeagueRepository {
  LeagueRepository(this._client);

  final SupabaseClient _client;

  /// The current weekly league for [city], lazily materialized server-side
  /// by the `get_or_create_current_league()` Postgres function — security
  /// definer, so period boundaries and themes are computed from now()
  /// server-side rather than trusted from the client. [city] is still
  /// passed through as an ordinary argument (not trusted for anything
  /// sensitive) — it only selects which of that week's parallel per-city
  /// rows comes back, matching everyone who entered the same city into the
  /// same league.
  Future<League> fetchCurrentLeague(String city) async {
    // The function returns a single `leagues` row (not SETOF), so PostgREST
    // hands it back as one JSON object rather than a one-element array.
    final result = await _client.rpc('get_or_create_current_league', params: {'p_city': city});
    return League.fromRow(Map<String, dynamic>.from(result as Map));
  }

  /// All submissions for [leagueId] with their live vote counts, highest
  /// first.
  Future<List<LeagueSubmission>> fetchSubmissions(String leagueId) async {
    final rows = await _client
        .from('league_submission_details')
        .select()
        .eq('league_id', leagueId)
        .order('stars', ascending: false);
    return [for (final row in List<Map<String, dynamic>>.from(rows)) LeagueSubmission.fromRow(row)];
  }

  /// The signed-in user's ratings in [leagueId], keyed by submission id —
  /// drives which stars show as already-filled in the voting feed.
  Future<Map<String, int>> fetchMyRatings(String leagueId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const {};
    final rows = await _client
        .from('league_ratings')
        .select('submission_id, rating')
        .eq('league_id', leagueId)
        .eq('rater_id', userId);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['submission_id'].toString(): int.tryParse(row['rating']?.toString() ?? '') ?? 0,
    };
  }

  /// Submits [projectId] (with its current cover [photoUrl]) as one of the
  /// signed-in user's entries to [leagueId]. A user may submit multiple
  /// projects to the same league; resubmitting the *same* project replaces
  /// its entry (upsert on the league_id+project_id unique constraint)
  /// rather than erroring.
  Future<void> submitProject({
    required String leagueId,
    required String projectId,
    required String photoUrl,
    String? caption,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('league_submissions').upsert(
      {
        'league_id': leagueId,
        'user_id': userId,
        'project_id': projectId,
        'photo_url': photoUrl,
        'caption': caption,
      },
      onConflict: 'league_id,project_id',
    );
  }

  /// Withdraws the signed-in user's own submission. RLS rejects this once
  /// the submission phase has closed.
  Future<void> unsubmit(String submissionId) async {
    final deleted = await _client.from('league_submissions').delete().eq('id', submissionId).select('id');
    if (deleted.isEmpty) {
      throw Exception('Submission was not removed (not found, or the league has ended)');
    }
  }

  /// Casts (or changes) the signed-in user's 1-5 star rating for
  /// [submissionId] in [leagueId]. RLS rejects this outside the voting
  /// phase or if the submission is the voter's own.
  Future<void> rateSubmission({
    required String leagueId,
    required String submissionId,
    required int rating,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('league_ratings').upsert(
      {'league_id': leagueId, 'rater_id': userId, 'submission_id': submissionId, 'rating': rating},
      onConflict: 'league_id,rater_id,submission_id',
    );
  }

  /// The winning submission of the most recently *ended* league the
  /// signed-in user was a member of, if there is one yet — used for the
  /// "Last Season's Champion" card. Matched by league membership rather
  /// than city, since a city can be split across several capacity-capped
  /// shards and only membership pins down which shard's champion is
  /// "theirs" — so this is a function rather than a plain view select.
  Future<LeagueChampion?> fetchLatestChampion() async {
    final result = await _client.rpc('latest_league_champion');
    if (result == null) return null;
    return LeagueChampion.fromRow(Map<String, dynamic>.from(result as Map));
  }

  /// Every league [userId] has won, most recent first — the trophy cabinet
  /// shown on their profile. Backed by the `league_trophies` view (winner
  /// per league, joined with that league's theme/date).
  Future<List<LeagueTrophy>> fetchTrophies(String userId) async {
    final rows = await _client
        .from('league_trophies')
        .select()
        .eq('user_id', userId)
        .order('starts_at', ascending: false);
    return [for (final row in List<Map<String, dynamic>>.from(rows)) LeagueTrophy.fromRow(row)];
  }

  /// Atomically marks celebrated every trophy the signed-in user has won
  /// but hasn't seen the celebration for yet, and returns just the ones
  /// newly claimed by this call — a single insert-and-return round trip
  /// server-side (`claim_newly_won_trophies()`), so two overlapping calls
  /// (e.g. a Riverpod rebuild racing an earlier one) can't double-fire the
  /// celebration the way a separate fetch-then-mark loop could.
  Future<List<LeagueTrophy>> claimNewlyWonTrophies() async {
    final rows = await _client.rpc('claim_newly_won_trophies');
    return [for (final row in List<Map<String, dynamic>>.from(rows)) LeagueTrophy.fromRow(row)];
  }
}
