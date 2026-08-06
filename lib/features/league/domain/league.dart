/// One 2-week league period, as materialized by the
/// `get_or_create_current_league()` Postgres function — the theme text and
/// period boundaries are snapshotted into this row at creation time, so a
/// past league's display never changes even if the underlying theme catalog
/// is edited later.
class League {
  const League({
    required this.id,
    required this.periodIndex,
    required this.themeTitle,
    required this.themeDescription,
    required this.startsAt,
    required this.endsAt,
  });

  factory League.fromRow(Map<String, dynamic> row) {
    return League(
      id: row['id'].toString(),
      periodIndex: int.tryParse(row['period_index']?.toString() ?? '') ?? 0,
      themeTitle: row['theme_title']?.toString() ?? '',
      themeDescription: row['theme_description']?.toString() ?? '',
      startsAt: DateTime.tryParse(row['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: DateTime.tryParse(row['ends_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final int periodIndex;
  final String themeTitle;
  final String themeDescription;
  final DateTime startsAt;
  final DateTime endsAt;

  bool get isOpen => DateTime.now().toUtc().isBefore(endsAt);
}

/// One artist's entry in a league, with its live vote count.
class LeagueSubmission {
  const LeagueSubmission({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.artistUsername,
    required this.photoUrl,
    required this.votes,
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
    );
  }

  final String id;
  final String leagueId;
  final String userId;
  final String artistUsername;
  final String photoUrl;
  final String? caption;
  final int votes;
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
