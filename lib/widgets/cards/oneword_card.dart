import 'package:flutter/material.dart';
import '../../models/word_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/underline_example.dart';
import '../pyq_chip_row.dart';

class OneWordCard extends StatelessWidget {
  final Word word;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onShare;
  final int index;
  final int total;
  final bool shareMode;
  final List<Map<String, dynamic>> pyqMatches;

  const OneWordCard({
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

  static const _green  = Color(0xFF059669);
  static const _orange = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
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
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked
                        ? (context.isDark ? const Color(0xFF60A5FA) : const Color(0xFF1F3C6D))
                        : context.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
          const SizedBox(height: 8),
          _label('Definition', _orange),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _orange.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Text(
                word.meaningEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: Divider(color: context.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: const [
                      Icon(Icons.arrow_downward_rounded, size: 18, color: Color(0xFF94A3B8)),
                      SizedBox(height: 3),
                      Text(
                        'ONE WORD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Divider(color: context.borderSubtle)),
              ],
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _green.withValues(alpha: 0.35), width: 2),
              ),
              child: Text(
                word.word,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (!shareMode && pyqMatches.isNotEmpty)
            PyqChipRow(matches: pyqMatches),
          const SizedBox(height: 20),
          if (word.meaningHi.isNotEmpty) ...[
            _label('Hindi Meaning', context.isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                        : const Color(0xFF4338CA).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    word.meaningHi,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (word.example.isNotEmpty) ...[
            _label('Example Sentence', context.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E)),
            const SizedBox(height: 8),
            buildUnderlinedExample(
              context,
              word.example,
              [word.word],
              baseStyle: TextStyle(fontSize: 16, color: context.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
          if (!shareMode) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: context.borderSubtle),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: total == 0 ? 0.0 : index / total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: context.borderSubtle,
              color: _green,
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

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.2,
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
