import 'package:art/features/projects/data/recent_project_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RecentProjectStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = RecentProjectStore();
  });

  group('RecentProjectStore', () {
    test('returns an empty map when no project has been opened', () async {
      expect(await store.getOpenedAt(), isEmpty);
    });

    test('reads previously stored project timestamps', () async {
      SharedPreferences.setMockInitialValues({
        'project_opened_at':
            '{"project-1":"2026-07-30T10:15:00.000","project-2":"2026-07-29T18:00:00.000"}',
      });

      final openedAt = await store.getOpenedAt();

      expect(openedAt, hasLength(2));
      expect(openedAt['project-1'], DateTime(2026, 7, 30, 10, 15));
      expect(openedAt['project-2'], DateTime(2026, 7, 29, 18));
    });

    test('records when a project is opened', () async {
      final beforeRecording = DateTime.now();

      await store.recordOpened('project-1');

      final openedAt = await store.getOpenedAt();
      expect(openedAt['project-1'], isNotNull);
      expect(openedAt['project-1']!.isBefore(beforeRecording), isFalse);
    });
  });
}
