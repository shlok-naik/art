import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../feed/providers.dart';
import '../providers.dart';
import 'stats_screen.dart';

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

/// Read-only view of another artist's profile — reached by tapping a
/// username/avatar in the feed or the Followed list. Bio is a hardcoded
/// placeholder for now: profile customisation (bio, avatar upload,
/// analytics, projects) is future work, not yet backed by real columns.
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
                child: Text('Profile not found.', style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
              );
            }
            final postsAsync = ref.watch(userPostsProvider(userId));
            final posts = postsAsync.value ?? const [];
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
                            border: Border.all(color: kBorderColor, width: kBorderWidth),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '@${profile.username}',
                          style: GoogleFonts.chewy(fontSize: 20, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                                color: Colors.grey.shade200,
                                border: Border.all(color: kBorderColor, width: kBorderWidth),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, size: 36, color: Colors.black26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: GoogleFonts.chewy(fontSize: 22, color: Colors.black),
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                value: _formatCount(posts.length),
                                label: 'Posts',
                              ),
                            ),
                            Container(width: 2, height: 32, color: const Color(0xFFEEEEEE)),
                            Expanded(
                              child: _StatColumn(
                                value: followersCount == null ? '—' : _formatCount(followersCount),
                                label: 'Followers',
                              ),
                            ),
                            Container(width: 2, height: 32, color: const Color(0xFFEEEEEE)),
                            Expanded(
                              child: _StatColumn(
                                value: followingCount == null ? '—' : _formatCount(followingCount),
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
                              border: Border.all(color: kBorderColor, width: kBorderWidth),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bar_chart, size: 18, color: Colors.black),
                                const SizedBox(width: 6),
                                Text(
                                  'View stats',
                                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
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
                  Text('Posts', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                  const SizedBox(height: 8),
                  if (postsAsync.hasError)
                    AppErrorText('Failed to load posts: ${postsAsync.error}')
                  else if (posts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: appHardCardDecoration(radius: 18),
                      child: Text(
                        'No posts yet.',
                        textAlign: TextAlign.center,
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemBuilder: (context, index) {
                        final photoUrl = posts[index].photoUrl;
                        return ClipRRect(
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
                        );
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppErrorText('Error: $error'),
            ),
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
            border: Border.all(color: kBorderColor, width: kBorderWidth),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isFollowing ? 'Unfollow' : 'Follow',
            style: appBodyStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isFollowing ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 2),
        Text(label, style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
      ],
    );
  }
}
