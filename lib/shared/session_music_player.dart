import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_icons.dart';
import 'app_spacing.dart';
import 'app_styles.dart';
import 'session_music_providers.dart';
import 'session_music_service.dart';

/// A Google-Maps-style "now playing" control for the session timer.
///
/// On Android, once the user grants the one-time "Notification access"
/// permission, this mirrors and controls whatever music app they already
/// have playing (Spotify, YouTube Music, anything) — the same mechanism the
/// lock screen uses, so it works on any subscription tier.
///
/// On iOS there's no public API for a third-party app to read or control
/// another app's playback, so this instead offers quick-launch buttons out
/// to each app; iOS's own Control Center picks up Now Playing from there.
class SessionMusicPlayer extends ConsumerStatefulWidget {
  const SessionMusicPlayer({super.key});

  @override
  ConsumerState<SessionMusicPlayer> createState() => _SessionMusicPlayerState();
}

class _SessionMusicPlayerState extends ConsumerState<SessionMusicPlayer> with WidgetsBindingObserver {
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    if (SessionMusicService.supportsLiveControl) {
      WidgetsBinding.instance.addObserver(this);
      _checkPermission();
    }
  }

  @override
  void dispose() {
    if (SessionMusicService.supportsLiveControl) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catches the user coming back from the system settings screen after
    // granting (or skipping) notification access.
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await ref.read(sessionMusicServiceProvider).isNotificationAccessGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionMusicService.supportsLiveControl) {
      return _buildQuickLaunchCard(
        title: 'Listen while you work',
        subtitle: 'Open a music app, then come back — playback stays in your control from there.',
      );
    }

    if (_permissionGranted == null) return const SizedBox.shrink();
    if (!_permissionGranted!) return _buildPermissionCard();

    final mediaStateAsync = ref.watch(sessionMediaStateProvider);
    return mediaStateAsync.when(
      data: (state) => state.connected ? _buildPlayerCard(state) : _buildQuickLaunchCard(
        title: 'Nothing playing yet',
        subtitle: 'Open a music app and start something — controls will show up here.',
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _buildQuickLaunchCard(
        title: 'Nothing playing yet',
        subtitle: 'Open a music app and start something — controls will show up here.',
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: appFlatCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.musicNote, size: 20, color: kAccentColor),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  'Control your music without leaving the session',
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Play, pause, and skip whatever\'s already playing — Spotify, YouTube Music, anything. '
            'Requires a one-time "Notification access" permission.',
            style: appBodyStyle(fontSize: 12, color: kMutedColor),
          ),
          const SizedBox(height: AppSpacing.space12),
          TextButton(
            onPressed: () => ref.read(sessionMusicServiceProvider).openNotificationAccessSettings(),
            style: TextButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space8),
              textStyle: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            child: const Text('Enable in Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLaunchCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: appFlatCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.musicNote, size: 20, color: kAccentColor),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(title, style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: appBodyStyle(fontSize: 12, color: kMutedColor)),
          const SizedBox(height: AppSpacing.space12),
          Wrap(
            spacing: AppSpacing.space8,
            runSpacing: AppSpacing.space8,
            children: [
              for (final app in QuickLaunchApp.values) _QuickLaunchChip(app: app),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(SessionMediaState state) {
    final service = ref.read(sessionMusicServiceProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: appFlatCardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: state.art != null
                  ? Image.memory(state.art!, fit: BoxFit.cover)
                  : Container(
                      color: kHairlineColor,
                      child: AppIcon(AppIcons.musicNote, size: 18, color: kMutedColor),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.title ?? 'Unknown track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  state.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appBodyStyle(fontSize: 12, color: kMutedColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: service.skipPrevious,
            icon: AppIcon(AppIcons.skipPrevious, size: 20, color: kInkColor),
          ),
          IconButton(
            onPressed: () => state.isPlaying ? service.pause() : service.play(),
            icon: AppIcon(
              state.isPlaying ? AppIcons.pause : AppIcons.play,
              size: 20,
              color: kInkColor,
            ),
          ),
          IconButton(
            onPressed: service.skipNext,
            icon: AppIcon(AppIcons.skipNext, size: 20, color: kInkColor),
          ),
        ],
      ),
    );
  }
}

class _QuickLaunchChip extends ConsumerWidget {
  const _QuickLaunchChip({required this.app});

  final QuickLaunchApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(sessionMusicServiceProvider).openApp(app),
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: kSurfaceColor,
        foregroundColor: kInkColor,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space8),
        textStyle: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      child: Text(app.label),
    );
  }
}
