import 'package:flutter/material.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import '../widgets/interactive_pressable.dart';
import 'category_detail_screen.dart';
import 'practice_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _premiumLoaded = false;
  int _remainingMixedQuizSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadPremiumMeta();
  }

  Future<void> _loadPremiumMeta() async {
    await loadPremiumStore();
    await resetPremiumUsageState();
    final remaining = await getRemainingPracticeSessions('mixed', mixed: true);
    if (!mounted) return;
    setState(() {
      _premiumLoaded = true;
      _remainingMixedQuizSessions = remaining;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    size: 20,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hello, Learner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          setState(() {});
                          _loadPremiumMeta();
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Let's crack vocabulary!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Explore',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.02,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ModernCategoryTile(
                      title: 'Core Words',
                      subtitle: '${progressStore["core"]} / 1266 words',
                      icon: Icons.auto_stories_rounded,
                      iconColor: const Color(0xFF1D4ED8),
                      backgroundColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFF93C5FD),
                          onTap: () => _openCategory(
                            title: 'Core Words',
                            categoryKey: "core",
                            total: 1266,
                          ),
                        ),
                        _ModernCategoryTile(
                      title: 'Synonyms',
                      subtitle: '${progressStore["synonyms"] ?? 0} / 208',
                      icon: Icons.compare_arrows,
                      iconColor: const Color(0xFF0EA5E9),
                      backgroundColor: const Color(0xFFF0F9FF),
                      borderColor: const Color(0xFF7DD3FC),
                          onTap: () => _openCategory(
                            title: 'Synonyms & Antonyms',
                            categoryKey: "synonyms",
                            total: 208,
                          ),
                        ),
                        _ModernCategoryTile(
                      title: 'One-word',
                      subtitle: '${progressStore["oneword"] ?? 0} / 145',
                      icon: Icons.short_text,
                      iconColor: const Color(0xFF059669),
                      backgroundColor: const Color(0xFFECFDF5),
                      borderColor: const Color(0xFF6EE7B7),
                          onTap: () => _openCategory(
                            title: 'One-word Substitutions',
                            categoryKey: "oneword",
                            total: 145,
                          ),
                        ),
                        _ModernCategoryTile(
                      title: 'Confusing Pairs',
                      subtitle: '${progressStore["confusing"] ?? 0} / 198',
                      icon: Icons.warning_amber,
                      iconColor: const Color(0xFFEA580C),
                      backgroundColor: const Color(0xFFFFF7ED),
                      borderColor: const Color(0xFFFDBA74),
                          onTap: () => _openCategory(
                            title: 'Confusing Words',
                            categoryKey: "confusing",
                            total: 198,
                          ),
                        ),
                        _ModernCategoryTile(
                      title: 'Idioms',
                      subtitle: '${progressStore["idioms"] ?? 0} / 316',
                      icon: Icons.format_quote,
                      iconColor: const Color(0xFF7C3AED),
                      backgroundColor: const Color(0xFFF5F3FF),
                      borderColor: const Color(0xFFC4B5FD),
                          onTap: () => _openCategory(
                            title: 'Idioms & Phrases',
                            categoryKey: "idioms",
                            total: 316,
                          ),
                        ),
                        _ModernCategoryTile(
                      title: 'Advanced',
                      subtitle: '${progressStore["advanced"] ?? 0} / 298',
                      icon: Icons.trending_up,
                      iconColor: const Color(0xFFB45309),
                      backgroundColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFFCD34D),
                          onTap: () => _openCategory(
                            title: 'Advanced Vocabulary',
                            categoryKey: "advanced",
                            total: 298,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _QuizCategoryTile(
                      title: 'Take a Quiz',
                      subtitle: !_premiumLoaded
                          ? 'Practice across all categories'
                          : premiumUnlocked
                          ? 'Unlimited mixed quizzes available'
                          : '$_remainingMixedQuizSessions free mixed quiz session${_remainingMixedQuizSessions == 1 ? '' : 's'} left today',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PracticeScreen(
                              category: 'mixed',
                              title: 'Take a Quiz',
                            ),
                          ),
                        ).then((_) => _loadPremiumMeta());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory({
    required String title,
    required String categoryKey,
    required int total,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          title: title,
          categoryKey: categoryKey,
          total: total,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

class _ModernCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ModernCategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractivePressable(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      overlayColor: iconColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuizCategoryTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractivePressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      overlayColor: const Color(0xFF0F766E),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF0F766E),
            ),
          ],
        ),
      ),
    );
  }
}

