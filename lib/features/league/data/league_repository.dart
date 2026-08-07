import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/league.dart';

class LeagueRepository {
  LeagueRepository(this._client);

  final SupabaseClient _client;

  /// The current 2-week league, lazily materialized server-side by
  /// `get_or_create_current_league()` — see add_league_tables.sql for why
  /// this is a security-definer function rather than a client upsert.
  Future<League> fetchCurrentLeague() async {
    // The function returns a single `leagues` row (not SETOF), so PostgREST
    // hands it back as one JSON object rather than a one-element array.
    final result = await _client.rpc('get_or_create_current_league');
    return League.fromRow(Map<String, dynamic>.from(result as Map));
  }

  /// All submissions for [leagueId] with their live vote counts, highest
  /// first.
  Future<List<LeagueSubmission>> fetchSubmissions(String leagueId) async {
    final rows = await _client
        .from('league_submission_details')
        .select()
        .eq('league_id', leagueId)
        .order('votes', ascending: false);
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
  /// the league has ended (see "users delete their own submission while the
  /// league is open" in add_league_tables.sql).
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

  /// The winning submission of the most recently *ended* league, if there
  /// is one yet — used for the "Last Season's Champion" card.
  Future<LeagueChampion?> fetchLatestChampion() async {
    final pastLeagues = await _client
        .from('leagues')
        .select('id')
        .lt('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('ends_at', ascending: false)
        .limit(1);
    final pastLeagueRows = List<Map<String, dynamic>>.from(pastLeagues);
    if (pastLeagueRows.isEmpty) return null;
    final leagueId = pastLeagueRows.first['id'].toString();

    final row =
        await _client.from('league_champions').select().eq('league_id', leagueId).maybeSingle();
    return row == null ? null : LeagueChampion.fromRow(row);
  }
}
