/// Pairs each of a user's projects with its most recent session photo as a
/// cover — the join [myProjectsWithCoverProvider] needs for the league
/// submission picker. Projects with no session photo yet are excluded.
///
/// [sessions] must be ordered newest-first per project (as
/// `SessionsRepository.fetchSessionsForProjects` already returns them, via
/// its `created_at desc` query) — the first photo seen for a project is
/// treated as its cover.
List<(Map<String, dynamic> project, String coverPhotoUrl)> projectsWithCoverPhotos({
  required List<Map<String, dynamic>> projects,
  required List<Map<String, dynamic>> sessions,
}) {
  final coverByProjectId = <String, String>{};
  for (final session in sessions) {
    final projectId = session['project_id']?.toString();
    final photoUrl = session['photo_url']?.toString();
    if (projectId == null || photoUrl == null || photoUrl.isEmpty) continue;
    coverByProjectId.putIfAbsent(projectId, () => photoUrl);
  }

  return [
    for (final project in projects)
      if (coverByProjectId[project['id'].toString()] case final cover?) (project, cover),
  ];
}
