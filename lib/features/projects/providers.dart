import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/projects_repository.dart';
import 'data/sessions_repository.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(supabaseClientProvider));
});

/// Most recently opened first (via `last_opened_at`), then never-opened
/// projects in [ProjectsRepository.fetchProjects]'s newest-created-first
/// order — `last_opened_at` lives on the row itself, so this is consistent
/// across every device/session rather than a device-local guess.
final projectsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final projects = await ref.watch(projectsRepositoryProvider).fetchProjects();

  final sorted = [...projects];
  sorted.sort((a, b) {
    final aTime = _lastOpenedAt(a);
    final bTime = _lastOpenedAt(b);
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  });
  return sorted;
});

DateTime? _lastOpenedAt(Map<String, dynamic> project) {
  final raw = project['last_opened_at'];
  return raw == null ? null : DateTime.tryParse(raw.toString());
}

final lastOpenedProjectProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  if (projects.isEmpty) return null;

  final first = projects.first;
  return _lastOpenedAt(first) != null ? first : null;
});

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepository(ref.watch(supabaseClientProvider));
});

final sessionsListProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  return ref.watch(sessionsRepositoryProvider).fetchSessions(projectId);
});
