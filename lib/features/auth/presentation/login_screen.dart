import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/app_spacing.dart';
import '../../../shared/app_styles.dart';
import '../providers.dart';
import 'sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space28, vertical: AppSpacing.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppWordmark(),
                const SizedBox(height: AppSpacing.space24),
                Text(
                  'Log in',
                  style: appHeadlineStyle(fontSize: 34, color: kNavyColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.space24),
                TextField(
                  controller: _emailController,
                  decoration: appInputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.space12),
                TextField(
                  controller: _passwordController,
                  decoration: appInputDecoration('Password'),
                  obscureText: true,
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.space24),
                if (_errorText != null) ...[
                  AppErrorText(_errorText!),
                  const SizedBox(height: AppSpacing.space12),
                ],
                AppPrimaryButton(
                  label: 'Log in',
                  isLoading: _isLoading,
                  onPressed: _signIn,
                ),
                const SizedBox(height: AppSpacing.space8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kMutedColor),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
