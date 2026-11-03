import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The app's name and colours. Change them here and every screen follows.
class Brand {
  static const appName = 'Briefly';
  static const tagline = 'Brief in. Proposal out.';

  static const primary = Color(0xFF660000); // maroon
  static const mid = Color(0xFF8B1111); // lighter maroon, for gradients
  static const deep = Color(0xFF3D0000); // darker maroon
  static const gold = Color(0xFFE0A93B);
  static const accent = gold; // old name, kept so older code still works

  static const ink = Color(0xFF2A0A0A);
  static const muted = Color(0xFF7A6868);
  static const soft = Color(0xFFFBEFEF);
  static const softer = Color(0xFFF8DADA);
  static const line = Color(0xFFE6D3D3);
  static const fieldFill = Colors.white;
  static const bgLight = Color(0xFFFFFBFB);
}

// One theme for the whole app, in light and dark.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seeded =
  ColorScheme.fromSeed(seedColor: Brand.primary, brightness: brightness);

  final scheme = dark
      ? seeded.copyWith(
    primary: const Color(0xFFE58B8B), // soft rose: buttons on dark
    onPrimary: const Color(0xFF3A0000),
    primaryContainer: const Color(0xFF4A1515),
    onPrimaryContainer: const Color(0xFFFFD9D9),
    secondaryContainer: const Color(0xFF4A1A1A),
    onSecondaryContainer: const Color(0xFFFFD9D9),
    tertiary: const Color(0xFFE5B866),
  )
      : seeded.copyWith(
    primary: Brand.primary,
    onPrimary: Colors.white,
    primaryContainer: Brand.softer,
    onPrimaryContainer: Brand.primary,
    secondaryContainer: Brand.softer,
    onSecondaryContainer: Brand.deep,
    tertiary: const Color(0xFFB07A1A),
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  const zoom = ZoomPageTransitionsBuilder();

  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    scaffoldBackgroundColor:
    dark ? const Color(0xFF140B0B) : Brand.bgLight,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: zoom,
        TargetPlatform.iOS: zoom,
        TargetPlatform.windows: zoom,
        TargetPlatform.linux: zoom,
        TargetPlatform.macOS: zoom,
        TargetPlatform.fuchsia: zoom,
      },
    ),
  );
}

// A soft fade between two screens.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 450),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, animation, __, child) =>
      FadeTransition(opacity: animation, child: child),
);

// The logo: a maroon square with a document and a gold sparkle.
// glow = true adds a light border and a deeper shadow, for dark backgrounds.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool glow;

  const BrandLogo({super.key, this.size = 56, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Brand.mid, Brand.deep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.28),
              border: glow
                  ? Border.all(color: const Color(0x55FFFFFF), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: glow
                      ? const Color(0x55000000)
                      : Brand.primary.withAlpha(70),
                  blurRadius: glow ? 34 : 14,
                  offset: Offset(0, glow ? 16 : 6),
                ),
              ],
            ),
            child: Icon(
              Icons.description_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: size * 0.15,
            bottom: size * 0.15,
            child: Icon(Icons.auto_awesome, size: size * 0.26, color: Brand.gold),
          ),
        ],
      ),
    );
  }
}