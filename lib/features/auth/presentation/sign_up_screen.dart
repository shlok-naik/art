import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: kInkColor),
      child: Scaffold(
        appBar: appThemedAppBar(context, 'Sign up'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _signUpSuccess
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Check your email to confirm your account.',
                          style: GoogleFonts.chewy(fontSize: 18, color: kInkColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        AppPrimaryButton(
                          label: 'Back to login',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('SIGN UP', style: appHeadlineStyle(fontSize: 48)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: appInputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.chewy(fontSize: 16, color: kInkColor),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          decoration: appInputDecoration('Password'),
                          obscureText: true,
                          style: GoogleFonts.chewy(fontSize: 16, color: kInkColor),
                        ),
                        const SizedBox(height: 20),
                        if (_errorText != null) ...[
                          AppErrorText(_errorText!),
                          const SizedBox(height: 12),
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
      ),
    );
  }
}
