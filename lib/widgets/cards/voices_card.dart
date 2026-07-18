import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';

class VoicesCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;

  const VoicesCard({
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
    final isDark = context.isDark;

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
                IconButton(icon: Icon(Icons.share_rounded, color: _accent), onPressed: onShare),
                IconButton(
                  icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: _accent),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
          const SizedBox(height: 4),

          _sectionLabel('Active Voice', const Color(0xFF1D4ED8), Icons.arrow_forward_rounded),
          const SizedBox(height: 8),
          _sentenceBox(
            word.word,
            background: isDark ? const Color(0xFF1D4ED8).withValues(alpha: 0.12) : const Color(0xFFEFF6FF),
            border: const Color(0xFF93C5FD),
            textColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Passive Voice', const Color(0xFF0D9488), Icons.swap_horiz_rounded),
          const SizedBox(height: 8),
          _sentenceBox(
            word.example,
            background: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.12) : const Color(0xFFF0FDFA),
            border: const Color(0xFF5EEAD4),
            textColor: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF134E4A),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          _title(context, 'Rule (Hindi)'),
          const SizedBox(height: 6),
          _explanationBox(context, word.meaningHi),

          const SizedBox(height: 16),

          _title(context, 'Rule (English)'),
          const SizedBox(height: 6),
          Text(word.meaningEn, style: const TextStyle(fontSize: 16)),

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
                style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
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
                const Text('Vocabo', style: TextStyle(color: Color(0xFF1F3C6D), fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                const Text('Build your vocabulary every day', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
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

  Widget _sentenceBox(String text, {required Color background, required Color border, required Color textColor}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
    );

  Widget _title(BuildContext context, String t) => Text(
    t,
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textSecondary),
  );

  Widget _explanationBox(BuildContext context, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: context.borderSubtle),
    ),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
  );

  BoxDecoration _decor(BuildContext context) => BoxDecoration(
    color: context.cardBg,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 8)),
    ],
  );
}
