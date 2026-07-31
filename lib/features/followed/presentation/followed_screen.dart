import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../profile/providers.dart';

class FollowedScreen extends ConsumerWidget {
  const FollowedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingListProvider);
    final suggestedAsync = ref.watch(suggestedArtistsProvider);
    final following = followingAsync.value ?? const [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Followed', style: GoogleFonts.chewy(fontSize: 24, color: Colors.black)),
              const SizedBox(height: 20),
              if (followingAsync.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (following.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: appHardCardDecoration(radius: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/branding/mascot.png', height: 80),
                      const SizedBox(height: 10),
                      Text('Nobody here yet', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text(
                        'Follow other artists to see their posts here.',
                        textAlign: TextAlign.center,
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                      ),
                    ],
                  ),
                )
              else
                for (final profile in following) ...[
                  _ArtistTile(
                    userId: profile['id'].toString(),
                    handle: profile['username']?.toString() ?? '',
                    subtitle: profile['display_name']?.toString() ?? '',
                    isFollowing: true,
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 20),
              Text('Suggested artists', style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
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
                              userId: profile['id'].toString(),
                              handle: profile['username']?.toString() ?? '',
                              subtitle: profile['display_name']?.toString() ?? '',
                              isFollowing: false,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorText('Failed to load suggestions: $error'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: kBorderColor, width: kBorderWidth),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 22, color: Colors.black26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('@${widget.handle}', style: GoogleFonts.chewy(fontSize: 15, color: Colors.black), overflow: TextOverflow.ellipsis),
                if (widget.subtitle.isNotEmpty)
                  Text(widget.subtitle, style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
              ],
            ),
          ),
          InkWell(
            onTap: _isSubmitting ? null : _toggleFollow,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _isFollowing ? kAccentTintColor : null,
                border: Border.all(color: kBorderColor, width: kBorderWidth),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isFollowing ? 'Following' : 'Follow',
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
