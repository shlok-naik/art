import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../data/profile_model.dart';
import '../providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _usernameController = TextEditingController(text: widget.profile.username);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (displayName.isEmpty || username.isEmpty) {
      setState(() => _errorText = 'Display name and username are required.');
      return;
    }
    if (password.isNotEmpty && password.length < 6) {
      setState(() => _errorText = 'Your new password must be at least 6 characters.');
      return;
    }

    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) {
      setState(() => _errorText = 'Your session has expired. Please log in again.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            username: username,
            displayName: displayName,
          );
      if (password.isNotEmpty) {
        await ref.read(authRepositoryProvider).updatePassword(password);
      }
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.code == '23505' ? 'That username is already taken.' : e.message);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Unable to save your changes. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Edit Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your details', style: GoogleFonts.chewy(fontSize: 20, color: Colors.black)),
              const SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                enabled: !_isSaving,
                decoration: appInputDecoration('Display name'),
                style: appBodyStyle(fontSize: 16),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _usernameController,
                enabled: !_isSaving,
                decoration: appInputDecoration('Username'),
                style: appBodyStyle(fontSize: 16),
              ),
              const SizedBox(height: 26),
              Text('Change password', style: GoogleFonts.chewy(fontSize: 20, color: Colors.black)),
              const SizedBox(height: 4),
              Text(
                'Leave this blank to keep your current password.',
                style: appBodyStyle(fontSize: 13, color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                enabled: !_isSaving,
                obscureText: true,
                decoration: appInputDecoration('New password'),
                style: appBodyStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (_errorText != null) ...[
                AppErrorText(_errorText!),
                const SizedBox(height: 12),
              ],
              AppPrimaryButton(label: 'Save changes', isLoading: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
