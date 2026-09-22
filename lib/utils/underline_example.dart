import 'package:flutter/material.dart';

// Only skip these as phrase suffixes — they're too generic to underline alone.
const _kSkipSuffix = {'the', 'not', "don't", "doesn't", "isn't", "can't"};

// Skip these as the "first content word" of a phrase in strategy 3.
const _kStopWords = {
  'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by',
  'do', 'not', 'its', 'up', 'be', 'as', 'or', 'so',
};

/// Renders [sentence] with every occurrence of each target word underlined
/// and bold. Falls back to plain [Text] when no match survives all strategies.
///
/// Search order per target word:
///   1. Exact substring.
///   2. Phrase suffix — drop leading words one at a time, skip trivial suffixes.
///   3. Stem of first meaningful word — progressively shorter prefixes (min 3).
Widget buildUnderlinedExample(
  BuildContext context,
  String sentence,
  List<String> underlineWords, {
  required TextStyle baseStyle,
  TextAlign textAlign = TextAlign.start,
}) {
  final lower = sentence.toLowerCase();
  final raw = _findRanges(lower, underlineWords);

  if (raw.isEmpty) {
    return Text(sentence, style: baseStyle, textAlign: textAlign);
  }

  raw.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final r in raw) {
    if (merged.isEmpty || r.$1 >= merged.last.$2) {
      merged.add(r);
    } else {
      final last = merged.removeLast();
      merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
    }
  }

  final ul = baseStyle.copyWith(
    decoration: TextDecoration.underline,
    decorationThickness: 2,
    fontWeight: FontWeight.w700,
  );

  final spans = <TextSpan>[];
  int pos = 0;
  for (final (start, end) in merged) {
    if (pos < start) spans.add(TextSpan(text: sentence.substring(pos, start)));
    spans.add(TextSpan(text: sentence.substring(start, end), style: ul));
    pos = end;
  }
  if (pos < sentence.length) spans.add(TextSpan(text: sentence.substring(pos)));

  return RichText(
    textAlign: textAlign,
    text: TextSpan(style: baseStyle, children: spans),
  );
}

List<(int, int)> _findRanges(String lower, List<String> words) {
  final ranges = <(int, int)>[];
  for (final w in words) {
    final wl = w.trim().toLowerCase();
    if (wl.isEmpty) continue;

    // 1. Exact substring
    var hits = _searchAll(lower, wl);
    if (hits.isNotEmpty) { ranges.addAll(hits); continue; }

    final parts = wl.split(' ').where((p) => p.isNotEmpty).toList();

    if (parts.length > 1) {
      // 2. Phrase suffix: drop leading words one by one
      //    Min length 2 so particles like "in", "up", "on" are tried.
      bool found = false;
      for (int i = 1; i < parts.length && !found; i++) {
        final suffix = parts.sublist(i).join(' ');
        if (suffix.length < 2 || _kSkipSuffix.contains(suffix)) continue;
        hits = _searchAll(lower, suffix);
        if (hits.isNotEmpty) { ranges.addAll(hits); found = true; }
      }
      if (found) continue;

      // 3. Stem of first meaningful word in phrase
      for (final part in parts) {
        if (_kStopWords.contains(part) || part.length < 2) continue;
        hits = _stemSearch(lower, part);
        if (hits.isNotEmpty) { ranges.addAll(hits); break; }
      }
    } else {
      // 3. Single-word stem match
      hits = _stemSearch(lower, wl);
      ranges.addAll(hits);
    }
  }
  return ranges;
}

List<(int, int)> _searchAll(String haystack, String needle) {
  final result = <(int, int)>[];
  int from = 0;
  while (true) {
    final i = haystack.indexOf(needle, from);
    if (i == -1) break;
    result.add((i, i + needle.length));
    from = i + needle.length;
  }
  return result;
}

/// Tries progressively shorter prefixes (down to min 3 chars, inclusive of the
/// full word) so inflected forms like "bifurcating" match "bifurcat",
/// "acting" matches "act", "died" matches "die".
List<(int, int)> _stemSearch(String haystack, String word) {
  final maxLen = word.length;
  final minLen = maxLen < 3 ? maxLen : 3;
  for (int n = maxLen; n >= minLen; n--) {
    final stem = word.substring(0, n);
    final hits = _searchAll(haystack, stem);
    if (hits.isNotEmpty) return hits;
  }
  return [];
}
