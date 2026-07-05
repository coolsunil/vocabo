import 'package:flutter/material.dart';
import '../data/bookmark_store.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import '../widgets/interactive_pressable.dart';
import 'learn_screen.dart';
import 'practice_screen.dart';
import 'revise_screen.dart';
import 'weak_areas_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String title;
  final String categoryKey;
  final int total;

  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.categoryKey,
    required this.total,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  static const Map<String, (String, String)> _learnLabels = {
    'core':                 ('Learn Words',           'Swipe through vocabulary'),
    'synonyms':             ('Learn Words',           'Swipe through vocabulary'),
    'idioms':               ('Learn Idioms',          'Swipe through idioms & phrases'),
    'confusing':            ('Learn Pairs',           'Swipe through confusing pairs'),
    'oneword':              ('Learn Substitutions',   'Swipe through one-word substitutions'),
    'advanced':             ('Learn Words',           'Swipe through vocabulary'),
    'fixed_prepositions':   ('Learn Prepositions',    'Swipe through fixed prepositions'),
    'phrasal_verbs':        ('Learn Phrasal Verbs',   'Swipe through phrasal verbs'),
    'root_words':           ('Learn Root Words',      'Swipe through root words'),
    'common_errors':        ('Study Errors',          'Learn to spot common mistakes'),
    'homophones':           ('Learn Homophones',      'Swipe through sound-alike words'),
    'spellings':            ('Learn Spellings',       'Swipe through spelling rules'),
    'foreign_words':        ('Learn Foreign Words',   'Swipe through foreign expressions'),
    'proverbs':             ('Learn Proverbs',        'Swipe through proverbs'),
    'sentence_improvement': ('Study Sentences',       'Learn to improve sentences'),
    'cloze_test':           ('Study Fill-in-Blanks',  'Swipe through cloze questions'),
    'voices':               ('Study Voice Rules',     'Active & Passive with rules'),
    'narration':            ('Study Narration Rules', 'Direct & Indirect with rules'),
  };

  static const Map<String, Color> _categoryAccents = {
    'core':                 Color(0xFF2563EB),
    'synonyms':             Color(0xFF059669),
    'antonyms':             Color(0xFF059669),
    'synonyms_antonyms':    Color(0xFF059669),
    'oneword':              Color(0xFFEA580C),
    'confusing':            Color(0xFF7C3AED),
    'idioms':               Color(0xFFDC2626),
    'advanced':             Color(0xFF0D9488),
    'fixed_prepositions':   Color(0xFFD97706),
    'phrasal_verbs':        Color(0xFFEC4899),
    'root_words':           Color(0xFF65A30D),
    'common_errors':        Color(0xFF6366F1),
    'homophones':           Color(0xFFC026D3),
    'spellings':            Color(0xFFF97316),
    'foreign_words':        Color(0xFF0284C7),
    'proverbs':             Color(0xFFDB2777),
    'sentence_improvement': Color(0xFF8B5CF6),
    'cloze_test':           Color(0xFFCA8A04),
    'voices':               Color(0xFF0891B2),
    'narration':            Color(0xFFD97706),
  };

  static const Map<String, List<Color>> _categoryGradientColors = {
    'core':                 [Color(0xFF1F3C6D), Color(0xFF2563EB)],
    'synonyms':             [Color(0xFF064E3B), Color(0xFF059669)],
    'antonyms':             [Color(0xFF064E3B), Color(0xFF059669)],
    'synonyms_antonyms':    [Color(0xFF064E3B), Color(0xFF059669)],
    'oneword':              [Color(0xFF9A3412), Color(0xFFEA580C)],
    'confusing':            [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    'idioms':               [Color(0xFF7F1D1D), Color(0xFFDC2626)],
    'advanced':             [Color(0xFF134E4A), Color(0xFF0D9488)],
    'fixed_prepositions':   [Color(0xFF92400E), Color(0xFFD97706)],
    'phrasal_verbs':        [Color(0xFF9D174D), Color(0xFFEC4899)],
    'root_words':           [Color(0xFF365314), Color(0xFF65A30D)],
    'common_errors':        [Color(0xFF1E1B4B), Color(0xFF6366F1)],
    'homophones':           [Color(0xFF701A75), Color(0xFFC026D3)],
    'spellings':            [Color(0xFF7C2D12), Color(0xFFF97316)],
    'foreign_words':        [Color(0xFF0C4A6E), Color(0xFF0284C7)],
    'proverbs':             [Color(0xFF831843), Color(0xFFDB2777)],
    'sentence_improvement': [Color(0xFF2E1065), Color(0xFF8B5CF6)],
    'cloze_test':           [Color(0xFF713F12), Color(0xFFCA8A04)],
    'voices':               [Color(0xFF164E63), Color(0xFF0891B2)],
    'narration':            [Color(0xFF78350F), Color(0xFFD97706)],
  };

  int _remainingPracticeSessions = 0;
  int _bookmarkCount = 0;
  bool _premiumLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumMeta();
  }

  Future<void> _loadPremiumMeta() async {
    await loadPremiumStore();
    await resetPremiumUsageState();
    final remaining = await getRemainingPracticeSessions(widget.categoryKey);
    final bookmarks = await loadBookmarks(widget.categoryKey);
    if (!mounted) return;
    setState(() {
      _remainingPracticeSessions = remaining;
      _bookmarkCount = bookmarks.length;
      _premiumLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learned = progressStore[widget.categoryKey] ?? 0;
    final progressValue = widget.total == 0 ? 0.0 : learned / widget.total;
    final accent = _categoryAccents[widget.categoryKey] ?? const Color(0xFF2563EB);
    final gradientColors = _categoryGradientColors[widget.categoryKey] ??
        [const Color(0xFF1F3C6D), const Color(0xFF2563EB)];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FC), Color(0xFFEAF0F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$learned completed',
                      style: const TextStyle(
                        color: Color(0xFFE6EEFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$learned / ${widget.total}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Start Learning',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              _ModernActionTile(
                icon: Icons.swipe_rounded,
                title: _learnLabels[widget.categoryKey]?.$1 ?? 'Learn Words',
                subtitle: _learnLabels[widget.categoryKey]?.$2 ?? 'Swipe through vocabulary',
                accent: accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LearnScreen(category: widget.categoryKey),
                    ),
                  ).then((_) {
                    if (mounted) {
                      setState(() {});
                      _loadPremiumMeta();
                    }
                  });
                },
              ),
              _ModernActionTile(
                icon: Icons.quiz_rounded,
                title: 'Practice',
                subtitle: !_premiumLoaded
                    ? 'Test your knowledge'
                    : premiumUnlocked
                    ? 'Unlimited practice available'
                    : '$_remainingPracticeSessions free session${_remainingPracticeSessions == 1 ? '' : 's'} left today',
                accent: accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PracticeScreen(
                        category: widget.categoryKey,
                        title: widget.title,
                      ),
                    ),
                  ).then((_) {
                    _loadPremiumMeta();
                  });
                },
              ),
              _ModernActionTile(
                icon: Icons.refresh_rounded,
                title: 'Revise',
                subtitle: !_premiumLoaded
                    ? 'Review bookmarked words'
                    : premiumUnlocked
                    ? 'Review all $_bookmarkCount bookmarked words'
                    : 'Free plan revises up to $freeReviseItemLimit saved words',
                accent: accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviseScreen(
                        category: widget.categoryKey,
                        title: widget.title,
                      ),
                    ),
                  ).then((_) => _loadPremiumMeta());
                },
              ),
              _ModernActionTile(
                icon: Icons.track_changes_rounded,
                title: 'Weak Areas',
                subtitle: premiumUnlocked
                    ? 'Review mistaken questions'
                    : 'Premium feature for focused revision',
                accent: accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeakAreasScreen(
                        category: widget.categoryKey,
                        title: widget.title,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ModernActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InteractivePressable(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        overlayColor: accent,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
