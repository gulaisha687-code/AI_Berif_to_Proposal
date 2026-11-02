import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_sc.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemeMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    const zoom = ZoomPageTransitionsBuilder();

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF12121A)
          : const Color(0xFFF7F6FB),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Brief to Proposal',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: mode,
        home: const HomeScreen(),
      ),
    );
  }
}