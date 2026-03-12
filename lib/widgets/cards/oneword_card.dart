import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class OneWordCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final int index;
  final int total;

  const OneWordCard({
    super.key,
    required this.word,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFF1F3C6D),
              ),
              onPressed: onBookmarkToggle,
            ),
          ),
          _title("Phrase"),
          const SizedBox(height: 12),

          Text(
            word.meaningEn,
            style: const TextStyle(fontSize: 22),
          ),

          const SizedBox(height: 30),

          _title("One Word"),
          const SizedBox(height: 12),

          Text(
            word.word,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _title("Hindi Meaning"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F3C6D).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              word.meaningHi,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: total == 0 ? 0.0 : index / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF22C55E),
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
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _headingColor(t),
    ),
  );

  Color _headingColor(String title) {
    switch (title) {
      case 'Phrase':
        return const Color(0xFF0F766E);
      case 'One Word':
        return const Color(0xFF1D4ED8);
      case 'Hindi Meaning':
        return const Color(0xFF4338CA);
      default:
        return Colors.grey.shade600;
    }
  }

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

