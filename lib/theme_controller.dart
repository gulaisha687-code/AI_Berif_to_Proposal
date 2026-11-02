import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The current theme choice. The app listens to this and rebuilds when it changes.
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

// Card colour that works in both light and dark mode.
Color cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F1F2B)
        : Colors.white;

Future<void> loadThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString('theme_mode')) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }
  } catch (_) {
    // Keep the default if saved settings can't be read.
  }
}

Future<void> setThemeMode(ThemeMode mode) async {
  themeMode.value = mode;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  } catch (_) {}
}

// The small icon button that opens the Light / Dark / Follow phone menu.
class ThemeMenuButton extends StatelessWidget {
  const ThemeMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: const Icon(Icons.brightness_6_outlined),
      onSelected: setThemeMode,
      itemBuilder: (_) => const [
        PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
        PopupMenuItem(value: ThemeMode.system, child: Text('Follow phone')),
      ],
    );
  }
}