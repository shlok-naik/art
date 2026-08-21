import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_styles.dart';
import '../data/profile_model.dart';
import '../domain/stat_key.dart';
import '../providers.dart';

/// Lets the signed-in user choose which stats appear on their public Stats
/// page. Each toggle saves immediately — there's no separate save step.
class StatsVisibilityScreen extends ConsumerStatefulWidget {
  const StatsVisibilityScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<StatsVisibilityScreen> createState() => _StatsVisibilityScreenState();
}

class _StatsVisibilityScreenState extends ConsumerState<StatsVisibilityScreen> {
  late Set<StatKey> _visible = statKeysFromStorage(widget.profile.visibleStats).toSet();
  bool _isSaving = false;
  String? _errorText;

  Future<void> _toggle(StatKey key, bool isVisible) async {
    final previous = Set<StatKey>.of(_visible);
    setState(() {
      if (isVisible) {
        _visible.add(key);
      } else {
        _visible.remove(key);
      }
      _isSaving = true;
      _errorText = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateVisibleStats(
            userId: widget.profile.id,
            visibleStats: [for (final k in _visible) k.storageKey],
          );
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileByIdProvider(widget.profile.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _visible = previous;
        _errorText = 'Failed to save: $e';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appThemedAppBar(context, 'Choose stats to show'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              "Pick what shows on your public Stats page — visible to anyone who taps 'View stats' on your profile.",
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            if (_errorText != null) ...[
              AppErrorText(_errorText!),
              const SizedBox(height: 12),
            ],
            for (final key in StatKey.values) ...[
              _StatToggleTile(
                statKey: key,
                isVisible: _visible.contains(key),
                enabled: !_isSaving,
                onChanged: (value) => _toggle(key, value),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatToggleTile extends StatelessWidget {
  const _StatToggleTile({
    required this.statKey,
    required this.isVisible,
    required this.enabled,
    required this.onChanged,
  });

  final StatKey statKey;
  final bool isVisible;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 2),
      child: Row(
        children: [
          Icon(statKey.icon, size: 20, color: kAccentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(statKey.label, style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInkColor)),
          ),
          Switch(
            value: isVisible,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: kAccentColor,
          ),
        ],
      ),
    );
  }
}
