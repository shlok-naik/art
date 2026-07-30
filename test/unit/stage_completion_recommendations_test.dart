import 'package:art/features/projects/presentation/session_details_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each session stage has a completion recommendation', () {
    for (final stage in kSessionStages) {
      expect(kStageCompletionRecommendations[stage], isNotNull);
    }
  });

  test('recommendations progress from sketching through finished', () {
    expect(
      kStageCompletionRecommendations['Sketching'],
      lessThan(kStageCompletionRecommendations['Finishing Touches']!),
    );
    expect(
      kStageCompletionRecommendations['Finishing Touches'],
      lessThan(kStageCompletionRecommendations['Finished']!),
    );
    expect(kStageCompletionRecommendations['Finished'], 100);
  });
}
