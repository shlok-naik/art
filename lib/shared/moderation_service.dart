import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Checks comment text against the backend's local profanity classifier.
/// Not a security boundary — anything calling Supabase directly could
/// bypass it — it only nudges the poster before submission; real
/// enforcement is the report flow plus owner/self delete on the comments
/// table.
///
/// Returns false (allow) if the backend can't be reached, so a moderation
/// outage never blocks posting.
Future<bool> containsFlaggedContent(String text) async {
  final baseUrl = dotenv.env['API_BASE_URL'];
  if (baseUrl == null || baseUrl.isEmpty) return false;

  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/moderate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return false;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['flagged'] == true;
  } catch (_) {
    return false;
  }
}
