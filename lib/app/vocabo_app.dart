import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';

class VocaboApp extends StatelessWidget {
  const VocaboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vocabo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F3C6D),
          primary: const Color(0xFF1F3C6D),
          secondary: const Color(0xFF0F766E),
          surface: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
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
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
