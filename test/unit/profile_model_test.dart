import 'package:art/features/profile/data/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile.fromMap', () {
    test('maps a Supabase profile row to a Profile', () {
      final profile = Profile.fromMap({
        'id': 'user-123',
        'username': 'paintedSky',
        'display_name': 'Painted Sky',
      });

      expect(profile.id, 'user-123');
      expect(profile.username, 'paintedSky');
      expect(profile.displayName, 'Painted Sky');
    });

    test('throws when a required field is missing', () {
      expect(
        () => Profile.fromMap({
          'id': 'user-123',
          'username': 'paintedSky',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
