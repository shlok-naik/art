import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Followed', style: GoogleFonts.chewy(fontSize: 24, color: kInkColor)),
              const SizedBox(height: 20),
              followingAsync.when(
                data: (following) => following.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: appHardCardDecoration(radius: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/branding/mascot.png', height: 80),
                            const SizedBox(height: 10),
                            Text('Nobody here yet', style: GoogleFonts.chewy(fontSize: 18, color: kInkColor)),
                            const SizedBox(height: 4),
                            Text(
                              'Follow other artists to see their posts here.',
                              textAlign: TextAlign.center,
                              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (final profile in following) ...[
                            _ArtistTile(
                              key: ValueKey('following-${profile['id']}'),
                              userId: profile['id'].toString(),
                              handle: profile['username']?.toString() ?? '',
                              subtitle: profile['display_name']?.toString() ?? '',
                              avatarUrl: profile['avatar_url']?.toString(),
                              isFollowing: true,
                            ),
                            const SizedBox(height: 10),
                          ],
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
              const SizedBox(height: 20),
              Text('Suggested artists', style: GoogleFonts.chewy(fontSize: 16, color: kInkColor)),
              const SizedBox(height: 10),
              suggestedAsync.when(
                data: (suggested) => suggested.isEmpty
                    ? Text(
                        'No suggestions right now.',
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF888888)),
                      )
                    : Column(
                        children: [
                          for (final profile in suggested) ...[
                            _ArtistTile(
                              key: ValueKey('suggested-${profile['id']}'),
                              userId: profile['id'].toString(),
                              handle: profile['username']?.toString() ?? '',
                              subtitle: profile['display_name']?.toString() ?? '',
                              avatarUrl: profile['avatar_url']?.toString(),
                              isFollowing: false,
                            ),
                            const SizedBox(height: 10),
                          ],
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
    this.avatarUrl,
  });

  final String userId;
  final String handle;
  final String subtitle;
  final bool isFollowing;
  final String? avatarUrl;

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
        title: Text(
          _isFollowing ? 'Unfollow @${widget.handle}?' : 'Follow @${widget.handle}?',
          style: GoogleFonts.chewy(fontSize: 18, color: kInkColor),
        ),
        content: Text(
          'Are you sure you want to ${_isFollowing ? 'unfollow' : 'follow'} @${widget.handle}?',
          style: appBodyStyle(fontSize: 13, color: kMutedColor),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: kBorderColor, width: kBorderWidth),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: appBodyStyle(fontWeight: FontWeight.w700, color: const Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _isFollowing ? 'Unfollow' : 'Follow',
              style: appBodyStyle(fontWeight: FontWeight.w800, color: kAccentColor),
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
    // The whole card navigates to the profile — the Follow/Unfollow button
    // is a nested InkWell, so Flutter's gesture arena routes taps on it to
    // the button alone rather than also bubbling up to this outer tap.
    return InkWell(
      onTap: _openProfile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: appHardCardDecoration(radius: 16, shadowOffset: 2),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kBorderColor, width: kBorderWidth),
              ),
              child: AppInitialsAvatar(
                name: widget.subtitle.isNotEmpty ? widget.subtitle : widget.handle,
                size: 44,
                imageUrl: widget.avatarUrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('@${widget.handle}', style: GoogleFonts.chewy(fontSize: 15, color: kInkColor), overflow: TextOverflow.ellipsis),
                  if (widget.subtitle.isNotEmpty)
                    Text(widget.subtitle, style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
                ],
              ),
            ),
            InkWell(
              onTap: _isSubmitting ? null : _confirmToggleFollow,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFollowing ? kAccentTintColor : null,
                  border: Border.all(color: kBorderColor, width: kBorderWidth),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isFollowing ? 'Unfollow' : 'Follow',
                  style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kInkColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
