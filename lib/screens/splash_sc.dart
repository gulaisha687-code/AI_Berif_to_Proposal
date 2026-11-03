import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../brand.dart';
import '../services/auth_ser.dart';
import 'home_sc.dart';
import 'welcome_sc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // x, y (-1 to 1), size, and a phase so each circle drifts differently.
  static const _bubbles = <List<double>>[
    [-0.85, -0.7, 120.0, 0.0],
    [0.9, -0.35, 70.0, 1.3],
    [-0.7, 0.55, 90.0, 2.4],
    [0.8, 0.75, 140.0, 3.6],
    [0.1, -0.9, 40.0, 4.8],
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _go();
  }

  Future<void> _go() async {
    final seenFuture = AuthService.hasOnboarded();
    await Future.delayed(const Duration(milliseconds: 2800));
    final seen = await seenFuture;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeRoute(seen ? const HomeScreen() : const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;
          final lift = (math.sin(t) + 1) / 2; // 0 = low, 1 = high

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B1111), Color(0xFF660000), Color(0xFF330000)],
              ),
            ),
            child: Stack(
              children: [
                // Soft circles drifting in the background.
                for (final b in _bubbles)
                  Align(
                    alignment: Alignment(
                      b[0] + 0.04 * math.sin(t + b[3]),
                      b[1] + 0.05 * math.cos(t + b[3]),
                    ),
                    child: Container(
                      width: b[2],
                      height: b[2],
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x26FFFFFF), Color(0x05FFFFFF)],
                        ),
                      ),
                    ),
                  ),

                Center(
                  child: _Entrance(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The logo floats up and down.
                        Transform.translate(
                          offset: Offset(0, -16 * lift),
                          child: const BrandLogo(size: 96, glow: true),
                        ),
                        const SizedBox(height: 26),
                        // Its shadow on the ground shrinks as the logo rises.
                        Container(
                          width: 70 - 22 * lift,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(
                              (70 - 30 * lift).round(),
                              0,
                              0,
                              0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _Wordmark(),
                      ],
                    ),
                  ),
                ),

                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Text(
                        Brand.tagline,
                        style: TextStyle(
                          color: Colors.white.withAlpha(170),
                          fontSize: 14,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Fades and scales its child in once.
class _Entrance extends StatelessWidget {
  final Widget child;
  const _Entrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.88 + 0.12 * v, child: child),
      ),
      child: child,
    );
  }
}

// The app name with a small, faint, tilted "AI" that pops in late.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          Brand.appName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Positioned(
          top: -4,
          right: -24,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1800),
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
            builder: (context, v, _) => Opacity(
              opacity: (v * 0.6).clamp(0.0, 0.6),
              child: Transform.rotate(
                angle: -0.26,
                child: Transform.scale(
                  scale: v,
                  child: Text(
                    'AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Brand.gold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}