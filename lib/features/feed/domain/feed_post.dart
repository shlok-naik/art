enum FeedPostType { session, slideshow }

String _formatTimeTaken(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  return '${minutes}m';
}

/// A post in the scrollable feed: either a single finished-session photo,
/// or a slideshow of a project's session photos in chronological order.
class FeedPost {
  const FeedPost({
    required this.id,
    required this.type,
    required this.projectId,
    required this.projectTitle,
    required this.userId,
    required this.artist,
    required this.slideCount,
    required this.views,
    required this.datePosted,
    required this.description,
    required this.toolsUsed,
    required this.timeTaken,
    this.sessionName,
    this.photoUrl,
    this.stage,
    this.difficulty,
  });

  /// Builds a post from a raw `sessions` row and its parent `projects` row
  /// (as returned by Supabase, either via a `projects!inner(...)` embed or
  /// fetched separately) — the single place that maps that shape to a
  /// [FeedPost], used by both the feed repository and screens that only have
  /// a session/project pair on hand (e.g. a project's "Past Sessions" list).
  factory FeedPost.fromRow({
    required Map<String, dynamic> session,
    required Map<String, dynamic> project,
    required String artist,
  }) {
    final projectId = project['id']?.toString() ?? session['project_id'].toString();
    final projectTitle = project['title']?.toString() ?? projectId;
    final sessionName = session['name']?.toString();
    final durationSeconds = int.tryParse(session['duration']?.toString() ?? '') ?? 0;
    final stage = session['stage']?.toString();
    final toolsUsedRaw = session['tools_used'];

    return FeedPost(
      id: session['id'].toString(),
      type: FeedPostType.session,
      projectId: projectId,
      projectTitle: projectTitle,
      sessionName: (sessionName != null && sessionName.isNotEmpty) ? sessionName : null,
      userId: project['user_id']?.toString() ?? '',
      artist: artist,
      slideCount: 1,
      views: 0,
      datePosted: DateTime.tryParse(session['created_at']?.toString() ?? '') ?? DateTime.now(),
      description: stage != null ? 'Working on: $stage' : 'A session from "$projectTitle".',
      toolsUsed: toolsUsedRaw is List
          ? toolsUsedRaw.map((tool) => tool.toString()).toList()
          : const <String>[],
      timeTaken: _formatTimeTaken(durationSeconds),
      photoUrl: session['photo_url']?.toString(),
      stage: stage,
      difficulty: int.tryParse(session['difficulty']?.toString() ?? ''),
    );
  }

  final String id;
  final FeedPostType type;
  final String projectId;
  final String projectTitle;

  /// The session's own name, if the artist gave it one — takes priority
  /// over the project title wherever a post needs a single display title.
  final String? sessionName;

  /// The id of the user (project owner) who posted this.
  final String userId;
  final String artist;
  final int slideCount;
  final int views;
  final DateTime datePosted;
  final String description;
  final List<String> toolsUsed;
  final String timeTaken;
  final String? photoUrl;
  final String? stage;
  final int? difficulty;

  /// What the UI should show as this post's title: the session's own name
  /// if it has one, otherwise the project it belongs to.
  String get displayTitle {
    final name = sessionName;
    return (name != null && name.isNotEmpty) ? name : projectTitle;
  }
}
