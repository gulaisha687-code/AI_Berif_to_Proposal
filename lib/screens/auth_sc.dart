import 'package:flutter/material.dart';
import '../brand.dart';
import '../services/auth_ser.dart';
import '../widget/auth_widget.dart';
import '../widget/motion.dart';
import '../widget/toast.dart';
import 'home_sc.dart';

// One screen for both Sign in and Sign up.
class AuthScreen extends StatefulWidget {
  final bool signUp;
  const AuthScreen({super.key, required this.signUp});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      if (widget.signUp) {
        await AuthService.signUpWithEmail(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await AuthService.signInWithEmail(_email.text.trim(), _password.text);
      }
      await AuthService.markOnboarded();
      if (!mounted) return;
      Navigator.of(context)
          .pushAndRemoveUntil(fadeRoute(const HomeScreen()), (route) => false);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e.message,
        type: ToastType.error,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Something went wrong: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!_emailRe.hasMatch(email)) {
      AppToast.show(context, 'Type your email above first.', type: ToastType.info);
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      AppToast.show(
        context,
        'If that email has an account, a reset link is on its way.',
        type: ToastType.success,
        duration: const Duration(seconds: 4),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.message, type: ToastType.error);
    }
  }

  OutlineInputBorder _border(Color color, [double width = 1.4]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  InputDecoration _decoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Brand.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: _border(Brand.line),
      enabledBorder: _border(Brand.line),
      focusedBorder: _border(Brand.primary, 1.8),
      errorBorder: _border(const Color(0xFFB3261E)),
      focusedErrorBorder: _border(const Color(0xFFB3261E), 1.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signUp = widget.signUp;

    return AuthScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Brand.ink),
            ),
            const SizedBox(height: 4),
            const FadeSlide(child: BrandLogo(size: 56)),
            const SizedBox(height: 22),
            FadeSlide(
              index: 1,
              child: Text(
                signUp ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Brand.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              signUp
                  ? 'Free to start. No card needed.'
                  : 'Sign in to your proposals.',
              style: const TextStyle(fontSize: 15, color: Brand.muted),
            ),
            const SizedBox(height: 24),

            FadeSlide(
              index: 2,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (signUp) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration('Full name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email'),
                      validator: (v) => _emailRe.hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hide,
                      decoration: _decoration(
                        'Password',
                        suffix: IconButton(
                          icon: Icon(
                            _hide ? Icons.visibility_off : Icons.visibility,
                            color: Brand.muted,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'At least 6 characters'
                          : null,
                    ),
                    if (signUp) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _hide,
                        decoration: _decoration('Confirm password'),
                        validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                      ),
                    ] else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgot,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Brand.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    PillButton(
                      label: signUp ? 'Sign up' : 'Sign in',
                      loading: _loading,
                      onTap: _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const OrDivider(),
            const SizedBox(height: 16),
            FadeSlide(
              index: 3,
              child: PillButton(
                label: 'Continue with Google',
                filled: false,
                leading: const GoogleBadge(),
                onTap: () => handleGoogle(context),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    signUp ? 'Have an account? ' : 'New here? ',
                    style: const TextStyle(fontSize: 14.5, color: Brand.muted),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushReplacement(fadeRoute(AuthScreen(signUp: !signUp))),
                    child: Text(
                      signUp ? 'Sign in' : 'Sign up',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Brand.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}