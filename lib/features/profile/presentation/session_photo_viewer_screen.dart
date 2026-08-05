import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../feed/domain/feed_post.dart';
import '../../projects/providers.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatDate(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// Full-screen, pinch-zoomable, read-only view of one session's photo —
/// reached from a project's photo grid. Unlike [PostDetailScreen], this has
/// no edit affordances: it's someone else's project.
class SessionPhotoViewerScreen extends ConsumerStatefulWidget {
  const SessionPhotoViewerScreen({super.key, required this.post});

  final FeedPost post;

  @override
  ConsumerState<SessionPhotoViewerScreen> createState() => _SessionPhotoViewerScreenState();
}

class _SessionPhotoViewerScreenState extends ConsumerState<SessionPhotoViewerScreen> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget, same dedup-on-the-server pattern as the feed card and
    // PostDetailScreen — opening the photo is a view event.
    ref.read(sessionsRepositoryProvider).recordView(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final photoUrl = post.photoUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(Icons.image_not_supported, size: 64, color: Colors.white38)
                  : InteractiveViewer(
                      child: CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.contain),
                    ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
                  alignment: Alignment.center,
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: DefaultTextStyle(
                style: GoogleFonts.chewy(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(post.displayTitle, style: GoogleFonts.chewy(fontSize: 20, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(post.datePosted),
                      style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
