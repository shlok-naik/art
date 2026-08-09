import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../profile/providers.dart';

class FollowedScreen extends ConsumerWidget {
  const FollowedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingListProvider);
    final suggestedAsync = ref.watch(suggestedArtistsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Followed', style: appBodyStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              followingAsync.when(
                data: (following) => following.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: appFlatCardDecoration(radius: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.followed, size: 40, color: kMutedColor, strokeWidth: 1.4),
                            const SizedBox(height: 10),
                            Text('Nobody here yet', style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Follow other artists to see their posts here.',
                              textAlign: TextAlign.center,
                              style: appBodyStyle(fontSize: 13, color: kMutedColor),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (final profile in following)
                            _ArtistTile(
                              key: ValueKey('following-${profile['id']}'),
                              userId: profile['id'].toString(),
                              handle: profile['username']?.toString() ?? '',
                              subtitle: profile['display_name']?.toString() ?? '',
                              isFollowing: true,
                            ),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => AppErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(followingListProvider),
                ),
              ),
              const SizedBox(height: 22),
              Text('Suggested artists', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              suggestedAsync.when(
                data: (suggested) => suggested.isEmpty
                    ? Text(
                        'No suggestions right now.',
                        style: appBodyStyle(fontSize: 13, color: kMutedColor),
                      )
                    : Column(
                        children: [
                          for (final profile in suggested)
                            _ArtistTile(
                              key: ValueKey('suggested-${profile['id']}'),
                              userId: profile['id'].toString(),
                              handle: profile['username']?.toString() ?? '',
                              subtitle: profile['display_name']?.toString() ?? '',
                              isFollowing: false,
                            ),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => AppErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(suggestedArtistsProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistTile extends ConsumerStatefulWidget {
  const _ArtistTile({
    super.key,
    required this.userId,
    required this.handle,
    required this.subtitle,
    required this.isFollowing,
  });

  final String userId;
  final String handle;
  final String subtitle;
  final bool isFollowing;

  @override
  ConsumerState<_ArtistTile> createState() => _ArtistTileState();
}

class _ArtistTileState extends ConsumerState<_ArtistTile> {
  late bool _isFollowing = widget.isFollowing;
  bool _isSubmitting = false;

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: widget.userId)),
    );
  }

  Future<void> _confirmToggleFollow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          _isFollowing ? 'Unfollow @${widget.handle}?' : 'Follow @${widget.handle}?',
          style: appBodyStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to ${_isFollowing ? 'unfollow' : 'follow'} @${widget.handle}?',
          style: appBodyStyle(fontSize: 13, color: kMutedColor),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: appBodyStyle(fontWeight: FontWeight.w600, color: kMutedColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _isFollowing ? 'Unfollow' : 'Follow',
              style: appBodyStyle(fontWeight: FontWeight.w600, color: kAccentColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _toggleFollow();
  }

  Future<void> _toggleFollow() async {
    setState(() => _isSubmitting = true);
    final repo = ref.read(followsRepositoryProvider);
    try {
      if (_isFollowing) {
        await repo.unfollow(widget.userId);
      } else {
        await repo.follow(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        _isSubmitting = false;
      });
      ref.invalidate(followingListProvider);
      ref.invalidate(suggestedArtistsProvider);
      ref.invalidate(followCountsProvider(widget.userId));
      ref.invalidate(isFollowingProvider(widget.userId));
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
    // The whole row navigates to the profile — the Follow/Unfollow button
    // is a nested InkWell, so Flutter's gesture arena routes taps on it to
    // the button alone rather than also bubbling up to this outer tap.
    return InkWell(
      onTap: _openProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kHairlineColor, width: 1)),
        ),
        child: Row(
          children: [
            AppInitialsAvatar(
              name: widget.subtitle.isNotEmpty ? widget.subtitle : widget.handle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@${widget.handle}',
                    style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle.isNotEmpty)
                    Text(widget.subtitle, style: appBodyStyle(fontSize: 12, color: kMutedColor)),
                ],
              ),
            ),
            InkWell(
              onTap: _isSubmitting ? null : _confirmToggleFollow,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: _isFollowing
                    ? BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      )
                    : BoxDecoration(
                        border: Border.all(color: kHairlineColor, width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                child: Text(
                  _isFollowing ? 'Unfollow' : 'Follow',
                  style: _isFollowing
                      ? appBodyStyle(fontSize: 12, fontWeight: FontWeight.w500)
                      : appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAccentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
