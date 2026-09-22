import 'package:flutter/material.dart';

import 'home_screen.dart';

// Purple palette
const _kDark = Color(0xFF701A75);
const _kBright = Color(0xFFC026D3);
const _kLight = Color(0xFFEDD5FE);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const darkBg = Color(0xFF160728);
    return Scaffold(
      backgroundColor: isDark ? darkBg : const Color(0xFFF3E8FF),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? darkBg : null,
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFF3E8FF), Color(0xFFFAE8FF), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // App icon
                    const _AppIcon(),
                    const SizedBox(height: 36),
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? const [Color(0xFFE879F9), Color(0xFFF5D0FE)]
                            : const [_kDark, _kBright],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Vocabo',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Words that Crack Exams!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE9D5FF) : _kDark,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Feature chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _Chip(icon: Icons.layers_rounded, label: '18+ Topics', isDark: isDark),
                        _Chip(icon: Icons.grading_rounded, label: 'PYQs Included', isDark: isDark),
                        _Chip(icon: Icons.bolt_rounded, label: 'Smart Practice', isDark: isDark),
                        _Chip(icon: Icons.emoji_events_rounded, label: 'SSC · IBPS · UPSC', isDark: isDark),
                      ],
                    ),
                    const Spacer(flex: 3),
                    // CTA button
                    _StartButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No sign-up needed · Free to start',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFA78BCA) : const Color(0xFF374151),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _kBright.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _Chip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: isDark ? const Color(0xFF3B0764).withValues(alpha: 0.8) : _kLight,
        border: isDark
            ? Border.all(color: const Color(0xFF7E22CE).withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDark ? const Color(0xFFD946EF) : _kBright, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE9D5FF) : _kDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_kDark, _kBright],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kBright.withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Learning',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
