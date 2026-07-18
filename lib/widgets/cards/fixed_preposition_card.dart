import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';

class FixedPrepositionCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;

  const FixedPrepositionCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.index,
    required this.total,
    this.shareMode = false,
  });

  static const _accent = Color(0xFF0F766E);

  static const _prepositions = {
    'of', 'to', 'for', 'with', 'on', 'at', 'from', 'by', 'about', 'in',
    'into', 'after', 'against', 'among', 'off', 'over', 'through', 'up',
    'across', 'around', 'between', 'beyond', 'down', 'during', 'out',
    'toward', 'towards', 'under', 'upon', 'within', 'without', 'near',
  };

  List<String> _splitWord() {
    final parts = word.word.split(' ');
    for (int i = 0; i < parts.length; i++) {
      if (_prepositions.contains(parts[i].toLowerCase())) {
        return [
          parts.sublist(0, i).join(' '),
          parts.sublist(i).join(' '),
        ];
      }
    }
    return [word.word, ''];
  }

  @override
  Widget build(BuildContext context) {
    final split = _splitWord();
    final base = split[0];
    final prep = split[1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!shareMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.share_rounded, color: context.textSecondary),
                  onPressed: onShare,
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? (context.isDark ? const Color(0xFF60A5FA) : const Color(0xFF1F3C6D))
                        : context.textSecondary,
                  ),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
          const SizedBox(height: 8),

          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (base.isNotEmpty)
                  Text(base, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                if (prep.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1.2),
                    ),
                    child: Text(
                      prep,
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: _accent),
                    ),
                  ),
                if (base.isEmpty && prep.isEmpty)
                  Text(word.word, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _title(context, "Hindi Meaning"),
          const SizedBox(height: 6),
          _highlight(context, word.meaningHi),

          const SizedBox(height: 20),

          _title(context, "English Meaning"),
          const SizedBox(height: 6),
          Text(word.meaningEn, style: const TextStyle(fontSize: 18)),

          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _title(context, "Example"),
            Text(word.example, style: const TextStyle(fontSize: 17)),
          ],

          if (word.synonyms.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _title(context, "Synonyms"),
            Text(word.synonyms.join(', '), style: const TextStyle(fontSize: 17)),
          ],

          if (word.antonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            _title(context, "Antonyms"),
            Text(word.antonyms.join(', '), style: const TextStyle(fontSize: 17)),
          ],

          if (!shareMode) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0.0 : index / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: context.borderSubtle,
              color: _accent,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '$index/$total',
                style: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Divider(color: context.borderSubtle),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('assets/images/app_icon.png', width: 20, height: 20, fit: BoxFit.cover),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Vocabo',
                  style: TextStyle(
                    color: Color(0xFF1F3C6D),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Build your vocabulary every day',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _title(BuildContext context, String t) => Text(
    t,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _headingColor(context, t),
    ),
  );

  Color _headingColor(BuildContext context, String title) {
    final dark = context.isDark;
    switch (title) {
      case 'Hindi Meaning':   return dark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
      case 'English Meaning': return dark ? const Color(0xFF2DD4BF) : _accent;
      case 'Example':         return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      case 'Synonyms':        return dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case 'Antonyms':        return dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      default:                return dark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    }
  }

  Widget _highlight(BuildContext context, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: context.isDark ? 0.22 : 0.07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.textPrimary),
    ),
  );

  BoxDecoration _decor(BuildContext context) => BoxDecoration(
    color: context.cardBg,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
