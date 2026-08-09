import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/underline_example.dart';
import '../pyq_chip_row.dart';

class CoreCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;
  final List<Map<String, dynamic>> pyqMatches;

  const CoreCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.index,
    required this.total,
    this.shareMode = false,
    this.pyqMatches = const [],
  });

  @override
  Widget build(BuildContext context) {
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
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 88,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF22C55E).withValues(alpha: 0.22)
                    : const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.word,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (!shareMode && pyqMatches.isNotEmpty)
            PyqChipRow(matches: pyqMatches),
          const SizedBox(height: 24),

          _title(context, "Hindi Meaning"),
          const SizedBox(height: 6),
          _highlight(context, word.meaningHi),

          const SizedBox(height: 20),

          _title(context, "English Meaning"),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (word.partOfSpeech.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF0F766E).withValues(alpha: 0.3)
                        : const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    word.partOfSpeech,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF0F766E),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  word.meaningEn,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),

          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _title(context, "Example"),
            buildUnderlinedExample(
              context, word.example, [word.word],
              baseStyle: const TextStyle(fontSize: 17),
            ),
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
              color: const Color(0xFF22C55E),
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
      case 'English Meaning': return dark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
      case 'Example':         return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      case 'Synonyms':        return dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case 'Antonyms':        return dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      default:                return dark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    }
  }

  Widget _highlight(BuildContext context, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.isDark
          ? const Color(0xFF1F3C6D).withValues(alpha: 0.45)
          : const Color(0xFF1F3C6D).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
