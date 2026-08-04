import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/domain/reactions.dart';
import '../../feed/providers.dart';
import '../../profile/providers.dart' as profile_providers;
import '../../projects/presentation/session_capture.dart';
import '../../projects/presentation/session_details_form.dart';
import '../../projects/providers.dart';
import '../../shell/main_shell.dart';

enum _Stage { viewing, photoSource, camera, reviewPhoto, savingPhoto, editingDetails, savingDetails }

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatDate(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

/// Full detail view of a single post: photo, views, date, description, tools
/// used, time taken, and a breakdown of each individual reaction type (not
/// just a combined total). Also supports editing the photo and the
/// stage/tools/difficulty details, since both already round-trip through the
/// existing sessions backend.
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
    // Fire-and-forget: opening the full detail view is a view event. Safe
    // to also fire from the feed card — the server upsert dedupes by
    // (session_id, viewer_id).
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

  Widget _buildViewingBody() {
    final post = widget.post;
    final countsMap =
        ref.watch(sessionReactionsProvider(post.id)).value?.counts ?? const <String, int>{};
    final counts = ReactionCounts.fromCountsMap(countsMap);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: (_photoUrl == null || _photoUrl!.isEmpty)
                ? Container(
                    width: double.infinity,
                    height: 260,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 64, color: Colors.black38),
                  )
                : CachedNetworkImage(
                    imageUrl: _photoUrl!,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _stage = _Stage.photoSource),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _stage = _Stage.editingDetails),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.tune),
                  label: const Text('Edit Details'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _title,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 26),
          ),
          if (_title != post.projectTitle) ...[
            const SizedBox(height: 2),
            Text(
              'Part of ${post.projectTitle}',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  icon: Icons.visibility_outlined,
                  label: 'Views',
                  value: _formatCount(post.views),
                ),
              ),
              Expanded(
                child: _DetailStat(
                  icon: Icons.event_outlined,
                  label: 'Date posted',
                  value: _formatDate(post.datePosted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Details', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(_description, style: GoogleFonts.chewy(fontSize: 15)),
          const SizedBox(height: 16),
          Text('Tools Used', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (_toolsUsed.isEmpty)
            Text('None recorded', style: GoogleFonts.chewy(fontSize: 14, color: Colors.black54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tool in _toolsUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorderColor, width: kBorderWidth),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tool, style: GoogleFonts.chewy(fontSize: 14)),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Text('Time Taken', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(post.timeTaken, style: GoogleFonts.chewy(fontSize: 15)),
          const SizedBox(height: 20),
          Text('Reactions', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          _ReactionBreakdown(counts: counts),
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

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Post'),
        body: SafeArea(child: body),
        bottomNavigationBar: AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.chewy(fontSize: 12, color: Colors.black54)),
            Text(value, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
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
        _ReactionChip(glyph: '👍', count: counts.upCount),
        _ReactionChip(glyph: '👎', count: counts.downCount),
        for (final reaction in EmojiReaction.values)
          _ReactionChip(glyph: emojiGlyphs[reaction]!, count: counts.emojiCounts[reaction]!),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.glyph, required this.count});

  final String glyph;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: appCardDecoration(radius: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(glyph, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            _formatCount(count),
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
