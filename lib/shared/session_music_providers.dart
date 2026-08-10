import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_music_service.dart';

final sessionMusicServiceProvider = Provider<SessionMusicService>((ref) => SessionMusicService());

/// Live system media-session updates (Android only — see
/// [SessionMusicService.supportsLiveControl]).
final sessionMediaStateProvider = StreamProvider.autoDispose<SessionMediaState>((ref) {
  return ref.watch(sessionMusicServiceProvider).mediaStateStream;
});
