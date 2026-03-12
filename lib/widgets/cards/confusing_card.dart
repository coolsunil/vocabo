import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class ConfusingCard extends StatelessWidget {
  final Word word;
  final Word? pairWord;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final int index;
  final int total;

  const ConfusingCard({
    super.key,
    required this.word,
    required this.pairWord,
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
          Text(
            pairWord == null ? word.word : '${word.word}  vs  ${pairWord!.word}',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          if (pairWord != null) ...[
            _title('Pair Meanings'),
            const SizedBox(height: 10),
            _pairTile(word),
            const SizedBox(height: 10),
            _pairTile(pairWord!),
          ] else ...[
            _title("Meaning"),
            const SizedBox(height: 8),
            Text(word.meaningEn, style: const TextStyle(fontSize: 18)),

            if (word.example.isNotEmpty) ...[
              const SizedBox(height: 24),
              _title("Example"),
              const SizedBox(height: 8),
              Text(
                word.example,
                style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
              ),
            ],
          ],
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
      case 'Pair Meanings':
        return const Color(0xFF1D4ED8);
      case 'Meaning':
        return const Color(0xFF0F766E);
      case 'Example':
        return const Color(0xFFB45309);
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _pairTile(Word item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3C6D).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFFD9E2F2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.word,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          if (item.meaningHi.isNotEmpty)
            Text(
              item.meaningHi,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F3C6D),
              ),
            ),
          if (item.meaningHi.isNotEmpty) const SizedBox(height: 4),
          Text(
            item.meaningEn,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF334155),
            ),
          ),
          if (item.example.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.example,
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
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

