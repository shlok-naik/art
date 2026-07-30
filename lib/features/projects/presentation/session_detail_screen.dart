import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'session_capture.dart';

enum _DetailStage { viewing, photoSource, camera, review, submitting }

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

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.projectId,
    required this.project,
  });

  final Map<String, dynamic> session;
  final String projectId;
  final Map<String, dynamic> project;

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  _DetailStage _stage = _DetailStage.viewing;
  String? _photoUrl;
  Uint8List? _newPhotoBytes;

  String get _sessionId => widget.session['id'].toString();

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.session['photo_url']?.toString();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newPhotoBytes = bytes;
        _stage = _DetailStage.review;
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
        _stage = _DetailStage.review;
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
    setState(() => _stage = _DetailStage.submitting);
    final repo = ref.read(sessionsRepositoryProvider);

    final String photoUrl;
    try {
      photoUrl = await repo.uploadPhoto(bytes, widget.projectId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _DetailStage.review);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
      return;
    }

    try {
      await repo.updateSessionPhoto(_sessionId, photoUrl);
      if (!mounted) return;
      ref.invalidate(sessionsListProvider(widget.projectId));
      setState(() {
        _photoUrl = photoUrl;
        _newPhotoBytes = null;
        _stage = _DetailStage.viewing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _DetailStage.review);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save session: $e')),
      );
    }
  }

  Widget _buildViewingBody() {
    final projectTitle = widget.project['title']?.toString() ?? widget.project['id'].toString();
    final durationSeconds = int.tryParse(widget.session['duration']?.toString() ?? '') ?? 0;
    final stage = widget.session['stage']?.toString();
    final difficulty = widget.session['difficulty']?.toString();
    final projectCompletion =
        int.tryParse(widget.project['completion_percent']?.toString() ?? '') ?? 0;
    final toolsUsedRaw = widget.session['tools_used'];
    final toolsUsed = toolsUsedRaw is List
        ? toolsUsedRaw.map((tool) => tool.toString()).toList()
        : const <String>[];

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
                    height: 240,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 64, color: Colors.black38),
                  )
                : CachedNetworkImage(
                    imageUrl: _photoUrl!,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _stage = _DetailStage.photoSource),
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
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: appCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROJECT',
                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 13, color: kAccentColor),
                ),
                const SizedBox(height: 2),
                Text(
                  projectTitle,
                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SessionStat(
                        label: 'Duration',
                        value: _formatDuration(Duration(seconds: durationSeconds)),
                      ),
                    ),
                    Expanded(
                      child: _SessionStat(
                        label: 'Logged',
                        value: _formatLoggedAt(widget.session['created_at']),
                      ),
                    ),
                  ],
                ),
                if (stage != null || difficulty != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (stage != null)
                        Expanded(child: _SessionStat(label: 'Stage', value: stage)),
                      if (difficulty != null)
                        Expanded(
                          child: _SessionStat(label: 'Difficulty', value: '$difficulty / 10'),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _SessionStat(label: 'Project completion', value: '$projectCompletion%'),
                if (toolsUsed.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tools Used',
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tool in toolsUsed)
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    late final Widget body;
    switch (_stage) {
      case _DetailStage.photoSource:
        body = PhotoSourcePicker(
          onTakePhoto: () => setState(() => _stage = _DetailStage.camera),
          onChooseFromGallery: _pickFromGallery,
          onUploadFile: _pickFile,
        );
      case _DetailStage.camera:
        body = SessionCameraView(
          onCaptured: (bytes) => setState(() {
            _newPhotoBytes = bytes;
            _stage = _DetailStage.review;
          }),
        );
      case _DetailStage.review:
      case _DetailStage.submitting:
        body = SessionPhotoReview(
          photoBytes: _newPhotoBytes!,
          isSubmitting: _stage == _DetailStage.submitting,
          onRetake: () => setState(() {
            _newPhotoBytes = null;
            _stage = _DetailStage.camera;
          }),
          onSubmit: _submitNewPhoto,
        );
      case _DetailStage.viewing:
        body = _buildViewingBody();
    }

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Session'),
        body: SafeArea(child: body),
        bottomNavigationBar: AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  const _SessionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.chewy(fontSize: 12, color: Colors.black54)),
        Text(value, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
