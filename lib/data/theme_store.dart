import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> loadThemeStore() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme_mode');
  if (saved == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (saved == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    // First launch — default to dark and persist so it sticks
    themeNotifier.value = ThemeMode.dark;
    await prefs.setString('theme_mode', 'dark');
  }
}

Future<void> toggleTheme() async {
  final next = themeNotifier.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
  themeNotifier.value = next;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', next == ThemeMode.dark ? 'dark' : 'light');
}
