import 'package:flutter/material.dart';
import '../brand.dart';
import '../services/auth_ser.dart';
import '../widget/auth_widget.dart';
import '../widget/motion.dart';
import 'auth_sc.dart';
import 'home_sc.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _guest(BuildContext context) async {
    await AuthService.markOnboarded();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          children: [
            const Expanded(child: FadeSlide(child: _HeroCard())),
            const SizedBox(height: 16),
            FadeSlide(
              index: 1,
              child: PillButton(
                label: 'Create account',
                onTap: () => Navigator.of(context)
                    .push(fadeRoute(const AuthScreen(signUp: true))),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlide(
              index: 2,
              child: PillButton(
                label: 'I already have an account',
                filled: false,
                onTap: () => Navigator.of(context)
                    .push(fadeRoute(const AuthScreen(signUp: false))),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => _guest(context),
              child: const Text(
                'Continue as guest',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Brand.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The big maroon card with the headline.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Brand.mid, Brand.primary, Brand.deep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Brand.primary.withAlpha(70),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(top: -50, right: -40, child: _circle(190, const Color(0x1AFFFFFF))),
            Positioned(top: 110, left: -60, child: _circle(120, Brand.gold.withAlpha(60))),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(size: 52, glow: true),
                    const Spacer(),
                    const Text(
                      'Win more clients.\nWrite less.',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Paste a messy client brief. Get a priced, structured proposal.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}