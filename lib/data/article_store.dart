import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/article_model.dart';

Article? todayArticle;
bool articleReadToday = false;

Future<void> loadTodayArticle() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/gk_articles.json');
    final list = json.decode(jsonString) as List<dynamic>;
    if (list.isEmpty) return;

    // Same shuffle strategy as word-of-day: stable per year, scrambled order.
    final now = DateTime.now();
    final rng = Random(now.year * 999983 + 13);
    final indices = List.generate(list.length, (i) => i)..shuffle(rng);
    final dayOfYear = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year, 1, 1))
        .inDays;
    final idx = indices[dayOfYear % list.length];
    todayArticle = Article.fromJson(list[idx] as Map<String, dynamic>);
  } catch (_) {}
}
