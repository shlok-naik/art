import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
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
          AppScreenHeader(
            title: 'My posts',
            trailing: InkWell(
              onTap: () => ref.read(_isGridViewProvider.notifier).state = !isGrid,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Tooltip(
                  message: isGrid ? 'Switch to list view' : 'Switch to grid view',
                  child: AppIcon(
                    isGrid ? AppIcons.feed : AppIcons.grid,
                    color: kInkColor,
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
                      padding: const EdgeInsets.all(AppSpacing.space24),
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
              loading: () => const AppSkeletonScreen(rows: 4),
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
      padding: const EdgeInsets.all(AppSpacing.space20),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space16),
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
      padding: const EdgeInsets.all(AppSpacing.space20),
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
          MuseumFrame(
            radius: 6,
            matWidth: 6,
            child: AspectRatio(
              aspectRatio: isGrid ? 1 : 4 / 3,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const _MissingPhoto()
                  : CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: kSurfaceColor),
                      errorWidget: (context, url, error) => const _MissingPhoto(),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            post.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appHeadlineStyle(fontSize: 14, italic: true),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.heartFilled, size: 11, color: kGoldColor),
              const SizedBox(width: AppSpacing.space4),
              Text(
                '${formatCount(total)} reactions',
                style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGoldColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurfaceColor,
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.image, size: 36, color: kMutedColor),
    );
  }
}
