import 'package:art/features/home/presentation/home_screen.dart';
import 'package:art/features/profile/data/profile_model.dart';
import 'package:art/features/profile/providers.dart';
import 'package:art/features/projects/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith(
            (ref) async => const Profile(id: 'u1', username: 'testuser', displayName: 'Test User'),
          ),
          lastOpenedProjectProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  final sizes = {
    'typical phone (iPhone 14)': const Size(390, 844),
    'narrow phone (iPhone SE width)': const Size(320, 568),
    'short phone (compact Android)': const Size(360, 640),
    'tall phone (Pro Max height)': const Size(390, 932),
  };

  for (final entry in sizes.entries) {
    testWidgets('HomeScreen lays out without overflow on a ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value);
      expect(tester.takeException(), isNull);
    });
  }
}
