import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_sc.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5), // indigo
      brightness: Brightness.light,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // Smooth zoom-and-fade transition between screens on every platform.
    const zoom = ZoomPageTransitionsBuilder();
    const transitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: zoom,
        TargetPlatform.iOS: zoom,
        TargetPlatform.windows: zoom,
        TargetPlatform.linux: zoom,
        TargetPlatform.macOS: zoom,
        TargetPlatform.fuchsia: zoom,
      },
    );

    return MaterialApp(
      title: 'Brief to Proposal',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
        scaffoldBackgroundColor: const Color(0xFFF7F6FB),
        pageTransitionsTheme: transitions,
      ),
      home: const HomeScreen(),
    );
  }
}