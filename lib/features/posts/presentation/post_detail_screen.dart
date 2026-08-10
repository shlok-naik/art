import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_spacing.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../auth/providers.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/domain/reactions.dart';
import '../../feed/presentation/comments_sheet.dart';
import '../../feed/providers.dart';
import '../../profile/providers.dart' as profile_providers;
import '../../projects/presentation/session_capture.dart';
import '../../projects/presentation/session_details_form.dart';
import '../../projects/providers.dart';
import '../../shell/main_shell.dart';

enum _Stage { viewing, photoSource, camera, reviewPhoto, savingPhoto, editingDetails, savingDetails }

/// Full detail view of a single post: photo, views, date, description, tools
/// used, time taken, and a breakdown of each individual reaction type (not
/// just a combined total). Reached from every context a session can be
/// opened in — the feed, My Posts, a project's session list, a profile's
/// post grid — so it renders the same everywhere; the photo/details edit
/// controls only appear when the signed-in user owns the post.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final FeedPost post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  _Stage _stage = _Stage.viewing;
  Uint8List? _newPhotoBytes;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: opening the full detail view records an aggregate view.
    ref.read(sessionsRepositoryProvider).recordView(widget.post.id);
  }

  late String? _photoUrl = widget.post.photoUrl;
  late String? _sessionName = widget.post.sessionName;
  late String _stageName = widget.post.stage ?? kSessionStages.first;
  late List<String> _toolsUsed = List.of(widget.post.toolsUsed);
  late int _difficulty = widget.post.difficulty ?? 5;

  String get _title {
    final name = _sessionName;
    return (name != null && name.isNotEmpty) ? name : widget.post.projectTitle;
  }

  String get _description =>
      'Working on: $_stageName';

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newPhotoBytes = bytes;
        _stage = _Stage.reviewPhoto;
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
        _newPhotoBytes = bytes;
        _stage = _Stage.reviewPhoto;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load file: $e')),
      );
    }
  }

  Future<void> _submitNewPhoto() async {
    final bytes = _newPhotoBytes;
    if (bytes == null) return;
    setState(() => _stage = _Stage.savingPhoto);
    final repo = ref.read(sessionsRepositoryProvider);

    final String photoUrl;
    try {
      photoUrl = await repo.uploadPhoto(bytes, widget.post.projectId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.reviewPhoto);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
      return;
    }

    try {
      await repo.updateSessionPhoto(widget.post.id, photoUrl);
      if (!mounted) return;
      _invalidateEverywhere();
      setState(() {
        _photoUrl = photoUrl;
        _newPhotoBytes = null;
        _stage = _Stage.viewing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.reviewPhoto);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save photo: $e')),
      );
    }
  }

  Future<void> _submitDetails(
    String name,
    String stage,
    List<String> toolsUsed,
    int difficulty,
    int _,
  ) async {
    setState(() => _stage = _Stage.savingDetails);
    final repo = ref.read(sessionsRepositoryProvider);
    try {
      await repo.updateSessionDetails(
        sessionId: widget.post.id,
        stage: stage,
        toolsUsed: toolsUsed,
        difficulty: difficulty,
        name: name,
      );
      if (!mounted) return;
      ref.invalidate(sessionsListProvider(widget.post.projectId));
      _invalidateEverywhere();
      setState(() {
        _sessionName = name;
        _stageName = stage;
        _toolsUsed = toolsUsed;
        _difficulty = difficulty;
        _stage = _Stage.viewing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.editingDetails);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    }
  }

  /// Every other place this session's data is cached and displayed — the
  /// feed, the owner's own post grid, the public profile grid (same
  /// provider, keyed by user id), and the Stats page charts that derive
  /// from difficulty/duration/stage. A photo or detail edit here needs to
  /// show up in all of them, not just this screen.
  void _invalidateEverywhere() {
    final userId = widget.post.userId;
    ref.invalidate(feedPostsProvider);
    ref.invalidate(myPostsProvider);
    ref.invalidate(userPostsProvider(userId));
    ref.invalidate(profile_providers.sessionStatsProvider(userId));
    ref.invalidate(profile_providers.stageMinutesProvider(userId));
    ref.invalidate(profile_providers.difficultyHistogramProvider(userId));
    ref.invalidate(profile_providers.userProjectGalleriesProvider(userId));
  }

  /// Whether the signed-in user owns this post — gates the edit controls.
  bool get _isOwner =>
      ref.read(supabaseClientProvider).auth.currentUser?.id == widget.post.userId;

  Widget _buildViewingBody() {
    final post = widget.post;
    final countsMap =
        ref.watch(sessionReactionsProvider(post.id)).value?.counts ?? const <String, int>{};
    final counts = ReactionCounts.fromCountsMap(countsMap);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MuseumFrame(
            radius: 10,
            matWidth: 6,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: (_photoUrl == null || _photoUrl!.isEmpty)
                  ? Container(
                      color: kSurfaceColor,
                      alignment: Alignment.center,
                      child: const AppIcon(AppIcons.image, size: 48, color: kMutedColor),
                    )
                  : CachedNetworkImage(imageUrl: _photoUrl!, fit: BoxFit.cover),
            ),
          ),
          if (_isOwner) ...[
            const SizedBox(height: AppSpacing.space12),
            Row(
              children: [
                Expanded(
                  child: AppOutlinedPillButton(
                    label: 'Edit photo',
                    onPressed: () => setState(() => _stage = _Stage.photoSource),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: AppOutlinedPillButton(
                    label: 'Edit details',
                    onPressed: () => setState(() => _stage = _Stage.editingDetails),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space16),
          Text(_title, style: appBodyStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          if (_title != post.projectTitle) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Part of ${post.projectTitle}',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kMutedColor),
            ),
          ],
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: [
              // Views stays plain ink — gold is reserved for engagement
              // (likes/reactions/ratings), not raw view counts.
              Expanded(child: AppDetailStat(label: 'Views', value: formatCount(post.views))),
              Expanded(
                child: AppDetailStat(
                  label: 'Date posted',
                  value: formatMonthDayYear(post.datePosted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),
          Text('Details', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.space8),
          Text(_description, style: appBodyStyle(fontSize: 14, color: kMutedColor)),
          const SizedBox(height: AppSpacing.space16),
          Text('Tools used', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.space8),
          if (_toolsUsed.isEmpty)
            Text('None recorded', style: appBodyStyle(fontSize: 14, color: kMutedColor))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tool in _toolsUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space8),
                    decoration: appFlatCardDecoration(radius: 20),
                    child: Text(tool, style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.space16),
          Text('Time taken', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.space4),
          Text(post.timeTaken, style: appBodyStyle(fontSize: 14, color: kMutedColor)),
          const SizedBox(height: AppSpacing.space20),
          Text('Reactions', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.space8),
          _ReactionBreakdown(counts: counts),
          const SizedBox(height: AppSpacing.space20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comments', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: () => showCommentsSheet(
                  context,
                  sessionId: post.id,
                  postOwnerUserId: post.userId,
                ),
                icon: const AppIcon(AppIcons.comment, size: 16, color: kAccentColor),
                label: Text(
                  'View (${ref.watch(sessionCommentsProvider(post.id)).value?.length ?? 0})',
                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    late final Widget body;
    switch (_stage) {
      case _Stage.photoSource:
        body = PhotoSourcePicker(
          onTakePhoto: () => setState(() => _stage = _Stage.camera),
          onChooseFromGallery: _pickFromGallery,
          onUploadFile: _pickFile,
        );
      case _Stage.camera:
        body = SessionCameraView(
          onCaptured: (bytes) => setState(() {
            _newPhotoBytes = bytes;
            _stage = _Stage.reviewPhoto;
          }),
        );
      case _Stage.reviewPhoto:
      case _Stage.savingPhoto:
        body = SessionPhotoReview(
          photoBytes: _newPhotoBytes!,
          isSubmitting: _stage == _Stage.savingPhoto,
          onRetake: () => setState(() {
            _newPhotoBytes = null;
            _stage = _Stage.camera;
          }),
          onSubmit: _submitNewPhoto,
        );
      case _Stage.editingDetails:
      case _Stage.savingDetails:
        body = SessionDetailsFillOutScreen(
          title: 'Edit Details',
          submitLabel: 'Save Changes',
          initialName: _sessionName,
          initialStage: _stageName,
          initialTools: _toolsUsed,
          initialDifficulty: _difficulty,
          isSubmitting: _stage == _Stage.savingDetails,
          onBack: () => setState(() => _stage = _Stage.viewing),
          onSubmit: _submitDetails,
        );
      case _Stage.viewing:
        body = _buildViewingBody();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Post'),
      body: SafeArea(child: body),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) => goToMainTab(context, ref, i),
      ),
    );
  }
}

class _ReactionBreakdown extends StatelessWidget {
  const _ReactionBreakdown({required this.counts});

  final ReactionCounts counts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ReactionChip(icon: AppIcons.heartFilled, count: counts.upCount),
        _ReactionChip(icon: AppIcons.thumbDown, count: counts.downCount),
        for (final reaction in EmojiReaction.values)
          _ReactionChip(icon: emojiIcons[reaction]!, count: counts.emojiCounts[reaction]!),
      ],
    );
  }
}

/// One reaction type's total: flat surface pill, ink icon + ink count. Ink
/// rather than gold — the design reserves gold for the headline engagement
/// numbers (feed likes, grid reaction totals, ratings), and a full row of
/// gold pills would drown that signal.
class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.icon, required this.count});

  final String icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space8),
      decoration: appFlatCardDecoration(radius: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 14, color: kInkColor),
          const SizedBox(width: AppSpacing.space8),
          Text(
            formatCount(count),
            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
