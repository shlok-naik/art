import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/providers.dart';
import '../../shell/main_shell.dart';
import 'post_detail_screen.dart';

final _isGridViewProvider = StateProvider<bool>((ref) => true);

/// The current user's own posts, viewable as a 2-column grid (default) or a
/// vertical list. Tapping any post opens it in full detail.
class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(myPostsProvider);
    final isGrid = ref.watch(_isGridViewProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppNavyHeader(
            title: 'My posts',
            trailing: InkWell(
              onTap: () => ref.read(_isGridViewProvider.notifier).state = !isGrid,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Tooltip(
                  message: isGrid ? 'Switch to list view' : 'Switch to grid view',
                  child: AppIcon(
                    isGrid ? AppIcons.feed : AppIcons.grid,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No posts yet — finish a session to see it here.',
                        textAlign: TextAlign.center,
                        style: appBodyStyle(fontSize: 14, color: kMutedColor),
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
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) => goToMainTab(context, ref, i),
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
      padding: const EdgeInsets.all(18),
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
      padding: const EdgeInsets.all(18),
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
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Container(
                      color: kSurfaceColor,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 40, color: kMutedColor),
                    )
                  : CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: kSurfaceColor),
                      errorWidget: (context, url, error) => Container(
                        color: kSurfaceColor,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 40, color: kMutedColor),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.heartFilled, size: 14, color: kAccentColor),
              const SizedBox(width: 5),
              Text(
                '${formatCount(total)} reactions',
                style: appBodyStyle(fontSize: 12, color: kMutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
