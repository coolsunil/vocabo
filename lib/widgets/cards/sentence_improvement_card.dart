import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class SentenceImprovementCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;

  const SentenceImprovementCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.index,
    required this.total,
    this.shareMode = false,
  });

  static const _accent = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!shareMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.share_rounded, color: _accent),
                  onPressed: onShare,
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _accent,
                  ),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
          const SizedBox(height: 4),

          _sectionLabel('Original', const Color(0xFFD97706), Icons.error_outline_rounded),
          const SizedBox(height: 8),
          _sentenceBox(
            word.word,
            background: const Color(0xFFFFFBEB),
            border: const Color(0xFFFCD34D),
            textColor: const Color(0xFF92400E),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Improved', const Color(0xFF16A34A), Icons.check_circle_outline),
          const SizedBox(height: 8),
          _sentenceBox(
            word.example,
            background: const Color(0xFFF0FDF4),
            border: const Color(0xFF86EFAC),
            textColor: const Color(0xFF166534),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          _title('Explanation (Hindi)'),
          const SizedBox(height: 6),
          _explanationBox(word.meaningHi),

          const SizedBox(height: 16),

          _title('Explanation (English)'),
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
              backgroundColor: const Color(0xFFE2E8F0),
              color: _accent,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '$index/$total',
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE2E8F0)),
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
      Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );

  Widget _sentenceBox(
    String text, {
    required Color background,
    required Color border,
    required Color textColor,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border, width: 1.2),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );

  Widget _title(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF475569),
    ),
  );

  Widget _explanationBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );

  BoxDecoration _decor() => BoxDecoration(
    color: Colors.white,
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
