// Dev-only tool: fast-forwards the current league's phase boundaries so you
// can watch submissions -> voting -> closed without waiting for the real
// weekly schedule. Requires the `debug_get_or_create_current_league` and
// `debug_set_league_window` SQL functions (see
// supabase/add_debug_league_functions.sql), both granted to `anon` — this
// talks to Supabase with the app's own anon key, gated by a local
// passphrase rather than a real account login.
//
// Run with: dart run tool/simulate_league.dart [submissionMinutes] [votingMinutes] [region]
// Then press `l` to fast-forward the current league, `q` to quit (restores
// the original schedule first if a simulation is active).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _gatePassword = 'password';

late final String _supabaseUrl;
late final String _anonKey;

void main(List<String> args) async {
  final env = _loadEnv(File('.env'));
  _supabaseUrl = env['SUPABASE_URL'] ?? (throw StateError('SUPABASE_URL missing from .env'));
  _anonKey = env['SUPABASE_ANON_KEY'] ?? (throw StateError('SUPABASE_ANON_KEY missing from .env'));

  final submissionMinutes = args.isNotEmpty ? int.parse(args[0]) : 2;
  final votingMinutes = args.length > 1 ? int.parse(args[1]) : 2;
  final region = args.length > 2 ? args[2] : 'north_america';

  stdout.write('Password: ');
  final entered = _readPassword();
  stdout.writeln();
  if (entered != _gatePassword) {
    stdout.writeln('Wrong password.');
    exit(1);
  }

  stdout.writeln('');
  stdout.writeln('League test-mode controller');
  stdout.writeln('  l = fast-forward current league '
      '($submissionMinutes min submissions -> $votingMinutes min voting -> restore)');
  stdout.writeln('  q = quit (restores the real schedule first if a simulation is running)');
  stdout.writeln('');

  String? leagueId;
  Map<String, dynamic>? original;
  Timer? midTimer;
  Timer? restoreTimer;

  Future<void> restore() async {
    midTimer?.cancel();
    restoreTimer?.cancel();
    if (leagueId == null || original == null) return;
    await _rpc('debug_set_league_window', {
      'p_league_id': leagueId,
      'p_submissions_close_at': original!['submissions_close_at'],
      'p_voting_closes_at': original!['voting_closes_at'],
    });
    stdout.writeln('\nRestored the league to its normal schedule.');
    leagueId = null;
    original = null;
  }

  Future<void> quit() async {
    await restore();
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } catch (_) {}
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => quit());

  var rawMode = true;
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {
    rawMode = false;
    stdout.writeln('(Raw key capture unavailable on this terminal — type l or q then press Enter.)');
  }

  Future<void> handleKey(String key) async {
    if (key == 'q') {
      await quit();
    } else if (key == 'l') {
      if (leagueId != null) {
        stdout.writeln('\nAlready running a simulation — press q to stop it first.');
        return;
      }

      stdout.writeln('\nFetching current league...');
      final league = await _rpc('debug_get_or_create_current_league', {'p_region': region});
      leagueId = league['id'] as String;
      original = {
        'submissions_close_at': league['submissions_close_at'],
        'voting_closes_at': league['voting_closes_at'],
      };

      final now = DateTime.now().toUtc();
      final submissionsClose = now.add(Duration(minutes: submissionMinutes));
      final votingCloses = submissionsClose.add(Duration(minutes: votingMinutes));

      await _rpc('debug_set_league_window', {
        'p_league_id': leagueId,
        'p_submissions_close_at': submissionsClose.toIso8601String(),
        'p_voting_closes_at': votingCloses.toIso8601String(),
      });

      stdout.writeln('Submissions close at $submissionsClose ($submissionMinutes min from now)');
      stdout.writeln('Voting closes at $votingCloses ($votingMinutes min after that)');
      stdout.writeln('Pull-to-refresh the league screen in the app to pick up the new countdown.');

      midTimer = Timer(Duration(minutes: submissionMinutes), () {
        stdout.writeln('\nSubmissions closed — voting phase should now be open in the app.');
      });
      restoreTimer = Timer(Duration(minutes: submissionMinutes + votingMinutes), restore);
    }

    if (!rawMode) {
      stdout.writeln('  l = fast-forward, q = quit');
    }
  }

  if (rawMode) {
    // stdin is a byte-chunk stream, not a stream of single keystrokes —
    // listen() (rather than a blocking read loop) keeps the event loop free
    // so the Timers above still fire while waiting for the next key.
    stdin.listen((chunk) {
      for (final byte in chunk) {
        final key = String.fromCharCode(byte).trim();
        if (key.isNotEmpty) unawaited(handleKey(key));
      }
    });
  } else {
    await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      final key = line.trim();
      if (key.isNotEmpty) await handleKey(key);
    }
  }
}

String _readPassword() {
  try {
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    return password;
  } catch (_) {
    return stdin.readLineSync() ?? '';
  }
}

Map<String, String> _loadEnv(File file) {
  final map = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx == -1) continue;
    map[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }
  return map;
}

Future<Map<String, dynamic>> _rpc(String function, Map<String, dynamic> args) async {
  final uri = Uri.parse('$_supabaseUrl/rest/v1/rpc/$function');
  final res = await http.post(
    uri,
    headers: {
      'apikey': _anonKey,
      'Authorization': 'Bearer $_anonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(args),
  );
  if (res.statusCode >= 300) {
    throw Exception('RPC $function failed: ${res.statusCode} ${res.body}');
  }
  if (res.body.isEmpty) return const {};
  final decoded = jsonDecode(res.body);
  return Map<String, dynamic>.from(decoded is List ? decoded.first as Map : decoded as Map);
}
