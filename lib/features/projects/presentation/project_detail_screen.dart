import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'session_capture.dart';
import 'session_detail_screen.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatLoggedAt(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

enum _SessionStage { idle, running, paused, camera, review, submitting }

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.project});

  final Map<String, dynamic> project;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  _SessionStage _stage = _SessionStage.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  Uint8List? _capturedPhoto;
  String? _errorText;

  String get _projectId => widget.project['id'].toString();

  void _startSession() {
    setState(() {
      _stage = _SessionStage.running;
      _elapsed = Duration.zero;
      _errorText = null;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _togglePause() {
    if (_stage == _SessionStage.running) {
      _ticker?.cancel();
      setState(() => _stage = _SessionStage.paused);
    } else if (_stage == _SessionStage.paused) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() => _stage = _SessionStage.running);
    }
  }

  void _endSession() {
    _ticker?.cancel();
    setState(() => _stage = _SessionStage.camera);
  }

  Future<void> _submit() async {
    final photo = _capturedPhoto;
    if (photo == null) return;
    setState(() => _stage = _SessionStage.submitting);
    try {
      final repo = ref.read(sessionsRepositoryProvider);
      final photoUrl = await repo.uploadPhoto(photo, _projectId);
      await repo.createSession(
        projectId: _projectId,
        durationSeconds: _elapsed.inSeconds,
        photoUrl: photoUrl,
      );
      if (!mounted) return;
      ref.invalidate(sessionsListProvider(_projectId));
      setState(() {
        _stage = _SessionStage.idle;
        _elapsed = Duration.zero;
        _capturedPhoto = null;
      });
    } catch (e) {
      debugPrint('Session submit failed: $e');
      if (!mounted) return;
      setState(() {
        _stage = _SessionStage.review;
        _errorText = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save session: $e')),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _buildTimerBody() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(_elapsed), style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _togglePause,
                icon: Icon(_stage == _SessionStage.running ? Icons.pause : Icons.play_arrow),
                label: Text(_stage == _SessionStage.running ? 'Pause' : 'Resume'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _endSession,
                icon: const Icon(Icons.stop),
                label: const Text('End'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdleBody() {
    final sessionsAsync = ref.watch(sessionsListProvider(_projectId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _startSession,
            child: const Text('Start New Session'),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Center(child: Text('No sessions logged yet.'));
              }
              return ListView.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final photoUrl = session['photo_url']?.toString();
                  final durationSeconds =
                      int.tryParse(session['duration']?.toString() ?? '') ?? 0;
                  return ListTile(
                    leading: (photoUrl == null || photoUrl.isEmpty)
                        ? const CircleAvatar(child: Icon(Icons.image_not_supported))
                        : CircleAvatar(backgroundImage: NetworkImage(photoUrl)),
                    title: Text(_formatDuration(Duration(seconds: durationSeconds))),
                    subtitle: Text('Logged: ${_formatLoggedAt(session['created_at'])}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SessionDetailScreen(
                            session: session,
                            projectId: _projectId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Failed to load sessions: $error')),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.project['title']?.toString() ?? widget.project['id'].toString();

    late final Widget body;
    switch (_stage) {
      case _SessionStage.camera:
        body = SessionCameraView(
          onCaptured: (bytes) => setState(() {
            _capturedPhoto = bytes;
            _stage = _SessionStage.review;
          }),
        );
      case _SessionStage.review:
      case _SessionStage.submitting:
        body = SessionPhotoReview(
          photoBytes: _capturedPhoto!,
          isSubmitting: _stage == _SessionStage.submitting,
          onRetake: () => setState(() {
            _capturedPhoto = null;
            _stage = _SessionStage.camera;
          }),
          onSubmit: _submit,
        );
      case _SessionStage.running:
      case _SessionStage.paused:
        body = _buildTimerBody();
      case _SessionStage.idle:
        body = _buildIdleBody();
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
