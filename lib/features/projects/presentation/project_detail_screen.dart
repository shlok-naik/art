import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/session_banner_ad.dart';
import '../../../shared/session_music_player.dart';
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space8),
          child: SessionBannerAd(),
        ),
        Expanded(child: Center(child: _buildTimerContent(isPaused))),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space8),
          child: SessionBannerAd(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space16,
            0,
            AppSpacing.space16,
            AppSpacing.space16,
          ),
          child: SessionMusicPlayer(),
        ),
      ],
    );
  }

  Widget _buildTimerContent(bool isPaused) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isPaused ? 'PAUSED' : 'SESSION IN PROGRESS',
          style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kAccentColor),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          formatDurationHms(_elapsed),
          style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 64, color: kInkColor),
        ),
        const SizedBox(height: AppSpacing.space32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _togglePause,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: kHairlineColor, width: 1),
                foregroundColor: kInkColor,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space12),
                textStyle: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              icon: AppIcon(isPaused ? AppIcons.play : AppIcons.pause, size: 20, color: kInkColor),
              label: Text(isPaused ? 'Resume' : 'Pause'),
            ),
            const SizedBox(width: AppSpacing.space16),
            ElevatedButton.icon(
              onPressed: _endSession,
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: kAccentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space12),
                textStyle: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              icon: const AppIcon(AppIcons.stop, size: 18, color: Colors.white),
              label: const Text('End'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleBody() {
    final sessionsAsync = ref.watch(sessionsListProvider(_projectId));
    return Column(
      children: [
        if (!_isOwner)
          const SizedBox(height: AppSpacing.space8)
        else if (_isFinished)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
            decoration: BoxDecoration(
              color: kSuccessBgColor,
              border: Border.all(color: kHairlineColor, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const AppIcon(AppIcons.checkCircle, size: 20, color: kSuccessTextColor),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Text(
                    'This project is finished — 100% complete and locked. No new sessions can be added.',
                    style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSuccessTextColor),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            child: AppErrorText(_errorText!),
          ),
        const SizedBox(height: AppSpacing.space12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Past Sessions', style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20)),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Text(
                    'No sessions logged yet.',
                    style: appBodyStyle(fontSize: 15, color: kMutedColor),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
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
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      decoration: appFlatCardDecoration(),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Container(
                                    width: 52,
                                    height: 52,
                                    color: kHairlineColor,
                                    child: const AppIcon(AppIcons.image, size: 24, color: kMutedColor),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (session['name']?.toString().isNotEmpty ?? false)
                                      ? session['name'].toString()
                                      : 'Untitled Session',
                                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                Text(
                                  'Logged: ${formatDateValue(session['created_at'])} · ${formatDurationHms(Duration(seconds: durationSeconds))}',
                                  style: appBodyStyle(fontSize: 13, color: kMutedColor),
                                ),
                              ],
                            ),
                          ),
                          const AppIcon(AppIcons.chevronRight, size: 18, color: kMutedColor),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppSkeletonScreen(),
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
      style: appBodyStyle(color: kInkColor),
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
