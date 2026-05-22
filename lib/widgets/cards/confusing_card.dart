import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class ConfusingCard extends StatelessWidget {
  final Word word;
  final Word? pairWord;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;

  const ConfusingCard({
    super.key,
    required this.word,
    required this.pairWord,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onShare,
    required this.index,
    required this.total,
    this.shareMode = false,
  });

  static const _blue = Color(0xFF2563EB);
  static const _amber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: _decor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!shareMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Color(0xFF1F3C6D), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onShare,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: const Color(0xFF1F3C6D),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (pairWord != null) ...[
            _wordBlock(word, _blue),
            _vsChip(),
            _wordBlock(pairWord!, _amber),
          ] else ...[
            _singleLayout(),
          ],
          if (!shareMode) ...[
            const Divider(height: 32),
            LinearProgressIndicator(
              value: total == 0 ? 0.0 : index / total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$index/$total',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),
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

  Widget _singleLayout() {
    final parts = word.word.contains(' / ')
        ? word.word.split(' / ').map((e) => e.trim()).toList()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts != null && parts.length >= 2)
          _dualHeader(parts[0], parts[1])
        else
          Text(
            word.word,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        const SizedBox(height: 22),
        if (word.meaningHi.isNotEmpty) ...[
          _label('Hindi Meaning', const Color(0xFF1D4ED8)),
          const SizedBox(height: 8),
          _splitLines(
            word.meaningHi,
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F3C6D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        _label('English Meaning', const Color(0xFF0F766E)),
        const SizedBox(height: 8),
        _splitLines(
          word.meaningEn,
          const TextStyle(
            fontSize: 17,
            color: Color(0xFF334155),
            height: 1.55,
          ),
        ),
        if (word.example.isNotEmpty) ...[
          const SizedBox(height: 22),
          _label('Example', const Color(0xFFB45309)),
          const SizedBox(height: 8),
          _exampleBlock(word.example),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _splitLines(String text, TextStyle style) {
    final sep = text.contains(';') ? ';' : ', ';
    final lines = text.split(sep).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.length <= 1) return Text(text, style: style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          Text(lines[i], style: style),
          if (i < lines.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _dualHeader(String w1, String w2) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Text(
              w1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _blue,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _amber.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Text(
              w2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _amber,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wordBlock(Word item, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.word,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          if (item.meaningHi.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.meaningHi,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F3C6D),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            item.meaningEn,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          if (item.example.isNotEmpty) ...[
            const SizedBox(height: 12),
            _exampleBlock(item.example),
          ],
        ],
      ),
    );
  }

  Widget _vsChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _exampleBlock(String example) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '"$example"',
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Color(0xFF475569),
          height: 1.5,
        ),
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
