import 'package:flutter/material.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';

const kSessionStages = [
  'Sketching',
  'Outlining',
  'Coloring',
  'Rendering',
  'Finishing Touches',
];

const kStageCompletionRecommendations = {
  'Sketching': 10,
  'Outlining': 25,
  'Coloring': 50,
  'Rendering': 75,
  'Finishing Touches': 90,
};

/// Collects stage/tools/difficulty metadata for a session before it's
/// submitted. Shown after the photo has been captured and confirmed.
class SessionDetailsFillOutScreen extends StatefulWidget {
  const SessionDetailsFillOutScreen({
    super.key,
    required this.onSubmit,
    required this.onBack,
    this.isSubmitting = false,
    this.title = 'Session Details',
    this.submitLabel = 'Save Session',
    this.initialName,
    this.initialStage,
    this.initialTools,
    this.initialDifficulty,
    this.initialProjectCompletion,
    this.showProjectCompletion = false,
  });

  final void Function(String name, String stage, List<String> toolsUsed, int difficulty, int projectCompletion)
      onSubmit;
  final VoidCallback onBack;
  final bool isSubmitting;
  final String title;
  final String submitLabel;
  final String? initialName;
  final String? initialStage;
  final List<String>? initialTools;
  final int? initialDifficulty;
  final int? initialProjectCompletion;
  final bool showProjectCompletion;

  @override
  State<SessionDetailsFillOutScreen> createState() => _SessionDetailsFillOutScreenState();
}

class _SessionDetailsFillOutScreenState extends State<SessionDetailsFillOutScreen> {
  late final _nameController = TextEditingController(text: widget.initialName ?? '');
  String? _nameError;
  late String _stage = widget.initialStage ?? kSessionStages.first;
  late final List<String> _tools = List.of(widget.initialTools ?? const []);
  final _toolController = TextEditingController();
  late int _difficulty = widget.initialDifficulty ?? 5;
  late int _projectCompletion = widget.initialProjectCompletion ?? 0;

  int get _recommendedCompletion => kStageCompletionRecommendations[_stage] ?? 0;

  void _handleSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give this session a name');
      return;
    }
    // Auto-commit whatever's still typed in the "add a tool" field, the same
    // way the name field is saved even without pressing Enter first —
    // otherwise a tool typed but not explicitly added (via + or Enter) is
    // silently dropped instead of saved.
    final pendingTool = _toolController.text.trim();
    final tools = List.of(_tools);
    if (pendingTool.isNotEmpty && !tools.contains(pendingTool)) {
      tools.add(pendingTool);
    }
    widget.onSubmit(name, _stage, tools, _difficulty, _projectCompletion);
  }

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
    _nameController.dispose();
    _toolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: appBodyStyle(color: kInkColor),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text('Session Name', style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !widget.isSubmitting,
              decoration: appInputDecoration('e.g. Sunset Mountains — Session 3').copyWith(
                errorText: _nameError,
              ),
              style: appBodyStyle(fontSize: 16, color: kInkColor),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 20),
            Text('Stage', style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
            Text('Tools Used', style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
                        label: Text(tool, style: appBodyStyle(fontSize: 14)),
                        onDeleted: widget.isSubmitting ? null : () => _removeTool(tool),
                        backgroundColor: kSurfaceColor,
                        side: const BorderSide(color: kHairlineColor, width: 1),
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
                    style: appBodyStyle(fontSize: 16, color: kInkColor),
                    onSubmitted: (_) => _addTool(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const AppIcon(AppIcons.plus, size: 26, color: kAccentColor),
                  onPressed: widget.isSubmitting ? null : _addTool,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Difficulty (1-10)',
              style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                    style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
              ],
            ),
            if (widget.showProjectCompletion) ...[
              const SizedBox(height: 16),
              Text(
                'Project Completion',
                style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kAccentTintColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recommended for $_stage: $_recommendedCompletion%',
                        style: appBodyStyle(fontSize: 13, color: kAccentColor),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.isSubmitting
                          ? null
                          : () => setState(() => _projectCompletion = _recommendedCompletion),
                      child: Text('Use this', style: appBodyStyle(color: kAccentColor)),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _projectCompletion.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      activeColor: kAccentColor,
                      label: '$_projectCompletion%',
                      onChanged: widget.isSubmitting
                          ? null
                          : (value) => setState(() => _projectCompletion = value.round()),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '$_projectCompletion%',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: widget.submitLabel,
              isLoading: widget.isSubmitting,
              onPressed: widget.isSubmitting ? null : _handleSubmit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.isSubmitting ? null : widget.onBack,
              child: Text('Back', style: appBodyStyle(color: kInkColor, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
