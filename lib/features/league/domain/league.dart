/// One weekly league period, as materialized by the
/// `get_or_create_current_league()` Postgres function — the theme text and
/// period boundaries are snapshotted into this row at creation time, so a
/// past league's display never changes even if the underlying theme catalog
/// is edited later.
///
/// Each week has two phases (both computed server-side in Europe/London
/// local time, so British Summer Time shifts them automatically):
///   Mon 00:00 -> Fri 14:00  : submissions open ("it runs")
///   Fri 14:00 -> Sun 00:00  : voting open (rate every entry 1-5 stars)
class League {
  const League({
    required this.id,
    required this.region,
    required this.periodIndex,
    required this.themeTitle,
    required this.themeDescription,
    required this.startsAt,
    required this.endsAt,
    required this.submissionsCloseAt,
    required this.votingClosesAt,
  });

  factory League.fromRow(Map<String, dynamic> row) {
    return League(
      id: row['id'].toString(),
      region: row['region']?.toString() ?? '',
      periodIndex: int.tryParse(row['period_index']?.toString() ?? '') ?? 0,
      themeTitle: row['theme_title']?.toString() ?? '',
      themeDescription: row['theme_description']?.toString() ?? '',
      startsAt: DateTime.tryParse(row['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: DateTime.tryParse(row['ends_at']?.toString() ?? '') ?? DateTime.now(),
      submissionsCloseAt: DateTime.tryParse(row['submissions_close_at']?.toString() ?? '') ?? DateTime.now(),
      votingClosesAt: DateTime.tryParse(row['voting_closes_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String region;
  final int periodIndex;
  final String themeTitle;
  final String themeDescription;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime submissionsCloseAt;
  final DateTime votingClosesAt;

  bool get isSubmissionOpen => DateTime.now().toUtc().isBefore(submissionsCloseAt);

  bool get isVotingOpen {
    final now = DateTime.now().toUtc();
    return !now.isBefore(submissionsCloseAt) && now.isBefore(votingClosesAt);
  }

  /// The time the current phase (submissions, then voting) next changes, or
  /// null once voting has closed for the week.
  DateTime? get nextPhaseBoundary {
    final now = DateTime.now().toUtc();
    if (now.isBefore(submissionsCloseAt)) return submissionsCloseAt;
    if (now.isBefore(votingClosesAt)) return votingClosesAt;
    return null;
  }

  String get phaseLabel {
    if (isSubmissionOpen) return 'Submissions close in';
    if (isVotingOpen) return 'Voting closes in';
    return 'Voting closed';
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
    required this.stars,
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
      stars: int.tryParse(row['stars']?.toString() ?? '') ?? 0,
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
  final int stars;
  final String projectId;
  final String projectTitle;
  final int projectCompletionPercent;
  final bool projectFinishedStatus;

  /// The submitted project as a `projects`-row-shaped map, for opening it in
  /// the shared ProjectDetailScreen (which keys ownership off `user_id`).
  Map<String, dynamic> get projectRow => {
        'id': projectId,
        'title': projectTitle,
        'user_id': userId,
        'completion_percent': projectCompletionPercent,
        'finished_status': projectFinishedStatus,
      };
}

/// The top-starred submission from a past (already-ended) league.
class LeagueChampion {
  const LeagueChampion({
    required this.leagueId,
    required this.submissionId,
    required this.artistUsername,
    required this.photoUrl,
    required this.stars,
  });

  factory LeagueChampion.fromRow(Map<String, dynamic> row) {
    return LeagueChampion(
      leagueId: row['league_id'].toString(),
      submissionId: row['submission_id'].toString(),
      artistUsername: row['artist_username']?.toString() ?? '',
      photoUrl: row['photo_url']?.toString() ?? '',
      stars: int.tryParse(row['stars']?.toString() ?? '') ?? 0,
    );
  }

  final String leagueId;
  final String submissionId;
  final String artistUsername;
  final String photoUrl;
  final int stars;
}

/// A league a given user won, for their profile's trophy cabinet — the same
/// underlying win as [LeagueChampion], but scoped to one user and carrying
/// the theme/date context needed to show it as a keepsake rather than a
/// live leaderboard fact.
class LeagueTrophy {
  const LeagueTrophy({
    required this.leagueId,
    required this.submissionId,
    required this.photoUrl,
    required this.stars,
    required this.themeTitle,
    required this.themeDescription,
    required this.periodIndex,
    required this.startsAt,
  });

  factory LeagueTrophy.fromRow(Map<String, dynamic> row) {
    return LeagueTrophy(
      leagueId: row['league_id'].toString(),
      submissionId: row['submission_id'].toString(),
      photoUrl: row['photo_url']?.toString() ?? '',
      stars: int.tryParse(row['stars']?.toString() ?? '') ?? 0,
      themeTitle: row['theme_title']?.toString() ?? '',
      themeDescription: row['theme_description']?.toString() ?? '',
      periodIndex: int.tryParse(row['period_index']?.toString() ?? '') ?? 0,
      startsAt: DateTime.tryParse(row['starts_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String leagueId;
  final String submissionId;
  final String photoUrl;
  final int stars;
  final String themeTitle;
  final String themeDescription;
  final int periodIndex;
  final DateTime startsAt;
}
