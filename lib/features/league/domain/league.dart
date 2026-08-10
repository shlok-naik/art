/// Which of the three windows a league is currently in, per the real
/// weekly cadence implemented server-side in `get_or_create_current_league()`
/// (Mon start -> Fri 2pm submissions close -> Sun voting closes -> Mon the
/// next league starts).
enum LeaguePhase { submissions, votingOnly, ended }

/// One week-long league period, as materialized by the
/// `get_or_create_current_league()` Postgres function — the theme text and
/// period boundaries are snapshotted into this row at creation time, so a
/// past league's display never changes even if the underlying theme catalog
/// is edited later.
///
/// A league runs through three windows, not a single open/closed state:
/// projects can be submitted from [startsAt] until [submissionsCloseAt]
/// (Friday), voting stays open until [votingClosesAt] (Sunday) — including
/// on submissions made earlier that week — and the league is fully over at
/// [endsAt] (the following Monday), when the next one begins.
class League {
  const League({
    required this.id,
    required this.periodIndex,
    required this.themeTitle,
    required this.themeDescription,
    required this.startsAt,
    required this.submissionsCloseAt,
    required this.votingClosesAt,
    required this.endsAt,
  });

  factory League.fromRow(Map<String, dynamic> row) {
    return League(
      id: row['id'].toString(),
      periodIndex: int.tryParse(row['period_index']?.toString() ?? '') ?? 0,
      themeTitle: row['theme_title']?.toString() ?? '',
      themeDescription: row['theme_description']?.toString() ?? '',
      startsAt: DateTime.tryParse(row['starts_at']?.toString() ?? '') ?? DateTime.now(),
      submissionsCloseAt: DateTime.tryParse(row['submissions_close_at']?.toString() ?? '') ?? DateTime.now(),
      votingClosesAt: DateTime.tryParse(row['voting_closes_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: DateTime.tryParse(row['ends_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final int periodIndex;
  final String themeTitle;
  final String themeDescription;
  final DateTime startsAt;
  final DateTime submissionsCloseAt;
  final DateTime votingClosesAt;
  final DateTime endsAt;

  bool get isSubmissionOpen => DateTime.now().toUtc().isBefore(submissionsCloseAt);

  /// Voting stays open through the submission window too — you can vote on
  /// earlier entries while others are still submitting.
  bool get isVotingOpen => DateTime.now().toUtc().isBefore(votingClosesAt);

  LeaguePhase get phase {
    if (isSubmissionOpen) return LeaguePhase.submissions;
    if (isVotingOpen) return LeaguePhase.votingOnly;
    return LeaguePhase.ended;
  }
}

/// One artist's entry in a league — a whole project, browsable session by
/// session — with its live vote count.
class LeagueSubmission {
  const LeagueSubmission({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.artistUsername,
    required this.photoUrl,
    required this.votes,
    required this.projectId,
    required this.projectTitle,
    required this.projectCompletionPercent,
    required this.projectFinishedStatus,
    this.caption,
  });

  factory LeagueSubmission.fromRow(Map<String, dynamic> row) {
    return LeagueSubmission(
      id: row['id'].toString(),
      leagueId: row['league_id'].toString(),
      userId: row['user_id'].toString(),
      artistUsername: row['artist_username']?.toString() ?? '',
      photoUrl: row['photo_url']?.toString() ?? '',
      caption: row['caption']?.toString(),
      votes: int.tryParse(row['votes']?.toString() ?? '') ?? 0,
      projectId: row['project_id']?.toString() ?? '',
      projectTitle: row['project_title']?.toString() ?? '',
      projectCompletionPercent: int.tryParse(row['project_completion_percent']?.toString() ?? '') ?? 0,
      projectFinishedStatus: row['project_finished_status'] == true,
    );
  }

  final String id;
  final String leagueId;
  final String userId;
  final String artistUsername;
  final String photoUrl;
  final String? caption;
  final int votes;
  final String projectId;
  final String projectTitle;
  final int projectCompletionPercent;
  final bool projectFinishedStatus;
}

/// The top-voted submission from a past (already-ended) league.
class LeagueChampion {
  const LeagueChampion({
    required this.leagueId,
    required this.submissionId,
    required this.artistUsername,
    required this.photoUrl,
    required this.votes,
  });

  factory LeagueChampion.fromRow(Map<String, dynamic> row) {
    return LeagueChampion(
      leagueId: row['league_id'].toString(),
      submissionId: row['submission_id'].toString(),
      artistUsername: row['artist_username']?.toString() ?? '',
      photoUrl: row['photo_url']?.toString() ?? '',
      votes: int.tryParse(row['votes']?.toString() ?? '') ?? 0,
    );
  }

  final String leagueId;
  final String submissionId;
  final String artistUsername;
  final String photoUrl;
  final int votes;
}
