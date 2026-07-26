import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/projects_repository.dart';
import 'data/recent_project_store.dart';
import 'data/sessions_repository.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  return ProjectsRepository(ref.watch(supabaseClientProvider), backendUrl);
});

final recentProjectStoreProvider = Provider<RecentProjectStore>((ref) => RecentProjectStore());

final projectsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final projects = await ref.watch(projectsRepositoryProvider).fetchProjects();
  final openedAt = await ref.watch(recentProjectStoreProvider).getOpenedAt();

  final sorted = [...projects];
  sorted.sort((a, b) {
    final aTime = openedAt[a['id'].toString()];
    final bTime = openedAt[b['id'].toString()];
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  });
  return sorted;
});

final lastOpenedProjectProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final openedAt = await ref.watch(recentProjectStoreProvider).getOpenedAt();
  if (openedAt.isEmpty) return null;

  final projects = await ref.watch(projectsListProvider.future);
  if (projects.isEmpty) return null;

  final first = projects.first;
  return openedAt.containsKey(first['id'].toString()) ? first : null;
});

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  return SessionsRepository(ref.watch(supabaseClientProvider), backendUrl);
});

final sessionsListProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  return ref.watch(sessionsRepositoryProvider).fetchSessions(projectId);
});
