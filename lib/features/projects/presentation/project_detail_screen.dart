import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../achievements/providers.dart';
import '../../auth/providers.dart';
import '../../feed/domain/feed_post.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../profile/providers.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'session_capture.dart';
import 'session_details_form.dart';

enum _SessionStage { idle, running, paused, photoSource, camera, review, details, submitting }

/// The single project view, used from every context a project can be opened
/// in: the Projects tab and Home (your own projects), a league submission,
/// and a profile's project circles. The session list renders identically
/// everywhere; the ownership check on `project['user_id']` is what gates the
/// editable controls (Start New Session), so someone else's project is
/// always read-only — RLS would reject a write anyway, this just keeps the
/// UI honest about it.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.project, this.artistUsername});

  final Map<String, dynamic> project;

  /// The project owner's username, for opening sessions as posts. Only
  /// needed when viewing someone else's project (league, profile); omitted
  /// for your own, where the signed-in profile's username is used.
  final String? artistUsername;

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

  bool get _isFinished =>
      (int.tryParse(widget.project['completion_percent']?.toString() ?? '') ?? 0) >= 100;

  /// Whether the signed-in user owns this project — gates every editable
  /// control on this screen.
  bool get _isOwner {
    final myUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    return myUserId != null && widget.project['user_id']?.toString() == myUserId;
  }

  void _startSession() {
    if (_isFinished || !_isOwner) return;
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
    setState(() => _stage = _SessionStage.photoSource);
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedPhoto = bytes;
        _stage = _SessionStage.review;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load photo: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) return;
      if (!mounted) return;
      setState(() {
        _capturedPhoto = bytes;
        _stage = _SessionStage.review;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load file: $e')),
      );
    }
  }

  Future<void> _submit({
    required String name,
    required String stage,
    required List<String> toolsUsed,
    required int difficulty,
    required int projectCompletion,
  }) async {
    final photo = _capturedPhoto;
    if (photo == null) return;
    setState(() => _stage = _SessionStage.submitting);
    final repo = ref.read(sessionsRepositoryProvider);

    final String photoUrl;
    try {
      photoUrl = await repo.uploadPhoto(photo, _projectId);
    } catch (e) {
      debugPrint('Photo upload failed: $e');
      if (!mounted) return;
      setState(() {
        _stage = _SessionStage.details;
        _errorText = 'Failed to upload photo: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
      return;
    }

    try {
      await repo.createSession(
        projectId: _projectId,
        durationSeconds: _elapsed.inSeconds,
        photoUrl: photoUrl,
        stage: stage,
        toolsUsed: toolsUsed,
        difficulty: difficulty,
        name: name,
      );
      try {
        await ref.read(projectsRepositoryProvider).updateCompletion(_projectId, projectCompletion);
        widget.project['completion_percent'] = projectCompletion;
        ref.invalidate(projectsListProvider);
        ref.invalidate(lastOpenedProjectProvider);
      } catch (e) {
        debugPrint('Project completion update failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session saved, but project completion was not updated.')),
          );
        }
      }
      if (!mounted) return;
      ref.invalidate(sessionsListProvider(_projectId));
      ref.invalidate(newlyUnlockedAchievementsProvider);
      setState(() {
        _stage = _SessionStage.idle;
        _elapsed = Duration.zero;
        _capturedPhoto = null;
        _errorText = null;
      });
    } catch (e) {
      debugPrint('Session save failed: $e');
      if (!mounted) return;
      setState(() {
        _stage = _SessionStage.details;
        _errorText = 'Failed to save session: $e';
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
    final isPaused = _stage == _SessionStage.paused;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPaused ? 'PAUSED' : 'SESSION IN PROGRESS',
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16, color: kAccentColor),
          ),
          const SizedBox(height: 8),
          Text(
            formatDurationHms(_elapsed),
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 64, color: Colors.black),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _togglePause,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _endSession,
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
        if (!_isOwner)
          const SizedBox(height: 8)
        else if (_isFinished)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kSuccessBgColor,
              border: Border.all(color: kBorderColor, width: kBorderWidth),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: kSuccessTextColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This project is finished — 100% complete and locked. No new sessions can be added.',
                    style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kSuccessTextColor),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppPrimaryButton(label: 'Start New Session', onPressed: _startSession),
          ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppErrorText(_errorText!),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Past Sessions', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Text(
                    'No sessions logged yet.',
                    style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final photoUrl = session['photo_url']?.toString();
                  final durationSeconds =
                      int.tryParse(session['duration']?.toString() ?? '') ?? 0;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final artist = widget.artistUsername ??
                          ref.read(currentProfileProvider).value?.username ??
                          'you';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            post: FeedPost.fromRow(
                              session: session,
                              project: widget.project,
                              artist: artist,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: appCardDecoration(),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported, color: Colors.black38),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDurationHms(Duration(seconds: durationSeconds)),
                                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Logged: ${formatDateValue(session['created_at'])}',
                                  style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black38),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: kAccentColor)),
            error: (error, _) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(sessionsListProvider(_projectId)),
            ),
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
      case _SessionStage.photoSource:
        body = PhotoSourcePicker(
          onTakePhoto: () => setState(() => _stage = _SessionStage.camera),
          onChooseFromGallery: _pickFromGallery,
          onUploadFile: _pickFile,
        );
      case _SessionStage.camera:
        body = SessionCameraView(
          onCaptured: (bytes) => setState(() {
            _capturedPhoto = bytes;
            _stage = _SessionStage.review;
          }),
        );
      case _SessionStage.review:
        body = SessionPhotoReview(
          photoBytes: _capturedPhoto!,
          isSubmitting: false,
          onRetake: () => setState(() {
            _capturedPhoto = null;
            _stage = _SessionStage.camera;
          }),
          onSubmit: () => setState(() => _stage = _SessionStage.details),
        );
      case _SessionStage.details:
      case _SessionStage.submitting:
        body = SessionDetailsFillOutScreen(
          initialProjectCompletion:
              int.tryParse(widget.project['completion_percent']?.toString() ?? '') ?? 0,
          showProjectCompletion: true,
          isSubmitting: _stage == _SessionStage.submitting,
          onBack: () => setState(() => _stage = _SessionStage.review),
          onSubmit: (name, stage, toolsUsed, difficulty, projectCompletion) => _submit(
            name: name,
            stage: stage,
            toolsUsed: toolsUsed,
            difficulty: difficulty,
            projectCompletion: projectCompletion,
          ),
        );
      case _SessionStage.running:
      case _SessionStage.paused:
        body = _buildTimerBody();
      case _SessionStage.idle:
        body = _buildIdleBody();
    }

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, title),
        body: SafeArea(child: body),
        bottomNavigationBar: AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}
