import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../models/word_model.dart';

Word? wordOfDay;
int wordOfDayIndex = 0;
String _wordOfDayDate = '';

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

bool get wordOfDayIsStale => _wordOfDayDate != _todayKey();

Future<void> loadWordOfDay() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/core_words.json');
    final list = json.decode(jsonString) as List<dynamic>;
    if (list.isEmpty) return;

    final now = DateTime.now();
    // Shuffle the full list once per year using the year as seed,
    // then pick by day-of-year — gives scrambled, non-repeating order.
    final rng = Random(now.year * 1000003 + 7);
    final indices = List.generate(list.length, (i) => i)..shuffle(rng);
    final dayOfYear = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year, 1, 1))
        .inDays;
    wordOfDayIndex = indices[dayOfYear % list.length];
    wordOfDay = Word.fromJson(list[wordOfDayIndex]);
    _wordOfDayDate = _todayKey();

    await _pushToWidget(wordOfDay!);
  } catch (_) {}
}

Future<void> _pushToWidget(Word word) async {
  try {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    await HomeWidget.saveWidgetData('wod_date', dateKey);
    await HomeWidget.saveWidgetData('wod_word', word.word);
    await HomeWidget.saveWidgetData('wod_meaning_en', word.meaningEn);
    await HomeWidget.saveWidgetData('wod_meaning_hi', word.meaningHi);
    await HomeWidget.saveWidgetData('wod_example', word.example);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.jarhauliyalabs.vocabo.WordOfDayWidgetProvider',
      iOSName: 'WordOfDayWidget',
    );
  } catch (_) {}
}
