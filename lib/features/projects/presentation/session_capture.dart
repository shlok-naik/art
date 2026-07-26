import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
      final file = await controller.takePicture();
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
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32, top: 8),
          child: FloatingActionButton.large(
            onPressed: _capturing ? null : _capture,
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
                icon: const Icon(Icons.replay),
                label: const Text('Retake'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
