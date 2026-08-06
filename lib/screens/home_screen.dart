import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/daily_goal_store.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import '../data/streak_store.dart';
import '../data/word_of_day_store.dart';
import '../services/notification_service.dart';
import '../data/theme_store.dart';
import '../utils/app_colors.dart';
import '../widgets/interactive_pressable.dart';
import 'category_detail_screen.dart';
import 'pyq_screen.dart';
import 'learn_screen.dart';
import 'onboarding_screen.dart';
import 'search_screen.dart';
import 'practice_screen.dart';
import 'donation_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _premiumLoaded = false;
  int _remainingMixedQuizSessions = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPremiumMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
      Future.delayed(const Duration(seconds: 2), initNotifications);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && wordOfDayIsStale) {
      loadWordOfDay().then((_) {
        if (mounted) setState(() {});
      });
    }
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFEA580C), size: 48),
            const SizedBox(height: 12),
            Text(
              '$current-day streak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: ctx.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: ctx.textSecondary,
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
      backgroundColor: context.scaffoldBg,
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
                  Flexible(
                    child: Text(
                      'Hello, Learner',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    const SizedBox(width: 4),
                  ],
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, mode, child) => IconButton(
                      tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
                      onPressed: toggleTheme,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        mode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: context.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Search',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.search_rounded,
                      color: context.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
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
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.settings_rounded,
                      color: context.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DailyGoalCard(onChanged: () => setState(() {})),
              const SizedBox(height: 20),

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
                    const SizedBox(height: 20),
                    Text(
                      'Explore',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.02,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ModernCategoryTile(
                          title: 'Core Vocabulary',
                          icon: Icons.auto_stories_rounded,
                          iconColor: const Color(0xFF1D4ED8),
                          backgroundColor: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFF93C5FD),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1F3C6D), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["core"] ?? 0,
                          total: 1513,
                          onTap: () => _openCategory(
                            title: 'Core Vocabulary',
                            categoryKey: "core",
                            total: 1513,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Advanced Vocabulary',
                          icon: Icons.trending_up,
                          iconColor: const Color(0xFF0D9488),
                          backgroundColor: const Color(0xFFF0FDFA),
                          borderColor: const Color(0xFF99F6E4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["advanced"] ?? 0,
                          total: 515,
                          onTap: () => _openCategory(
                            title: 'Advanced Vocabulary',
                            categoryKey: "advanced",
                            total: 515,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Antonyms & Synonyms',
                          icon: Icons.compare_arrows,
                          iconColor: const Color(0xFF059669),
                          backgroundColor: const Color(0xFFECFDF5),
                          borderColor: const Color(0xFF6EE7B7),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["synonyms"] ?? 0,
                          total: 438,
                          onTap: () => _openCategory(
                            title: 'Synonyms & Antonyms',
                            categoryKey: "synonyms",
                            total: 438,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'One-word',
                          icon: Icons.short_text,
                          iconColor: const Color(0xFFEA580C),
                          backgroundColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFDBA74),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9A3412), Color(0xFFEA580C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["oneword"] ?? 0,
                          total: 501,
                          onTap: () => _openCategory(
                            title: 'One-word Substitutions',
                            categoryKey: "oneword",
                            total: 501,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Confusing Pairs',
                          icon: Icons.warning_amber,
                          iconColor: const Color(0xFF7C3AED),
                          backgroundColor: const Color(0xFFF5F3FF),
                          borderColor: const Color(0xFFC4B5FD),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["confusing"] ?? 0,
                          total: 380,
                          onTap: () => _openCategory(
                            title: 'Confusing Words',
                            categoryKey: "confusing",
                            total: 380,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Idioms',
                          icon: Icons.format_quote,
                          iconColor: const Color(0xFFDC2626),
                          backgroundColor: const Color(0xFFFEF2F2),
                          borderColor: const Color(0xFFFCA5A5),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["idioms"] ?? 0,
                          total: 473,
                          onTap: () => _openCategory(
                            title: 'Idioms & Phrases',
                            categoryKey: "idioms",
                            total: 473,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Fixed Prepositions',
                          icon: Icons.link_rounded,
                          iconColor: const Color(0xFFD97706),
                          backgroundColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFCD34D),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF92400E), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["fixed_prepositions"] ?? 0,
                          total: 217,
                          onTap: () => _openCategory(
                            title: 'Fixed Prepositions',
                            categoryKey: "fixed_prepositions",
                            total: 217,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Phrasal Verbs',
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFFEC4899),
                          backgroundColor: const Color(0xFFFDF2F8),
                          borderColor: const Color(0xFFF9A8D4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9D174D), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["phrasal_verbs"] ?? 0,
                          total: 285,
                          onTap: () => _openCategory(
                            title: 'Phrasal Verbs',
                            categoryKey: "phrasal_verbs",
                            total: 285,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Root Words',
                          icon: Icons.account_tree_rounded,
                          iconColor: const Color(0xFF65A30D),
                          backgroundColor: const Color(0xFFF7FEE7),
                          borderColor: const Color(0xFFBEF264),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF365314), Color(0xFF65A30D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["root_words"] ?? 0,
                          total: 461,
                          onTap: () => _openCategory(
                            title: 'Root Words',
                            categoryKey: "root_words",
                            total: 461,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Common Errors',
                          icon: Icons.rule_folder_rounded,
                          iconColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFFEEF2FF),
                          borderColor: const Color(0xFFA5B4FC),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1B4B), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["common_errors"] ?? 0,
                          total: 492,
                          onTap: () => _openCategory(
                            title: 'Common Errors',
                            categoryKey: "common_errors",
                            total: 492,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Homophones',
                          icon: Icons.hearing_rounded,
                          iconColor: const Color(0xFFC026D3),
                          backgroundColor: const Color(0xFFFDF4FF),
                          borderColor: const Color(0xFFE879F9),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF701A75), Color(0xFFC026D3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["homophones"] ?? 0,
                          total: 278,
                          onTap: () => _openCategory(
                            title: 'Homophones',
                            categoryKey: "homophones",
                            total: 278,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Spellings',
                          icon: Icons.spellcheck_rounded,
                          iconColor: const Color(0xFFF97316),
                          backgroundColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFED7AA),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C2D12), Color(0xFFF97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["spellings"] ?? 0,
                          total: 250,
                          onTap: () => _openCategory(
                            title: 'Spellings',
                            categoryKey: "spellings",
                            total: 250,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Foreign Words',
                          icon: Icons.translate_rounded,
                          iconColor: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFF93C5FD),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["foreign_words"] ?? 0,
                          total: 276,
                          onTap: () => _openCategory(
                            title: 'Foreign Words',
                            categoryKey: "foreign_words",
                            total: 276,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Proverbs',
                          icon: Icons.menu_book_rounded,
                          iconColor: const Color(0xFFDB2777),
                          backgroundColor: const Color(0xFFFDF2F8),
                          borderColor: const Color(0xFFF9A8D4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF831843), Color(0xFFDB2777)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["proverbs"] ?? 0,
                          total: 145,
                          onTap: () => _openCategory(
                            title: 'Proverbs',
                            categoryKey: "proverbs",
                            total: 145,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Sentence Improvement',
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          backgroundColor: const Color(0xFFF5F3FF),
                          borderColor: const Color(0xFFC4B5FD),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E1065), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["sentence_improvement"] ?? 0,
                          total: 183,
                          onTap: () => _openCategory(
                            title: 'Sentence Improvement',
                            categoryKey: "sentence_improvement",
                            total: 183,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Cloze Test',
                          icon: Icons.article_rounded,
                          iconColor: const Color(0xFFCA8A04),
                          backgroundColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFCD34D),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF713F12), Color(0xFFCA8A04)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["cloze_test"] ?? 0,
                          total: 153,
                          onTap: () => _openCategory(
                            title: 'Cloze Test',
                            categoryKey: "cloze_test",
                            total: 153,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Active / Passive Voice',
                          icon: Icons.swap_horiz_rounded,
                          iconColor: const Color(0xFF0891B2),
                          backgroundColor: const Color(0xFFECFEFF),
                          borderColor: const Color(0xFF67E8F9),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF164E63), Color(0xFF0891B2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["voices"] ?? 0,
                          total: 228,
                          onTap: () => _openCategory(
                            title: 'Active / Passive Voice',
                            categoryKey: "voices",
                            total: 228,
                          ),
                        ),
                        _ModernCategoryTile(
                          title: 'Direct & Indirect Speech',
                          icon: Icons.record_voice_over_rounded,
                          iconColor: const Color(0xFFD97706),
                          backgroundColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFBBF24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF78350F), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          learned: progressStore["narration"] ?? 0,
                          total: 212,
                          onTap: () => _openCategory(
                            title: 'Direct & Indirect Speech',
                            categoryKey: "narration",
                            total: 212,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _QuizCategoryTile(
                      title: 'Previous Year Questions (PYQs)',
                      subtitle: 'SSC · IBPS · SBI · UPSC · CLAT · AFCAT · CSIR · Supreme Court · RBI & more',
                      gradient: const [Color(0xFF14532D), Color(0xFF16A34A)],
                      icon: Icons.fact_check_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PYQScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallActionTile(
                            title: 'Take a Quiz',
                            subtitle: !_premiumLoaded
                                ? 'All categories'
                                : premiumUnlocked
                                ? 'Unlimited access'
                                : '$_remainingMixedQuizSessions session${_remainingMixedQuizSessions == 1 ? '' : 's'} left',
                            gradient: const [Color(0xFF701A75), Color(0xFFC026D3)],
                            icon: Icons.quiz_rounded,
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
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SmallActionTile(
                            title: 'Community',
                            subtitle: 'Join on Telegram',
                            gradient: const [Color(0xFF0063A5), Color(0xFF0088CC)],
                            icon: Icons.send_rounded,
                            onTap: () async {
                              final tgUri = Uri.parse('tg://resolve?domain=vocabo_community');
                              final webUri = Uri.parse('https://t.me/vocabo_community');
                              if (await canLaunchUrl(tgUri)) {
                                await launchUrl(tgUri);
                              } else {
                                await launchUrl(webUri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _FeedbackCard(),
                    const SizedBox(height: 14),
                    const _SupportCard(),
                    const SizedBox(height: 14),
                    const _ReferralCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Made with ❤️ for Aspirants',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _DailyGoalCard extends StatelessWidget {
  final VoidCallback onChanged;

  const _DailyGoalCard({required this.onChanged});

  void _showGoalPicker(BuildContext context) {
    const presets = [25, 50, 75, 100];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.borderMedium,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Set Daily Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ctx.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How many cards do you want to learn each day?',
              style: TextStyle(fontSize: 13, color: ctx.textSecondary),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: presets.map((n) {
                final selected = n == dailyGoal;
                return GestureDetector(
                  onTap: () async {
                    await setDailyGoal(n);
                    if (ctx.mounted) Navigator.pop(ctx);
                    onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selected ? null : ctx.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(color: ctx.borderSubtle),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$n cards',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : ctx.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = todayWordCount.clamp(0, dailyGoal);
    final pct = count / dailyGoal;
    final done = count >= dailyGoal;

    const gradientStart = Color(0xFF4F46E5);
    const gradientEnd = Color(0xFF06B6D4);

    return InteractivePressable(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      overlayColor: gradientStart,
      child: Container(
        padding: const EdgeInsets.all(20),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientStart.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.rocket_launch_rounded,
                size: 110,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    const Text(
                      'Daily Goal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Complete ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (!done) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showGoalPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.tune_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Set goal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  done ? 'Great work today!' : '$count / $dailyGoal cards',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  done
                      ? 'You\'ve hit your daily target'
                      : '${dailyGoal - count} more to hit your goal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  static const Map<String, int> _totals = {
    'core': 1513, 'synonyms': 438, 'oneword': 501, 'confusing': 380,
    'idioms': 473, 'advanced': 515, 'fixed_prepositions': 217,
    'phrasal_verbs': 285, 'root_words': 461, 'common_errors': 492,
    'homophones': 278, 'spellings': 250, 'foreign_words': 276,
    'proverbs': 145, 'sentence_improvement': 183, 'cloze_test': 153,
    'voices': 228, 'narration': 212,
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
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF701A75), Color(0xFFC026D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF701A75).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_graph_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
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
                  '/ $totalWords cards',
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
  final LinearGradient? gradient;

  const _ModernCategoryTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    required this.learned,
    required this.total,
    this.gradient,
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
    final hasGradient = gradient != null;
    final titleColor = hasGradient ? Colors.white : const Color(0xFF0F172A);
    final ringFg = hasGradient ? Colors.white : iconColor;
    final ringBg = hasGradient
        ? Colors.white.withValues(alpha: 0.25)
        : borderColor.withValues(alpha: 0.5);
    final pctColor = hasGradient ? Colors.white : iconColor;
    final iconBg = hasGradient
        ? Colors.white.withValues(alpha: 0.18)
        : iconColor.withValues(alpha: 0.16);
    final iconFg = hasGradient ? Colors.white : iconColor;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: InteractivePressable(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      overlayColor: hasGradient ? Colors.white : iconColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: hasGradient ? null : backgroundColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasGradient ? Colors.transparent : borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: hasGradient
                  ? iconColor.withValues(alpha: 0.35)
                  : iconColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                icon,
                size: 86,
                color: (hasGradient ? Colors.white : iconColor)
                    .withValues(alpha: 0.10),
              ),
            ),
            Column(
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
                        color: iconBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: iconFg, size: 28),
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
                        backgroundColor: ringBg,
                        valueColor: AlwaysStoppedAnimation(ringFg),
                      ),
                      if (pct > 0)
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: pctColor,
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
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            if (learned > 0 && learned < total) ...[
              const SizedBox(height: 3),
              Text(
                'Resume · card $learned',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: titleColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
          ],
        ),
      ),
    ),
    );
  }
}

class _QuizCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color> gradient;
  final IconData icon;

  const _QuizCategoryTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient = const [Color(0xFF312E81), Color(0xFF06B6D4)],
    this.icon = Icons.quiz_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return InteractivePressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      overlayColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                icon,
                size: 90,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
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
        clipBehavior: Clip.hardEdge,
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
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 110,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Column(
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
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (word.meaningHi.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                word.meaningHi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
          ],
        ),
      ),
    );
  }
}

// ── Small Action Tile (compact square, used in rows) ─────────────────────────

class _SmallActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionTile({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractivePressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      overlayColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback & Rating Card ────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard();

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.jarhauliyalabs.vocabo';

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractivePressable(
      borderRadius: BorderRadius.circular(16),
      onTap: _openStore,
      overlayColor: Colors.white,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF92400E), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate & Feedback',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enjoying Vocabo? Leave a review on Play Store',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.80)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
            ),
            child: const Text(
              'Rate',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Support Card ──────────────────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return InteractivePressable(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DonationScreen()),
      ),
      overlayColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFBE185D), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBE185D).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Vocabo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Buy the developer a chai — keep the app free',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
              ),
              child: const Text(
                'Support',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Referral Card ─────────────────────────────────────────────────────────────

class _ReferralCard extends StatelessWidget {
  const _ReferralCard();

  static const _appLink =
      'https://play.google.com/store/apps/details?id=com.jarhauliyalabs.vocabo';

  void _share() {
    Share.share(
      '📚 Preparing for SSC, IBPS, UPSC or any competitive exam?\n\n'
      'I\'ve been using *Vocabo* to build my English vocabulary — it covers '
      'PYQs, idioms, synonyms, one-word substitutions, voice change, narration '
      'and a lot more. Really helpful for exam prep!\n\n'
      '👉 Download free: $_appLink',
      subject: 'Check out Vocabo — Vocabulary for Competitive Exams',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFF4338CA), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite Friends',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Help fellow aspirants discover Vocabo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Know someone preparing for SSC, IBPS, UPSC or any competitive exam? Share Vocabo and help them build a stronger vocabulary.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Share Vocabo',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4338CA),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '✨ One word a day. One step closer to your dream.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
