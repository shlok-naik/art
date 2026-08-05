import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ModerationResult {
  const ModerationResult({required this.flagged, required this.censored});

  final bool flagged;
  final String censored;
}

/// Checks comment text against the backend's local profanity censor. Not a
/// security boundary — anything calling Supabase directly could bypass it —
/// it only nudges the poster before submission; real enforcement is the
/// report flow plus owner/self delete on the comments table.
///
/// Returns the original text unflagged if the backend can't be reached, so
/// a moderation outage never blocks posting.
Future<ModerationResult> moderateText(String text) async {
  final baseUrl = dotenv.env['API_BASE_URL'];
  if (baseUrl == null || baseUrl.isEmpty) {
    return ModerationResult(flagged: false, censored: text);
  }

  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/moderate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      return ModerationResult(flagged: false, censored: text);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ModerationResult(
      flagged: body['flagged'] == true,
      censored: body['censored']?.toString() ?? text,
    );
  } catch (_) {
    return ModerationResult(flagged: false, censored: text);
  }
}
