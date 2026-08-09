import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref.read(profileRepositoryProvider).createProfile(
            userId: userId,
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.code == '23505') {
        setState(() => _errorText = 'That username is already taken.');
      } else {
        setState(() => _errorText = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppWordmark(),
                const SizedBox(height: 22),
                Text(
                  'Set up',
                  style: appHeadlineStyle(fontSize: 34, color: kNavyColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _displayNameController,
                  decoration: appInputDecoration('Display name'),
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: appInputDecoration('Username'),
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 22),
                if (_errorText != null) ...[
                  AppErrorText(_errorText!),
                  const SizedBox(height: 12),
                ],
                AppPrimaryButton(
                  label: 'Save',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
