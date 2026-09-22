import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';
import '../pyq_chip_row.dart';

class SynonymCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;
  final List<Map<String, dynamic>> pyqMatches;

  const SynonymCard({
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
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decor(context),
      child: Column(
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
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (!shareMode && pyqMatches.isNotEmpty)
            PyqChipRow(matches: pyqMatches),

          const SizedBox(height: 16),

          if (word.meaningEn.isNotEmpty)
            Text(
              word.meaningEn,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          if (word.meaningHi.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              word.meaningHi,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (word.synonyms.isNotEmpty) ...[
            _sectionLabel('Synonyms', isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), Icons.check_circle_outline),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.synonyms.map((s) => _chip(context, s, false)).toList(),
            ),
            const SizedBox(height: 20),
          ],

          if (word.antonyms.isNotEmpty) ...[
            _sectionLabel('Antonyms', isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), Icons.compare_arrows_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.antonyms.map((a) => _chip(context, a, true)).toList(),
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
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 10),
            Text(
              '$index/$total',
              style: TextStyle(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
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

  Widget _sectionLabel(String label, Color color, IconData icon) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ],
  );

  Widget _chip(BuildContext context, String text, bool isAntonym) {
    final isDark = context.isDark;
    final color = isAntonym
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

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
