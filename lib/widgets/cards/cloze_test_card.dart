import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class ClozeTestCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final int index;
  final int total;

  const ClozeTestCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.index,
    required this.total,
  });

  static const _accent = Color(0xFFC2410C);

  @override
  Widget build(BuildContext context) {
    final answer = word.example;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _accent,
              ),
              onPressed: onBookmarkToggle,
            ),
          ),
          const SizedBox(height: 4),

          // Sentence with blank
          const Text(
            'Fill in the blank',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Text(
              word.word,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Answer
          const Text(
            'Answer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _accent.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _accent,
              ),
            ),
          ),

          // Options
          if (word.options.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.options.map((opt) {
                final isAnswer = opt == answer;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAnswer
                        ? _accent.withValues(alpha: 0.10)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAnswer
                          ? _accent.withValues(alpha: 0.4)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAnswer) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: _accent,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isAnswer
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isAnswer
                              ? _accent
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

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
