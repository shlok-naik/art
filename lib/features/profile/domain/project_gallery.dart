/// A user's project, together with the photographed sessions logged
/// against it — drives the "Projects" circles row on a profile and the
/// gallery screen behind each circle.
class ProjectGallery {
  const ProjectGallery({required this.project, required this.sessions});

  final Map<String, dynamic> project;

  /// Sessions with a photo for this project, newest first — sessions.first
  /// is the most recent ("final") session, used as the circle preview.
  final List<Map<String, dynamic>> sessions;

  String get title => project['title']?.toString() ?? project['id'].toString();

  String? get previewPhotoUrl => sessions.isEmpty ? null : sessions.first['photo_url']?.toString();
}
