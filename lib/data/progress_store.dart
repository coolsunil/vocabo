import 'package:shared_preferences/shared_preferences.dart';

const List<String> progressCategories = [
  'core',
  'synonyms',
  'idioms',
  'confusing',
  'oneword',
  'advanced',
];

final Map<String, int> progressStore = {
  for (final category in progressCategories) category: 0,
};

Future<void> loadProgressStore() async {
  final prefs = await SharedPreferences.getInstance();
  for (final category in progressCategories) {
    progressStore[category] = prefs.getInt(_progressKey(category)) ?? 0;
  }
}

Future<void> updateProgressIfHigher(
  String category,
  int learned, {
  int? total,
}) async {
  if (!progressStore.containsKey(category)) return;

  final current = progressStore[category] ?? 0;
  final clamped = total == null ? learned : learned.clamp(0, total);

  if (clamped > current) {
    progressStore[category] = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey(category), clamped);
  }
}

Future<void> resetProgressStore() async {
  final prefs = await SharedPreferences.getInstance();
  for (final category in progressCategories) {
    progressStore[category] = 0;
    await prefs.remove(_progressKey(category));
  }
}

String _progressKey(String category) => 'progress_$category';
