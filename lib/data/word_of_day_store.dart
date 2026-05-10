import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_model.dart';

Word? wordOfDay;

Future<void> loadWordOfDay() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/core.json');
    final list = json.decode(jsonString) as List<dynamic>;
    if (list.isEmpty) return;

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    wordOfDay = Word.fromJson(list[dayOfYear % list.length]);
  } catch (_) {}
}
