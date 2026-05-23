import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import '../data/streak_store.dart';
import '../data/word_of_day_store.dart';
import '../services/notification_service.dart';
import '../widgets/interactive_pressable.dart';
import 'category_detail_screen.dart';
import 'learn_screen.dart';
import 'onboarding_screen.dart';
import 'search_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
      Future.delayed(const Duration(seconds: 2), initNotifications);
    });
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(onDone: () => Navigator.pop(context)),
        ),
      );
    }
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

  void _showStreakSheet() {
    HapticFeedback.selectionClick();
    final best = bestStreak;
    final current = currentStreak;
    final message = current >= 30
        ? 'Legendary dedication!'
        : current >= 14
            ? 'You\'re on fire — keep it up!'
            : current >= 7
                ? 'One week strong!'
                : current >= 3
                    ? 'Great momentum!'
                    : 'Keep opening the app daily!';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFEA580C), size: 48),
            const SizedBox(height: 12),
            Text(
              '$current-day streak',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Best streak: $best day${best == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                  if (currentStreak > 0) ...[
                    GestureDetector(
                      onTap: () => _showStreakSheet(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Color(0xFFEA580C), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$currentStreak',
                              style: const TextStyle(
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    tooltip: 'Search',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF475569),
                    ),
                  ),
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
              const SizedBox(height: 24),

              const Text(
                'Explore',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: [
                    if (wordOfDay != null) ...[
                      _WordOfDayCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LearnScreen(
                                category: 'core',
                                initialIndex: wordOfDayIndex,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _OverallProgressCard(),
                    const SizedBox(height: 16),
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
                          icon: Icons.auto_stories_rounded,
                          iconColor: const Color(0xFF1D4ED8),
                          backgroundColor: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFF93C5FD),
                          learned: progressStore["core"] ?? 0,
                          total: 1438,
                          onTap: () => _openCategory(
                            title: 'Core Words',
                            categoryKey: "core",
                            total: 1438,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Antonyms & Synonyms',
                          icon: Icons.compare_arrows,
                          iconColor: const Color(0xFF0EA5E9),
                          backgroundColor: const Color(0xFFF0F9FF),
                          borderColor: const Color(0xFF7DD3FC),
                          learned: progressStore["synonyms"] ?? 0,
                          total: 208,
                          onTap: () => _openCategory(
                            title: 'Synonyms & Antonyms',
                            categoryKey: "synonyms_antonyms",
                            total: 208,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'One-word',
                          icon: Icons.short_text,
                          iconColor: const Color(0xFF059669),
                          backgroundColor: const Color(0xFFECFDF5),
                          borderColor: const Color(0xFF6EE7B7),
                          learned: progressStore["oneword"] ?? 0,
                          total: 344,
                          onTap: () => _openCategory(
                            title: 'One-word Substitutions',
                            categoryKey: "oneword",
                            total: 344,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Confusing Pairs',
                          icon: Icons.warning_amber,
                          iconColor: const Color(0xFFEA580C),
                          backgroundColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFDBA74),
                          learned: progressStore["confusing"] ?? 0,
                          total: 331,
                          onTap: () => _openCategory(
                            title: 'Confusing Words',
                            categoryKey: "confusing",
                            total: 331,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Idioms',
                          icon: Icons.format_quote,
                          iconColor: const Color(0xFF7C3AED),
                          backgroundColor: const Color(0xFFF5F3FF),
                          borderColor: const Color(0xFFC4B5FD),
                          learned: progressStore["idioms"] ?? 0,
                          total: 316,
                          onTap: () => _openCategory(
                            title: 'Idioms & Phrases',
                            categoryKey: "idioms",
                            total: 316,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Advanced',
                          icon: Icons.trending_up,
                          iconColor: const Color(0xFFB45309),
                          backgroundColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFCD34D),
                          learned: progressStore["advanced"] ?? 0,
                          total: 298,
                          onTap: () => _openCategory(
                            title: 'Advanced Vocabulary',
                            categoryKey: "advanced",
                            total: 298,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Fixed Prepositions',
                          icon: Icons.link_rounded,
                          iconColor: const Color(0xFF0F766E),
                          backgroundColor: const Color(0xFFF0FDFA),
                          borderColor: const Color(0xFF99F6E4),
                          learned: progressStore["fixed_prepositions"] ?? 0,
                          total: 150,
                          onTap: () => _openCategory(
                            title: 'Fixed Prepositions',
                            categoryKey: "fixed_prepositions",
                            total: 150,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Phrasal Verbs',
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFFBE185D),
                          backgroundColor: const Color(0xFFFDF2F8),
                          borderColor: const Color(0xFFF9A8D4),
                          learned: progressStore["phrasal_verbs"] ?? 0,
                          total: 225,
                          onTap: () => _openCategory(
                            title: 'Phrasal Verbs',
                            categoryKey: "phrasal_verbs",
                            total: 225,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Root Words',
                          icon: Icons.account_tree_rounded,
                          iconColor: const Color(0xFF7C2D12),
                          backgroundColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFDBA74),
                          learned: progressStore["root_words"] ?? 0,
                          total: 439,
                          onTap: () => _openCategory(
                            title: 'Root Words',
                            categoryKey: "root_words",
                            total: 439,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Common Errors',
                          icon: Icons.rule_folder_rounded,
                          iconColor: const Color(0xFFCA8A04),
                          backgroundColor: const Color(0xFFFEFCE8),
                          borderColor: const Color(0xFFFEF08A),
                          learned: progressStore["common_errors"] ?? 0,
                          total: 464,
                          onTap: () => _openCategory(
                            title: 'Common Errors',
                            categoryKey: "common_errors",
                            total: 464,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Homophones',
                          icon: Icons.hearing_rounded,
                          iconColor: const Color(0xFF4F46E5),
                          backgroundColor: const Color(0xFFEEF2FF),
                          borderColor: const Color(0xFFA5B4FC),
                          learned: progressStore["homophones"] ?? 0,
                          total: 264,
                          onTap: () => _openCategory(
                            title: 'Homophones',
                            categoryKey: "homophones",
                            total: 264,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Spellings',
                          icon: Icons.spellcheck_rounded,
                          iconColor: const Color(0xFF0891B2),
                          backgroundColor: const Color(0xFFECFEFF),
                          borderColor: const Color(0xFF67E8F9),
                          learned: progressStore["spellings"] ?? 0,
                          total: 220,
                          onTap: () => _openCategory(
                            title: 'Spellings',
                            categoryKey: "spellings",
                            total: 220,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Foreign Words',
                          icon: Icons.translate_rounded,
                          iconColor: const Color(0xFF9333EA),
                          backgroundColor: const Color(0xFFFDF4FF),
                          borderColor: const Color(0xFFE879F9),
                          learned: progressStore["foreign_words"] ?? 0,
                          total: 247,
                          onTap: () => _openCategory(
                            title: 'Foreign Words',
                            categoryKey: "foreign_words",
                            total: 247,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Proverbs',
                          icon: Icons.menu_book_rounded,
                          iconColor: const Color(0xFF4D7C0F),
                          backgroundColor: const Color(0xFFF7FEE7),
                          borderColor: const Color(0xFFBEF264),
                          learned: progressStore["proverbs"] ?? 0,
                          total: 118,
                          onTap: () => _openCategory(
                            title: 'Proverbs',
                            categoryKey: "proverbs",
                            total: 118,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Sentence Improvement',
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFF475569),
                          backgroundColor: const Color(0xFFF8FAFC),
                          borderColor: const Color(0xFFCBD5E1),
                          learned: progressStore["sentence_improvement"] ?? 0,
                          total: 150,
                          onTap: () => _openCategory(
                            title: 'Sentence Improvement',
                            categoryKey: "sentence_improvement",
                            total: 150,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Cloze Test',
                          icon: Icons.article_rounded,
                          iconColor: const Color(0xFFC2410C),
                          backgroundColor: const Color(0xFFFFEDD5),
                          borderColor: const Color(0xFFFED7AA),
                          learned: progressStore["cloze_test"] ?? 0,
                          total: 121,
                          onTap: () => _openCategory(
                            title: 'Cloze Test',
                            categoryKey: "cloze_test",
                            total: 121,
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

class _OverallProgressCard extends StatelessWidget {
  static const Map<String, int> _totals = {
    'core': 1438, 'synonyms': 208, 'oneword': 344, 'confusing': 331,
    'idioms': 316, 'advanced': 298, 'fixed_prepositions': 150,
    'phrasal_verbs': 225, 'root_words': 439, 'common_errors': 464,
    'homophones': 264, 'spellings': 220, 'foreign_words': 247,
    'proverbs': 118, 'sentence_improvement': 150, 'cloze_test': 121,
  };

  const _OverallProgressCard();

  @override
  Widget build(BuildContext context) {
    final totalWords = _totals.values.fold(0, (a, b) => a + b);
    final learnedWords = progressCategories.fold<int>(
      0, (sum, cat) => sum + (progressStore[cat] ?? 0),
    );
    final progress = totalWords == 0 ? 0.0 : learnedWords / totalWords;
    final categoriesStarted =
        _totals.keys.where((cat) => (progressStore[cat] ?? 0) > 0).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3C6D), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F3C6D).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Overall Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$categoriesStarted / ${_totals.length} categories',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$learnedWords',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $totalWords words',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% complete',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernCategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;
  final int learned;
  final int total;

  const _ModernCategoryTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    required this.learned,
    required this.total,
  });

  (IconData, Color)? get _milestone {
    if (total == 0 || learned == 0) return null;
    final pct = learned / total;
    if (pct >= 1.0) return (Icons.check_circle_rounded, const Color(0xFF059669));
    if (pct >= 0.75) return (Icons.emoji_events_rounded, const Color(0xFFD97706));
    if (pct >= 0.5) return (Icons.local_fire_department_rounded, const Color(0xFFEA580C));
    if (pct >= 0.25) return (Icons.star_rounded, const Color(0xFF3B82F6));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _milestone;
    final pct = total == 0 ? 0.0 : learned / total;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
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
                    if (badge != null)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: badge.$2,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(badge.$1, size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 3.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: borderColor.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation(iconColor),
                      ),
                      if (pct > 0)
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: iconColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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

class _WordOfDayCard extends StatelessWidget {
  final VoidCallback onTap;

  const _WordOfDayCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final word = wordOfDay!;
    final meaning = word.meaningEn.isNotEmpty ? word.meaningEn : word.meaningHi;

    return InteractivePressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      overlayColor: const Color(0xFFD97706),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                const Text(
                  'Word of the Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              word.word,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              meaning,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (word.example.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${word.example}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
