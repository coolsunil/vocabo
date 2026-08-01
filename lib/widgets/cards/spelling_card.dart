import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/underline_example.dart';

class SpellingCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;

  const SpellingCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.index,
    required this.total,
    this.shareMode = false,
  });

  static const _accent = Color(0xFF0891B2);

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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF22C55E).withValues(alpha: 0.22)
                    : const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                word.word,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (word.spellingTip.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      word.spellingTip,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _title(context, 'Hindi Meaning'),
          const SizedBox(height: 6),
          _highlight(context, word.meaningHi),

          const SizedBox(height: 20),

          _title(context, 'English Meaning'),
          const SizedBox(height: 6),
          Text(word.meaningEn, style: const TextStyle(fontSize: 18)),

          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _title(context, 'Example'),
            buildUnderlinedExample(
              context, word.example, [word.word],
              baseStyle: const TextStyle(fontSize: 17),
            ),
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
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: _headingColor(context, t),
    ),
  );

  Color _headingColor(BuildContext context, String title) {
    final dark = context.isDark;
    switch (title) {
      case 'Hindi Meaning':   return dark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
      case 'English Meaning': return dark ? const Color(0xFF22D3EE) : _accent;
      case 'Example':         return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
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
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: context.textPrimary),
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
