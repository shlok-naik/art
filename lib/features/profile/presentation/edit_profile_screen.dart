import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../league/domain/league_region.dart';
import '../../league/presentation/region_picker_sheet.dart';
import '../../league/providers.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';
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
  late final TextEditingController _bioController;
  final _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _errorText;
  late String? _region;
  late String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _region = widget.profile.region;
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) {
      setState(() => _errorText = 'Your session has expired. Please log in again.');
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = true;
        _errorText = null;
      });
      final repo = ref.read(profileRepositoryProvider);
      final avatarUrl = await repo.uploadAvatar(bytes, userId);
      await repo.updateAvatarUrl(userId: userId, avatarUrl: avatarUrl);
      if (!mounted) return;
      setState(() {
        _avatarUrl = avatarUrl;
        _isUploadingAvatar = false;
      });
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileByIdProvider(userId));
    } on MissingColumnException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
        _errorText = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
        _errorText = 'Failed to update profile picture: $e';
      });
    }
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
      final bio = _bioController.text.trim();
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            username: username,
            displayName: displayName,
            bio: bio.isEmpty ? null : bio,
          );
      final region = _region;
      if (region != null && region != widget.profile.region) {
        await ref.read(profileRepositoryProvider).updateRegion(userId: userId, region: region);
        ref.invalidate(currentLeagueProvider);
      }
      if (password.isNotEmpty) {
        await ref.read(authRepositoryProvider).updatePassword(password);
      }
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileByIdProvider(userId));
      Navigator.of(context).pop();
    } on MissingColumnException catch (e) {
      // Username/display name still saved (see ProfileRepository.updateProfile)
      // — only bio couldn't. Don't pop, so the user sees why bio looks
      // unchanged, but also don't treat this as a full failure.
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileByIdProvider(userId));
      setState(() => _errorText = e.message);
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
      appBar: appThemedAppBar(context, 'Edit Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _isUploadingAvatar ? null : _pickAvatar,
                  borderRadius: BorderRadius.circular(48),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: kBorderColor, width: kBorderWidth)),
                        ),
                        child: AppInitialsAvatar(
                          name: widget.profile.displayName,
                          size: 88,
                          imageUrl: _avatarUrl,
                        ),
                      ),
                      if (_isUploadingAvatar)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        )
                      else
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: kAccentColor,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Your details', style: GoogleFonts.chewy(fontSize: 20, color: kInkColor)),
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
              const SizedBox(height: 14),
              TextField(
                controller: _bioController,
                enabled: !_isSaving,
                maxLines: 3,
                maxLength: 160,
                decoration: appInputDecoration('Bio (optional)'),
                style: appBodyStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text('League region', style: GoogleFonts.chewy(fontSize: 20, color: kInkColor)),
              const SizedBox(height: 4),
              Text(
                "Which region's weekly league you compete in.",
                style: appBodyStyle(fontSize: 13, color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isSaving
                    ? null
                    : () async {
                        final picked = await pickLeagueRegion(context, current: _region);
                        if (picked != null) setState(() => _region = picked);
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColor, width: kBorderWidth),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _region == null ? 'Not set' : leagueRegionLabel(_region!),
                          style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInkColor),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: kMutedColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Change password', style: GoogleFonts.chewy(fontSize: 20, color: kInkColor)),
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
