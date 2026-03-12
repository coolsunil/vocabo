import 'package:shared_preferences/shared_preferences.dart';

const List<String> practiceStatCategories = [
  'core',
  'synonyms',
  'idioms',
  'confusing',
  'oneword',
  'advanced',
  'mixed',
];

int getStoredBestScore(String category) => _bestScoreStore[category] ?? 0;

int getStoredBestAccuracy(String category) => _bestAccuracyStore[category] ?? 0;

int get overallBestScore {
  if (_bestScoreStore.isEmpty) return 0;
  return _bestScoreStore.values.fold(0, (max, value) => value > max ? value : max);
}

int get overallBestAccuracy {
  if (_bestAccuracyStore.isEmpty) return 0;
  return _bestAccuracyStore.values.fold(
    0,
    (max, value) => value > max ? value : max,
  );
}

final Map<String, int> _bestScoreStore = {};
final Map<String, int> _bestAccuracyStore = {};

Future<void> loadPracticeStatsStore(Iterable<String> categories) async {
  final prefs = await SharedPreferences.getInstance();
  for (final category in categories) {
    _bestScoreStore[category] = prefs.getInt(_bestScoreKey(category)) ?? 0;
    _bestAccuracyStore[category] = prefs.getInt(_bestAccuracyKey(category)) ?? 0;
  }
}

Future<void> updateBestPracticeStats(
  String category, {
  required int score,
  required int accuracy,
}) async {
  final prefs = await SharedPreferences.getInstance();

  final currentScore = _bestScoreStore[category] ?? 0;
  final currentAccuracy = _bestAccuracyStore[category] ?? 0;

  if (score > currentScore) {
    _bestScoreStore[category] = score;
    await prefs.setInt(_bestScoreKey(category), score);
  }

  if (accuracy > currentAccuracy) {
    _bestAccuracyStore[category] = accuracy;
    await prefs.setInt(_bestAccuracyKey(category), accuracy);
  }
}

String _bestScoreKey(String category) => 'practice_best_score_$category';
String _bestAccuracyKey(String category) => 'practice_best_accuracy_$category';
