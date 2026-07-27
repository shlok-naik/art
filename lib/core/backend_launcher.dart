import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

String resolveBackendUrl() {
  final url = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  // The Android emulator can't reach the host machine via localhost; it
  // needs the special 10.0.2.2 alias instead.
  if (!kIsWeb && Platform.isAndroid) {
    return url
        .replaceFirst('localhost', '10.0.2.2')
        .replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return url;
}

/// Starts the local FastAPI backend automatically if it isn't already
/// running, so developers don't have to remember a separate step before
/// `flutter run`. Only applicable when the app itself runs on the same
/// machine as the backend (desktop) and the backend is local (localhost).
Future<void> ensureBackendRunning(String backendUrl) async {
  if (kIsWeb) return;
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
  if (!backendUrl.contains('localhost') && !backendUrl.contains('127.0.0.1')) {
    return;
  }

  final healthUri = Uri.parse(backendUrl).replace(path: '/health');
  if (await _isHealthy(healthUri)) return;

  final backendDir = Directory(
    '${Directory.current.path}${Platform.pathSeparator}backend',
  );
  if (!backendDir.existsSync()) return;

  try {
    await Process.start(
      _pythonExecutable(),
      ['main.py'],
      workingDirectory: backendDir.path,
      mode: ProcessStartMode.detached,
    );
  } catch (_) {
    return;
  }

  for (var i = 0; i < 20; i++) {
    await Future.delayed(const Duration(milliseconds: 300));
    if (await _isHealthy(healthUri)) return;
  }
}

String _pythonExecutable() {
  final venvPython = Platform.isWindows
      ? '${Directory.current.path}${Platform.pathSeparator}.venv${Platform.pathSeparator}Scripts${Platform.pathSeparator}python.exe'
      : '${Directory.current.path}${Platform.pathSeparator}.venv${Platform.pathSeparator}bin${Platform.pathSeparator}python3';
  if (File(venvPython).existsSync()) return venvPython;
  return Platform.isWindows ? 'python' : 'python3';
}

Future<bool> _isHealthy(Uri url) async {
  try {
    final response = await http.get(url).timeout(const Duration(milliseconds: 500));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
