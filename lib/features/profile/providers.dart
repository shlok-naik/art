import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/follows_repository.dart';
import 'data/profile_model.dart';
import 'data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final followsRepositoryProvider = Provider<FollowsRepository>((ref) {
  return FollowsRepository(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value?.session?.user;
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});

/// Follower/following counts for a given profile id.
final followCountsProvider =
    FutureProvider.autoDispose.family<({int followers, int following}), String>((ref, userId) {
  return ref.watch(followsRepositoryProvider).fetchFollowCounts(userId);
});

/// Whether the signed-in user follows [userId].
final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) {
  return ref.watch(followsRepositoryProvider).isFollowing(userId);
});

/// Profiles the signed-in user follows.
final followingListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(followsRepositoryProvider).fetchFollowing();
});

/// Profiles the signed-in user doesn't yet follow, for "Suggested artists".
final suggestedArtistsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(followsRepositoryProvider).fetchSuggested();
});
