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

final projectsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(projectsRepositoryProvider).fetchProjects();
});

final recentProjectStoreProvider = Provider<RecentProjectStore>((ref) => RecentProjectStore());

final lastOpenedProjectProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final lastId = await ref.watch(recentProjectStoreProvider).getLastOpenedProjectId();
  if (lastId == null) return null;

  final projects = await ref.watch(projectsListProvider.future);
  for (final project in projects) {
    if (project['id'].toString() == lastId) return project;
  }
  return null;
});

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  return SessionsRepository(ref.watch(supabaseClientProvider), backendUrl);
});

final sessionsListProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  return ref.watch(sessionsRepositoryProvider).fetchSessions(projectId);
});
