import 'package:flutter/material.dart';
import '../data/theme_store.dart';
import '../screens/welcome_screen.dart';

class VocaboApp extends StatelessWidget {
  const VocaboApp({super.key});

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F3C6D),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF1F3C6D).withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vocabo',
        themeMode: mode,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1F3C6D),
            primary: const Color(0xFF1F3C6D),
            secondary: const Color(0xFF0F766E),
            surface: Colors.white,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
          ),
          elevatedButtonTheme: _elevatedButtonTheme,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1F3C6D),
            brightness: Brightness.dark,
            primary: const Color(0xFF3B82F6),
            secondary: const Color(0xFF0D9488),
            surface: const Color(0xFF1E293B),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF1E293B),
          ),
          elevatedButtonTheme: _elevatedButtonTheme,
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
