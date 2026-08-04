import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/app_styles.dart';
import '../../feed/domain/feed_post.dart';
import '../domain/project_gallery.dart';
import 'session_photo_viewer_screen.dart';

/// All of a project's photographed sessions, oldest-to-newest progress
/// shown as a photo grid — reached by tapping a project circle on a
/// profile. Read-only: no session capture or editing, unlike the owner's
/// [ProjectDetailScreen].
class ProjectGalleryScreen extends StatelessWidget {
  const ProjectGalleryScreen({super.key, required this.gallery, required this.artist});

  final ProjectGallery gallery;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, gallery.title),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: gallery.sessions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final session = gallery.sessions[index];
            final photoUrl = session['photo_url']?.toString();
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionPhotoViewerScreen(
                    post: FeedPost.fromRow(session: session, project: gallery.project, artist: artist),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: photoUrl == null || photoUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 20, color: Colors.black26),
                      )
                    : CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey.shade100),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported, size: 20, color: Colors.black26),
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
