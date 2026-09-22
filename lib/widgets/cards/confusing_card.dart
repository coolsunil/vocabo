import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/underline_example.dart';

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

  static const _blueDark   = Color(0xFF93C5FD);
  static const _blueLight  = Color(0xFF2563EB);
  static const _amberDark  = Color(0xFFFCD34D);
  static const _amberLight = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final blue  = isDark ? _blueDark  : _blueLight;
    final amber = isDark ? _amberDark : _amberLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: _decor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!shareMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.share_rounded, color: context.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onShare,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1F3C6D))
                        : context.textSecondary,
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
            _wordBlock(context, word, blue),
            _vsChip(context),
            _wordBlock(context, pairWord!, amber),
          ] else ...[
            _singleLayout(context, blue, amber),
          ],
          if (!shareMode) ...[
            const Divider(height: 32),
            LinearProgressIndicator(
              value: total == 0 ? 0.0 : index / total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: context.borderSubtle,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$index/$total',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Divider(color: context.borderSubtle),
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

  Widget _singleLayout(BuildContext context, Color blue, Color amber) {
    final parts = word.word.contains(' / ')
        ? word.word.split(' / ').map((e) => e.trim()).toList()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts != null && parts.length >= 2)
          _dualHeader(parts[0], parts[1], blue, amber)
        else
          Text(
            word.word,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
        const SizedBox(height: 22),
        if (word.meaningHi.isNotEmpty) ...[
          _label('Hindi Meaning', context.isDark ? const Color(0xFF818CF8) : const Color(0xFF1D4ED8)),
          const SizedBox(height: 8),
          _splitLines(
            word.meaningHi,
            TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        _label('English Meaning', context.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E)),
        const SizedBox(height: 8),
        _splitLines(
          word.meaningEn,
          TextStyle(
            fontSize: 17,
            color: context.textSecondary,
            height: 1.55,
          ),
        ),
        if (word.example.isNotEmpty) ...[
          const SizedBox(height: 22),
          _label('Example', context.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
          const SizedBox(height: 8),
          _exampleBlock(context, word.example, _underlineWords(word)),
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

  Widget _dualHeader(String w1, String w2, Color blue, Color amber) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: blue.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Text(
              w1,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: blue),
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
              color: amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: amber.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Text(
              w2,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: amber),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wordBlock(BuildContext context, Word item, Color accent) {
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent),
          ),
          if (item.meaningHi.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.meaningHi,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            item.meaningEn,
            style: TextStyle(fontSize: 16, color: context.textSecondary, height: 1.5),
          ),
          if (item.example.isNotEmpty) ...[
            const SizedBox(height: 12),
            _exampleBlock(context, item.example, _underlineWords(item)),
          ],
        ],
      ),
    );
  }

  Widget _vsChip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: context.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.borderMedium),
          ),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.textSecondary,
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

  List<String> _underlineWords(Word item) {
    if (item.confusionWith.isNotEmpty) return item.confusionWith;
    final parts = item.word.split(' / ');
    return parts.length > 1 ? parts.map((p) => p.trim()).toList() : [item.word];
  }

  Widget _exampleBlock(BuildContext context, String example, List<String> underlineWords) {
    final style = TextStyle(
      fontSize: 16,
      fontStyle: FontStyle.italic,
      color: context.textSecondary,
      height: 1.5,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderSubtle),
      ),
      child: buildUnderlinedExample(
        context, '"$example"', underlineWords,
        baseStyle: style,
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
