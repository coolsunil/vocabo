import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class CommonErrorCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;

  const CommonErrorCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.index,
    required this.total,
  });

  static const _accent = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Wrong sentence
          _sectionLabel('Wrong', const Color(0xFFDC2626), Icons.cancel_outlined),
          const SizedBox(height: 8),
          _sentenceBox(
            word.word,
            background: const Color(0xFFFEF2F2),
            border: const Color(0xFFFCA5A5),
            textColor: const Color(0xFF991B1B),
          ),

          const SizedBox(height: 20),

          // Correct sentence
          _sectionLabel(
            'Correct',
            const Color(0xFF16A34A),
            Icons.check_circle_outline,
          ),
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

          // Explanation
          _title('Explanation (Hindi)'),
          const SizedBox(height: 6),
          _explanationBox(word.meaningHi),

          const SizedBox(height: 16),

          _title('Explanation (English)'),
          const SizedBox(height: 6),
          Text(word.meaningEn, style: const TextStyle(fontSize: 16)),

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
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color, IconData icon) {
    return Row(
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
  }

  Widget _sentenceBox(
    String text, {
    required Color background,
    required Color border,
    required Color textColor,
  }) {
    return Container(
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
  }

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
