import 'package:flutter/material.dart';
import '../screens/pyq_screen.dart';
import '../utils/app_colors.dart';

class PyqChipRow extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const PyqChipRow({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();
    final labelColor = context.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, size: 13, color: labelColor),
          const SizedBox(width: 4),
          Text(
            'Asked in',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: matches.map((m) => _chip(context, m)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, Map<String, dynamic> m) {
    final label = '${m['exam']}  ${m['year']}';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PYQScreen(
            jumpToFile: m['file'] as String,
            jumpToIndex: (m['idx'] as num).toInt(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF1F3C6D).withValues(alpha: 0.4)
              : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.isDark
                ? const Color(0xFF60A5FA).withValues(alpha: 0.45)
                : const Color(0xFF93C5FD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 11,
              color: context.isDark
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1D4ED8),
            ),
          ],
        ),
      ),
    );
  }
}
