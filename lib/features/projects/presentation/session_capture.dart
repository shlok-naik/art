import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

/// Lets the user choose how to attach a photo to their session: take a new
/// one with the camera, or upload an existing one (gallery or file).
class PhotoSourcePicker extends StatelessWidget {
  const PhotoSourcePicker({
    super.key,
    required this.onTakePhoto,
    required this.onChooseFromGallery,
    required this.onUploadFile,
  });

  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFromGallery;
  final VoidCallback onUploadFile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 56, color: kAccentColor),
            const SizedBox(height: 12),
            Text('Add a Photo', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              'Capture or upload a photo to finish this session.',
              textAlign: TextAlign.center,
              style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            AppPrimaryButton(label: 'Take Photo', onPressed: onTakePhoto),
            const SizedBox(height: 12),
            _SourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onPressed: onChooseFromGallery,
            ),
            const SizedBox(height: 12),
            _SourceButton(
              icon: Icons.upload_file_outlined,
              label: 'Upload File',
              onPressed: onUploadFile,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: const BorderSide(color: kBorderColor, width: kBorderWidth),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class SessionCameraView extends StatefulWidget {
  const SessionCameraView({super.key, required this.onCaptured});

  final ValueChanged<Uint8List> onCaptured;

  @override
  State<SessionCameraView> createState() => _SessionCameraViewState();
}

class _SessionCameraViewState extends State<SessionCameraView> {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not start camera: $e');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture().timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('Camera did not respond in time'),
          );
      final bytes = await file.readAsBytes();
      widget.onCaptured(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
      setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppErrorText(_error!),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: kAccentColor));
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColor, width: kBorderWidth),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32, top: 8),
          child: FloatingActionButton.large(
            onPressed: _capturing ? null : _capture,
            backgroundColor: kAccentColor,
            foregroundColor: Colors.white,
            child: _capturing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }
}

class SessionPhotoReview extends StatelessWidget {
  const SessionPhotoReview({
    super.key,
    required this.photoBytes,
    required this.isSubmitting,
    required this.onRetake,
    required this.onSubmit,
  });

  final Uint8List photoBytes;
  final bool isSubmitting;
  final VoidCallback onRetake;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.memory(photoBytes, fit: BoxFit.cover)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : onRetake,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                icon: const Icon(Icons.replay),
                label: const Text('Retake'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(isSubmitting ? 'Submitting…' : 'Submit'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
