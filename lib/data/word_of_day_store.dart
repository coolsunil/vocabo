import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/word_model.dart';

Word? wordOfDay;
int wordOfDayIndex = 0;

Future<void> loadWordOfDay() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/core_words.json');
    final list = json.decode(jsonString) as List<dynamic>;
    if (list.isEmpty) return;

    final now = DateTime.now();
    // Seed with date so the word is consistent all day but random across days
    final seed = now.year * 10000 + now.month * 100 + now.day;
    wordOfDayIndex = Random(seed).nextInt(list.length);
    wordOfDay = Word.fromJson(list[wordOfDayIndex]);
  } catch (_) {}
}
