import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/providers.dart';
import '../../shell/main_shell.dart';
import 'post_detail_screen.dart';

final _isGridViewProvider = StateProvider<bool>((ref) => false);

/// The current user's own posts, viewable as a vertical one-by-one feed or a
/// 2-column grid. Tapping any post opens it in full detail.
class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(myPostsProvider);
    final isGrid = ref.watch(_isGridViewProvider);

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(
          context,
          'My Posts',
          actions: [
            IconButton(
              icon: Icon(isGrid ? Icons.view_agenda_outlined : Icons.grid_view_outlined),
              tooltip: isGrid ? 'Switch to list view' : 'Switch to grid view',
              onPressed: () =>
                  ref.read(_isGridViewProvider.notifier).state = !isGrid,
            ),
          ],
        ),
        body: SafeArea(
          child: postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No posts yet — finish a session to see it here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chewy(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                );
              }
              return isGrid ? _PostGrid(posts: posts) : _PostList(posts: posts);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(myPostsProvider),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}

void _openPost(BuildContext context, FeedPost post) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
  );
}

class _PostList extends StatelessWidget {
  const _PostList({required this.posts});

  final List<FeedPost> posts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _PostTile(post: posts[index], isGrid: false),
    );
  }
}

class _PostGrid extends StatelessWidget {
  const _PostGrid({required this.posts});

  final List<FeedPost> posts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) => _PostTile(post: posts[index], isGrid: true),
    );
  }
}

class _PostTile extends ConsumerWidget {
  const _PostTile({required this.post, required this.isGrid});

  final FeedPost post;
  final bool isGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(sessionReactionsProvider(post.id)).value?.total ?? 0;
    final photoUrl = post.photoUrl;

    return GestureDetector(
      onTap: () => _openPost(context, post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: isGrid ? 1 : 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColor, width: kBorderWidth),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: isGrid ? 15 : 18),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 16, color: kAccentColor),
              const SizedBox(width: 4),
              Text(
                '${formatCount(total)} reactions',
                style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
