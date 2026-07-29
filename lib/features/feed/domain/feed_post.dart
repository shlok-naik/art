enum FeedPostType { session, slideshow }

/// A post in the scrollable feed: either a single finished-session photo,
/// or a slideshow of a project's session photos in chronological order.
class FeedPost {
  const FeedPost({
    required this.id,
    required this.type,
    required this.projectTitle,
    required this.artist,
    required this.slideCount,
    required this.views,
    required this.datePosted,
    required this.description,
    required this.toolsUsed,
    required this.timeTaken,
  });

  final String id;
  final FeedPostType type;
  final String projectTitle;
  final String artist;
  final int slideCount;
  final int views;
  final DateTime datePosted;
  final String description;
  final List<String> toolsUsed;
  final String timeTaken;
}

// Placeholder feed data until the real feed is wired up to the backend.
final List<FeedPost> dummyFeedPosts = [
  FeedPost(
    id: '1',
    type: FeedPostType.session,
    projectTitle: 'Neon Alley',
    artist: 'mika_draws',
    slideCount: 1,
    views: 1240,
    datePosted: DateTime(2026, 7, 24),
    description: 'Blocking in the base colors for the alleyway scene.',
    toolsUsed: ['Procreate', 'Apple Pencil'],
    timeTaken: '1h 12m',
  ),
  FeedPost(
    id: '2',
    type: FeedPostType.slideshow,
    projectTitle: 'Underwater Ruins',
    artist: 'lunar_art',
    slideCount: 5,
    views: 8931,
    datePosted: DateTime(2026, 7, 22),
    description: 'Full session breakdown from sketch to final render.',
    toolsUsed: ['Photoshop', 'Wacom Tablet'],
    timeTaken: '6h 40m',
  ),
  FeedPost(
    id: '3',
    type: FeedPostType.session,
    projectTitle: 'Portrait Study #4',
    artist: 'inkwell_jo',
    slideCount: 1,
    views: 412,
    datePosted: DateTime(2026, 7, 21),
    description: 'Working on skin tone gradients.',
    toolsUsed: ['Krita'],
    timeTaken: '45m',
  ),
  FeedPost(
    id: '4',
    type: FeedPostType.slideshow,
    projectTitle: 'Dragon Companion',
    artist: 'pixel_finch',
    slideCount: 4,
    views: 3067,
    datePosted: DateTime(2026, 7, 19),
    description: 'From rough thumbnail to finished character sheet.',
    toolsUsed: ['Clip Studio Paint', 'Drawing Tablet'],
    timeTaken: '4h 05m',
  ),
  FeedPost(
    id: '5',
    type: FeedPostType.session,
    projectTitle: 'Autumn Still Life',
    artist: 'crimson.doe',
    slideCount: 1,
    views: 977,
    datePosted: DateTime(2026, 7, 18),
    description: 'Laying down the underpainting.',
    toolsUsed: ['Acrylic Paint', 'Canvas'],
    timeTaken: '2h 30m',
  ),
  FeedPost(
    id: '6',
    type: FeedPostType.slideshow,
    projectTitle: 'City at Dusk',
    artist: 'sketchy_sam',
    slideCount: 3,
    views: 1655,
    datePosted: DateTime(2026, 7, 15),
    description: 'Three sessions building up the skyline and lighting.',
    toolsUsed: ['Procreate', 'iPad'],
    timeTaken: '3h 15m',
  ),
];
