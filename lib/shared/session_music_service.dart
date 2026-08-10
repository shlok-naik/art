import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Snapshot of whatever's currently playing system-wide, as reported by
/// Android's `MediaSessionManager` (see `MediaBridge.kt`). [connected] is
/// false until the OS reports an active media session — i.e. the user has
/// opened a music app and started playing something.
@immutable
class SessionMediaState {
  const SessionMediaState({
    required this.connected,
    this.packageName,
    this.title,
    this.artist,
    this.isPlaying = false,
    this.art,
  });

  const SessionMediaState.disconnected() : this(connected: false);

  final bool connected;
  final String? packageName;
  final String? title;
  final String? artist;
  final bool isPlaying;
  final Uint8List? art;

  factory SessionMediaState.fromMap(Map<Object?, Object?> map) {
    return SessionMediaState(
      connected: map['connected'] as bool? ?? false,
      packageName: map['packageName'] as String?,
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      isPlaying: map['isPlaying'] as bool? ?? false,
      art: map['art'] as Uint8List?,
    );
  }
}

/// A music app the session timer can offer as a quick-launch shortcut. Deep
/// links open the app itself (never a specific track — there's no public API
/// for that outside a service's own SDK); once something's playing, Android
/// picks it up automatically via [SessionMusicService.mediaStateStream].
enum QuickLaunchApp {
  spotify('Spotify', 'spotify:'),
  appleMusic('Apple Music', 'music://'),
  youtubeMusic('YouTube Music', 'youtubemusic://');

  const QuickLaunchApp(this.label, this.uriString);

  final String label;
  final String uriString;
}

/// Centralized wrapper around the app's system media-session integration.
/// Reading/controlling whatever music app the user already has playing is
/// Android-only (see class doc on `MediaNotificationListenerService.kt` for
/// why); on iOS this only offers quick-launch buttons out to each app.
class SessionMusicService {
  static final SessionMusicService _instance = SessionMusicService._internal();
  factory SessionMusicService() => _instance;
  SessionMusicService._internal();

  static const _methodChannel = MethodChannel('art/system_media');
  static const _eventChannel = EventChannel('art/system_media/events');

  /// Live playback control (read + play/pause/skip) is only wired up on
  /// Android — see [SessionMusicService] doc comment.
  static bool get supportsLiveControl => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<SessionMediaState>? _mediaStateStream;

  Stream<SessionMediaState> get mediaStateStream {
    return _mediaStateStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => SessionMediaState.fromMap(event as Map<Object?, Object?>),
    );
  }

  Future<bool> isNotificationAccessGranted() async {
    if (!supportsLiveControl) return false;
    final granted = await _methodChannel.invokeMethod<bool>('isNotificationAccessGranted');
    return granted ?? false;
  }

  /// Opens the system "Notification access" settings screen so the user can
  /// grant this app the special permission `MediaSessionManager` requires.
  /// There's no runtime permission dialog for this — it's an Android
  /// privacy speed bump for anything that can read other apps' sessions.
  Future<void> openNotificationAccessSettings() async {
    if (!supportsLiveControl) return;
    await _methodChannel.invokeMethod('openNotificationAccessSettings');
  }

  Future<void> play() => _methodChannel.invokeMethod('play');

  Future<void> pause() => _methodChannel.invokeMethod('pause');

  Future<void> skipNext() => _methodChannel.invokeMethod('skipNext');

  Future<void> skipPrevious() => _methodChannel.invokeMethod('skipPrevious');

  Future<bool> openApp(QuickLaunchApp app) async {
    final uri = Uri.parse(app.uriString);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
