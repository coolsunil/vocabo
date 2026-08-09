import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

const _kArticlesUrl =
    'https://vocabo-9d30b.web.app/gk_articles.json';
const _kCacheKey = 'gk_articles_json';
const _kCacheDateKey = 'gk_articles_cache_date';

Article? todayArticle;
bool articleReadToday = false;
String _articleDate = '';

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

bool get articleIsStale => _articleDate != _todayKey();

Future<void> loadTodayArticle() async {
  final jsonString = await _getArticlesJson();
  if (jsonString == null) return;
  try {
    final list = json.decode(jsonString) as List<dynamic>;
    if (list.isEmpty) return;
    final now = DateTime.now();
    final dayOfYear = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year, 1, 1))
        .inDays;
    final cycle = dayOfYear ~/ list.length;
    final rng = Random(now.year * 999983 + cycle * 31337 + 13);
    final indices = List.generate(list.length, (i) => i)..shuffle(rng);
    final idx = indices[dayOfYear % list.length];
    todayArticle = Article.fromJson(list[idx] as Map<String, dynamic>);
    articleReadToday = false;
    _articleDate = _todayKey();
  } catch (_) {}
}

Future<String?> _getArticlesJson() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedDate = prefs.getString(_kCacheDateKey) ?? '';
  final today = _todayKey();

  // Return cached version if fetched today
  if (cachedDate == today) {
    final cached = prefs.getString(_kCacheKey);
    if (cached != null) return cached;
  }

  // Try fetching fresh copy from Firebase
  try {
    final response = await http
        .get(Uri.parse(_kArticlesUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final fresh = response.body;
      await prefs.setString(_kCacheKey, fresh);
      await prefs.setString(_kCacheDateKey, today);
      return fresh;
    }
  } catch (_) {}

  // Use stale cache if available
  final stale = prefs.getString(_kCacheKey);
  if (stale != null) return stale;

  // Last resort: bundled assets
  try {
    return await rootBundle.loadString('assets/data/gk_articles.json');
  } catch (_) {
    return null;
  }
}
