import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

const kSessionStages = [
  'Sketching',
  'Outlining',
  'Drawing',
  'Coloring',
  'Inking',
  'Rendering',
  'Editing',
  'Finishing Touches',
];

/// Collects stage/tools/difficulty metadata for a session before it's
/// submitted. Shown after the photo has been captured and confirmed.
class SessionDetailsFillOutScreen extends StatefulWidget {
  const SessionDetailsFillOutScreen({
    super.key,
    required this.onSubmit,
    required this.onBack,
    this.isSubmitting = false,
  });

  final void Function(String stage, List<String> toolsUsed, int difficulty) onSubmit;
  final VoidCallback onBack;
  final bool isSubmitting;

  @override
  State<SessionDetailsFillOutScreen> createState() => _SessionDetailsFillOutScreenState();
}

class _SessionDetailsFillOutScreenState extends State<SessionDetailsFillOutScreen> {
  String _stage = kSessionStages.first;
  final List<String> _tools = [];
  final _toolController = TextEditingController();
  int _difficulty = 5;

  void _addTool() {
    final value = _toolController.text.trim();
    if (value.isEmpty || _tools.contains(value)) {
      _toolController.clear();
      return;
    }
    setState(() {
      _tools.add(value);
      _toolController.clear();
    });
  }

  void _removeTool(String tool) {
    setState(() => _tools.remove(tool));
  }

  @override
  void dispose() {
    _toolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Details',
              style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text('Stage', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _stage,
              decoration: appInputDecoration('Stage'),
              items: [
                for (final stage in kSessionStages) DropdownMenuItem(value: stage, child: Text(stage)),
              ],
              onChanged: widget.isSubmitting
                  ? null
                  : (value) => setState(() => _stage = value ?? _stage),
            ),
            const SizedBox(height: 20),
            Text('Tools Used', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_tools.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tool in _tools)
                      Chip(
                        label: Text(tool, style: GoogleFonts.chewy(fontSize: 14)),
                        onDeleted: widget.isSubmitting ? null : () => _removeTool(tool),
                        backgroundColor: Colors.grey.shade100,
                        side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toolController,
                    enabled: !widget.isSubmitting,
                    decoration: appInputDecoration('Add a tool (e.g. Procreate)'),
                    style: GoogleFonts.chewy(fontSize: 16, color: Colors.black),
                    onSubmitted: (_) => _addTool(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: kAccentColor, size: 32),
                  onPressed: widget.isSubmitting ? null : _addTool,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Difficulty (1-10)',
              style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _difficulty.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: kAccentColor,
                    label: '$_difficulty',
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) => setState(() => _difficulty = value.round()),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$_difficulty',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Save Session',
              isLoading: widget.isSubmitting,
              onPressed: () => widget.onSubmit(_stage, List.of(_tools), _difficulty),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.isSubmitting ? null : widget.onBack,
              child: Text('Back', style: GoogleFonts.chewy(color: Colors.black, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
