enum FeedPostType { session, slideshow }

/// A post in the scrollable feed: either a single finished-session photo,
/// or a slideshow of a project's session photos in chronological order.
class FeedPost {
  const FeedPost({
    required this.id,
    required this.type,
    required this.projectId,
    required this.projectTitle,
    required this.artist,
    required this.slideCount,
    required this.views,
    required this.datePosted,
    required this.description,
    required this.toolsUsed,
    required this.timeTaken,
    this.photoUrl,
    this.stage,
    this.difficulty,
  });

  final String id;
  final FeedPostType type;
  final String projectId;
  final String projectTitle;
  final String artist;
  final int slideCount;
  final int views;
  final DateTime datePosted;
  final String description;
  final List<String> toolsUsed;
  final String timeTaken;
  final String? photoUrl;

  /// Raw session fields kept around (in addition to [description], which is
  /// a human-readable summary) so the post can be edited in place.
  final String? stage;
  final int? difficulty;
}
