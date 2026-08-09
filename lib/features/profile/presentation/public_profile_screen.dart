import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievement_chip.dart';
import '../../achievements/presentation/all_achievements_screen.dart';
import '../../achievements/providers.dart';
import '../../auth/providers.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/providers.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../domain/project_gallery.dart';
import '../providers.dart';
import 'stats_screen.dart';
import 'stats_visibility_screen.dart';

/// Read-only view of another artist's profile — reached by tapping a
/// username/avatar in the feed or the Followed list. Avatar upload and
/// deeper customisation (analytics, custom project layout) are future work.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final isOwnProfile = userId == myUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Profile not found.', style: appBodyStyle(fontSize: 16, color: kInkColor)),
              );
            }
            final postsAsync = ref.watch(userPostsProvider(userId));
            final posts = postsAsync.value ?? const <FeedPost>[];
            final postsCount = postsAsync.value?.length;
            final followersCount = ref.watch(followCountsProvider(userId)).value?.followers;
            final followingCount = ref.watch(followCountsProvider(userId)).value?.following;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: kHairlineColor, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const AppIcon(AppIcons.back, size: 18, color: kInkColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '@${profile.username}',
                          style: appBodyStyle(fontSize: 20, color: kInkColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwnProfile) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StatsVisibilityScreen(profile: profile)),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: kHairlineColor, width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const AppIcon(AppIcons.pencil, size: 18, color: kInkColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: appHardCardDecoration(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kHairlineColor,
                                border: Border.all(color: kHairlineColor, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: const AppIcon(AppIcons.profile, size: 34, color: kMutedColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: appBodyStyle(fontSize: 22, color: kInkColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${profile.username}',
                                    style: GoogleFonts.rubikMonoOne(fontSize: 15, color: kAccentColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (profile.bio != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            profile.bio!,
                            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
                          ),
                        ],
                        if (!isOwnProfile) ...[
                          const SizedBox(height: 8),
                          _MutualFollowersLine(userId: userId),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppStatColumn(
                                value: postsCount == null ? '—' : formatCount(postsCount),
                                label: 'Posts',
                              ),
                            ),
                            Container(width: 1, height: 32, color: kHairlineColor),
                            Expanded(
                              child: AppStatColumn(
                                value: followersCount == null ? '—' : formatCount(followersCount),
                                label: 'Followers',
                              ),
                            ),
                            Container(width: 1, height: 32, color: kHairlineColor),
                            Expanded(
                              child: AppStatColumn(
                                value: followingCount == null ? '—' : formatCount(followingCount),
                                label: 'Following',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StatsScreen(userId: userId)),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: kHairlineColor, width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppIcon(AppIcons.barChart, size: 18, color: kInkColor),
                                const SizedBox(width: 6),
                                Text(
                                  'View stats',
                                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInkColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isOwnProfile) ...[
                          const SizedBox(height: 10),
                          _FollowButton(userId: userId),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProjectsRow(userId: userId, artist: profile.username),
                  const SizedBox(height: 20),
                  _AchievementsRow(userId: userId),
                  if (profile.pinnedPostId != null) ...[
                    const SizedBox(height: 20),
                    _PinnedPostCard(pinnedPostId: profile.pinnedPostId!, posts: posts),
                  ],
                  const SizedBox(height: 20),
                  _PostsSection(
                    postsAsync: postsAsync,
                    posts: posts,
                    userId: userId,
                    isOwnProfile: isOwnProfile,
                    pinnedPostId: profile.pinnedPostId,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(profileByIdProvider(userId)),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isSubmitting = false;
  bool? _override;

  Future<void> _toggleFollow(bool isFollowing) async {
    setState(() => _isSubmitting = true);
    final repo = ref.read(followsRepositoryProvider);
    try {
      if (isFollowing) {
        await repo.unfollow(widget.userId);
      } else {
        await repo.follow(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _override = !isFollowing;
        _isSubmitting = false;
      });
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(followingListProvider);
      ref.invalidate(suggestedArtistsProvider);
      ref.invalidate(followCountsProvider(widget.userId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = _override ?? ref.watch(isFollowingProvider(widget.userId)).value ?? false;

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: _isSubmitting ? null : () => _toggleFollow(isFollowing),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? kAccentTintColor : kAccentColor,
            border: Border.all(color: kHairlineColor, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isFollowing ? 'Unfollow' : 'Follow',
            style: appBodyStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isFollowing ? kInkColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Instagram-style "Story" circles, one per project that has at least one
/// photographed session — tapping one opens that project's photo grid.
class _ProjectsRow extends ConsumerWidget {
  const _ProjectsRow({required this.userId, required this.artist});

  final String userId;
  final String artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleriesAsync = ref.watch(userProjectGalleriesProvider(userId));
    final galleries = galleriesAsync.value ?? const [];
    if (galleries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Projects', style: appBodyStyle(fontSize: 18, color: kInkColor)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: galleries.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final gallery = galleries[index];
              return _ProjectCircle(
                gallery: gallery,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(
                      project: gallery.project,
                      artistUsername: artist,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectCircle extends StatelessWidget {
  const _ProjectCircle({required this.gallery, required this.onTap});

  final ProjectGallery gallery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoUrl = gallery.previewPhotoUrl;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: kAccentColor, width: 2.5)),
              ),
              child: ClipOval(
                child: photoUrl == null || photoUrl.isEmpty
                    ? Container(
                        color: kHairlineColor,
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.image, size: 18, color: kMutedColor),
                      )
                    : CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: kSurfaceColor),
                        errorWidget: (context, url, error) => Container(
                          color: kHairlineColor,
                          alignment: Alignment.center,
                          child: const AppIcon(AppIcons.image, size: 18, color: kMutedColor),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              gallery.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kInkColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievements section for any profile — locked/unlocked state is real for
/// whichever [userId] is passed in, so a visitor sees the same earned badges
/// the owner does on their own profile, plus a link to the full catalog.
class _AchievementsRow extends ConsumerWidget {
  const _AchievementsRow({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAchievements = ref.watch(unlockedAchievementsProvider(userId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Achievements', style: appBodyStyle(fontSize: 18, color: kInkColor)),
            const SizedBox(width: 8),
            Text(
              '${unlockedAchievements?.length ?? 0}/${achievementCatalog.length}',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
            ),
            const Spacer(),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AllAchievementsScreen(userId: userId)),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'View all',
                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (unlockedAchievements == null || unlockedAchievements.isEmpty)
          Text(
            'No achievements yet.',
            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final achievement in achievementCatalog)
                if (unlockedAchievements.containsKey(achievement.key)) AchievementChip(achievement: achievement),
            ],
          ),
      ],
    );
  }
}

/// "Followed by X, Y and N others" — people the viewer follows who also
/// follow this profile. Silent (renders nothing) when there are none.
class _MutualFollowersLine extends ConsumerWidget {
  const _MutualFollowersLine({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutuals = ref.watch(mutualFollowersProvider(userId)).value;
    if (mutuals == null || mutuals.profiles.isEmpty) return const SizedBox.shrink();

    final names = [for (final profile in mutuals.profiles) profile['username']?.toString() ?? ''];
    final remaining = mutuals.totalCount - names.length;

    final label = switch (names.length) {
      1 when remaining <= 0 => 'Followed by @${names[0]}',
      1 => 'Followed by @${names[0]} and $remaining other${remaining == 1 ? '' : 's'}',
      _ when remaining <= 0 =>
        'Followed by ${names.sublist(0, names.length - 1).map((n) => '@$n').join(', ')} and @${names.last}',
      _ =>
        'Followed by ${names.map((n) => '@$n').join(', ')} and $remaining other${remaining == 1 ? '' : 's'}',
    };

    return Text(
      label,
      style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMutedColor),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Featured card for the post the owner has pinned to the top of their
/// profile — renders nothing if [pinnedPostId] isn't (yet) among [posts].
class _PinnedPostCard extends StatelessWidget {
  const _PinnedPostCard({required this.pinnedPostId, required this.posts});

  final String pinnedPostId;
  final List<FeedPost> posts;

  @override
  Widget build(BuildContext context) {
    FeedPost? pinnedPost;
    for (final post in posts) {
      if (post.id == pinnedPostId) {
        pinnedPost = post;
        break;
      }
    }
    if (pinnedPost == null) return const SizedBox.shrink();
    final photoUrl = pinnedPost.photoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppIcon(AppIcons.pin, size: 15, color: kAccentColor),
            const SizedBox(width: 6),
            Text('Pinned', style: appBodyStyle(fontSize: 18, color: kInkColor)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: pinnedPost!)),
          ),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Container(
                      color: kHairlineColor,
                      alignment: Alignment.center,
                      child: const AppIcon(AppIcons.image, size: 30, color: kMutedColor),
                    )
                  : CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: kSurfaceColor),
                      errorWidget: (context, url, error) => Container(
                        color: kHairlineColor,
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.image, size: 30, color: kMutedColor),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PostSort {
  newest('Newest'),
  oldest('Oldest'),
  mostViewed('Most viewed');

  const _PostSort(this.label);
  final String label;
}

/// The post grid, with a sort control (newest/oldest/most viewed), an
/// optional per-project filter, tap-to-view, and — for the profile owner —
/// long-press to pin/unpin a post to the top of the profile.
class _PostsSection extends ConsumerStatefulWidget {
  const _PostsSection({
    required this.postsAsync,
    required this.posts,
    required this.userId,
    required this.isOwnProfile,
    required this.pinnedPostId,
  });

  final AsyncValue<List<FeedPost>> postsAsync;
  final List<FeedPost> posts;
  final String userId;
  final bool isOwnProfile;
  final String? pinnedPostId;

  @override
  ConsumerState<_PostsSection> createState() => _PostsSectionState();
}

class _PostsSectionState extends ConsumerState<_PostsSection> {
  _PostSort _sort = _PostSort.newest;
  String? _projectFilter;

  List<FeedPost> get _visiblePosts {
    final filtered = _projectFilter == null
        ? List<FeedPost>.of(widget.posts)
        : widget.posts.where((post) => post.projectTitle == _projectFilter).toList();
    switch (_sort) {
      case _PostSort.newest:
        filtered.sort((a, b) => b.datePosted.compareTo(a.datePosted));
      case _PostSort.oldest:
        filtered.sort((a, b) => a.datePosted.compareTo(b.datePosted));
      case _PostSort.mostViewed:
        filtered.sort((a, b) => b.views.compareTo(a.views));
    }
    return filtered;
  }

  Future<void> _togglePin(FeedPost post) async {
    final isPinned = widget.pinnedPostId == post.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isPinned ? 'Unpin this post?' : 'Pin this post?',
          style: appBodyStyle(fontSize: 18, color: kInkColor),
        ),
        content: Text(
          isPinned
              ? "It'll no longer be featured at the top of your profile."
              : "It'll be featured at the top of your profile, above the grid.",
          style: appBodyStyle(fontSize: 13, color: kMutedColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isPinned ? 'Unpin' : 'Pin'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(profileRepositoryProvider).updatePinnedPost(
            userId: widget.userId,
            postId: isPinned ? null : post.id,
          );
      ref.invalidate(profileByIdProvider(widget.userId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update pin: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectTitles = {for (final post in widget.posts) post.projectTitle}.toList()..sort();
    final visiblePosts = _visiblePosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Posts', style: appBodyStyle(fontSize: 18, color: kInkColor)),
            const Spacer(),
            if (projectTitles.length > 1)
              _ThemedMenuButton<String?>(
                icon: AppIcons.filter,
                label: 'Filter',
                value: _projectFilter,
                items: [
                  (value: null, label: 'All projects'),
                  for (final title in projectTitles) (value: title, label: title),
                ],
                onSelected: (value) => setState(() => _projectFilter = value),
              ),
            const SizedBox(width: 10),
            _ThemedMenuButton<_PostSort>(
              icon: AppIcons.sort,
              label: 'Sort',
              value: _sort,
              items: [for (final sort in _PostSort.values) (value: sort, label: sort.label)],
              onSelected: (value) => setState(() => _sort = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.postsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.postsAsync.hasError)
          AppErrorState(
            error: widget.postsAsync.error!,
            onRetry: () => ref.invalidate(userPostsProvider(widget.userId)),
          )
        else if (visiblePosts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: appHardCardDecoration(radius: 18),
            child: Text(
              widget.posts.isEmpty ? 'No posts yet.' : 'No posts match this filter.',
              textAlign: TextAlign.center,
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visiblePosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final post = visiblePosts[index];
              final photoUrl = post.photoUrl;
              final isPinned = widget.pinnedPostId == post.id;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                ),
                onLongPress: widget.isOwnProfile ? () => _togglePin(post) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photoUrl == null || photoUrl.isEmpty
                          ? Container(
                              color: kHairlineColor,
                              alignment: Alignment.center,
                              child: const AppIcon(AppIcons.image, size: 20, color: kMutedColor),
                            )
                          : CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: kSurfaceColor),
                              errorWidget: (context, url, error) => Container(
                                color: kHairlineColor,
                                alignment: Alignment.center,
                                child: const AppIcon(AppIcons.image, size: 20, color: kMutedColor),
                              ),
                            ),
                      if (isPinned)
                        const Positioned(
                          top: 4,
                          left: 4,
                          child: AppIcon(AppIcons.pin, size: 14, color: Colors.white),
                        ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.eye, size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              formatCount(post.views),
                              style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)
                                  .copyWith(shadows: const [Shadow(color: kMutedColor, blurRadius: 4)]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A sort/filter trigger + dropdown menu styled like the rest of the app —
/// hairline border, rounded pill trigger, Inter-labelled options with a
/// checkmark on the current selection — instead of the default Material
/// popup menu look.
class _ThemedMenuButton<T> extends StatelessWidget {
  const _ThemedMenuButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final String icon;
  final String label;
  final T value;
  final List<({T value, String label})> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kHairlineColor, width: 1),
      ),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: appBodyStyle(
                      fontSize: 15,
                      color: item.value == value ? kAccentColor : kInkColor,
                    ),
                  ),
                ),
                if (item.value == value) const AppIcon(AppIcons.check, size: 16, color: kAccentColor),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: kHairlineColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 15, color: kInkColor),
            const SizedBox(width: 4),
            Text(label, style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInkColor)),
          ],
        ),
      ),
    );
  }
}
