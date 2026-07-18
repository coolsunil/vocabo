import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../models/word_model.dart';

Word? wordOfDay;
int wordOfDayIndex = 0;

Future<void> loadWordOfDay() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/core_words.json');
    final list = json.decode(jsonString) as List<dynamic>;
    if (list.isEmpty) return;

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    wordOfDayIndex = Random(seed).nextInt(list.length);
    wordOfDay = Word.fromJson(list[wordOfDayIndex]);

    await _pushToWidget(wordOfDay!);
  } catch (_) {}
}

Future<void> _pushToWidget(Word word) async {
  try {
    final meaning = word.meaningEn.isNotEmpty ? word.meaningEn : word.meaningHi;
    await HomeWidget.saveWidgetData<String>('widget_word', word.word);
    await HomeWidget.saveWidgetData<String>('widget_meaning', meaning);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.jarhauliyalabs.vocabo.WordOfDayWidgetProvider',
      iOSName: 'WordOfDayWidget',
    );
  } catch (_) {}
}
