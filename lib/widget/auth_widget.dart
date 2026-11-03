import 'package:flutter/material.dart';
import '../brand.dart';
import '../screens/home_sc.dart';
import '../services/auth_ser.dart';
import 'motion.dart';
import 'toast.dart';

// The base of the welcome, sign-in and sign-up screens: always white,
// even when the rest of the app is in dark mode.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.light),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// A big rounded button. filled = solid maroon, otherwise white with a maroon outline.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;
  final Widget? leading;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = true,
    this.loading = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : Brand.primary;

    return Bouncy(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: filled ? Brand.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: filled ? null : Border.all(color: Brand.primary, width: 1.6),
          boxShadow: filled
              ? [
            BoxShadow(
              color: Brand.primary.withAlpha(70),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: loading ? null : onTap,
            child: Center(
              child: loading
                  ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
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

// A stand-in for the Google logo. Use Google's official asset for a real release.
class GoogleBadge extends StatelessWidget {
  const GoogleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

// A thin line with "or" in the middle.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Brand.line)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('or', style: TextStyle(color: Brand.muted)),
        ),
        Expanded(child: Divider(color: Brand.line)),
      ],
    );
  }
}

// Shared by the welcome and the sign-in/up screens.
Future<void> handleGoogle(BuildContext context) async {
  try {
    final signedIn = await AuthService.signInWithGoogle();
    if (!signedIn || !context.mounted) return; // closed the window: do nothing
    await AuthService.markOnboarded();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(fadeRoute(const HomeScreen()), (route) => false);
  } on AuthFailure catch (e) {
    if (!context.mounted) return;
    AppToast.show(
      context,
      e.message,
      type: ToastType.error,
      duration: const Duration(seconds: 4),
    );
  } catch (e) {
    if (!context.mounted) return;
    AppToast.show(context, 'Sign-in failed: $e', type: ToastType.error);
  }
}