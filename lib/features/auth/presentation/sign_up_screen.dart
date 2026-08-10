import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/app_spacing.dart';
import '../../../shared/app_styles.dart';
import '../providers.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _signUpSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() => _signUpSuccess = true);
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
      appBar: appThemedAppBar(context, 'Sign up'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space28, vertical: AppSpacing.space28),
            child: _signUpSuccess
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Check your email to confirm your account.',
                        style: appBodyStyle(fontSize: 15, color: kMutedColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space20),
                      AppPrimaryButton(
                        label: 'Back to login',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign up',
                        style: appHeadlineStyle(fontSize: 26, color: kNavyColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.space20),
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
                        label: 'Sign up',
                        isLoading: _isLoading,
                        onPressed: _signUp,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
