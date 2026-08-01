import 'package:flutter/material.dart';

/// Renders [sentence] as a [RichText] with every occurrence of each word
/// in [underlineWords] underlined and bold. Falls back to plain [Text] when
/// no match is found (e.g. example uses a pronoun instead of the word).
Widget buildUnderlinedExample(
  BuildContext context,
  String sentence,
  List<String> underlineWords, {
  required TextStyle baseStyle,
  TextAlign textAlign = TextAlign.start,
}) {
  final lower = sentence.toLowerCase();

  final ranges = <(int, int)>[];
  for (final w in underlineWords) {
    final wl = w.trim().toLowerCase();
    if (wl.isEmpty) continue;
    int from = 0;
    while (true) {
      final i = lower.indexOf(wl, from);
      if (i == -1) break;
      ranges.add((i, i + wl.length));
      from = i + wl.length;
    }
  }

  if (ranges.isEmpty) {
    return Text(sentence, style: baseStyle, textAlign: textAlign);
  }

  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final r in ranges) {
    if (merged.isEmpty || r.$1 >= merged.last.$2) {
      merged.add(r);
    } else {
      final last = merged.removeLast();
      merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
    }
  }

  final underlineStyle = baseStyle.copyWith(
    decoration: TextDecoration.underline,
    decorationThickness: 2,
    fontWeight: FontWeight.w700,
  );

  final spans = <TextSpan>[];
  int pos = 0;
  for (final (start, end) in merged) {
    if (pos < start) spans.add(TextSpan(text: sentence.substring(pos, start)));
    spans.add(TextSpan(text: sentence.substring(start, end), style: underlineStyle));
    pos = end;
  }
  if (pos < sentence.length) spans.add(TextSpan(text: sentence.substring(pos)));

  return RichText(
    textAlign: textAlign,
    text: TextSpan(style: baseStyle, children: spans),
  );
}
