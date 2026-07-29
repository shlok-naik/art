import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers.dart';
import 'session_capture.dart';

enum _DetailStage { viewing, photoSource, camera, review, submitting }

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session, required this.projectId});

  final Map<String, dynamic> session;
  final String projectId;

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
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (_photoUrl == null || _photoUrl!.isEmpty)
                    ? const SizedBox(
                        width: 200,
                        height: 200,
                        child: Icon(Icons.image_not_supported, size: 64),
                      )
                    : Image.network(_photoUrl!, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32, top: 8),
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _stage = _DetailStage.photoSource),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Photo'),
          ),
        ),
      ],
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

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: body,
    );
  }
}
