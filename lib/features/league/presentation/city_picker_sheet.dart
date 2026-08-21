import 'package:flutter/material.dart';

import '../../../shared/app_spacing.dart';
import '../../../shared/app_styles.dart';
import '../domain/league_city.dart';

/// Bottom sheet asking the user to type their city; returns the normalized
/// city name (see [normalizeCityName]), or null if dismissed without
/// entering one. Shared by the league screen's first-time prompt and the
/// "change city" row in Edit Profile.
Future<String?> pickLeagueCity(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CityPickerSheet(current: current),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.current});

  final String? current;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final city = normalizeCityName(_controller.text);
    if (city.isEmpty) return;
    Navigator.of(context).pop(city);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick your city', style: appBodyStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space4),
              Text(
                "You'll be matched into a weekly league with everyone else in your city.",
                style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
              ),
              const SizedBox(height: AppSpacing.space16),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: appInputDecoration('City, e.g. Austin'),
                style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.space16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
