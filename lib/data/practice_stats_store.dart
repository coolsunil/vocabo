import 'package:shared_preferences/shared_preferences.dart';

const int practiceQuestionLimit = 25;

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
int getStoredAttempts(String category) => _attemptsStore[category] ?? 0;
int getStoredAverageScore(String category) {
  final attempts = _attemptsStore[category] ?? 0;
  final total = _totalScoreStore[category] ?? 0;
  if (attempts == 0) return 0;
  return (total / attempts).round();
}

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
final Map<String, int> _attemptsStore = {};
final Map<String, int> _totalScoreStore = {};

Future<void> loadPracticeStatsStore(Iterable<String> categories) async {
  final prefs = await SharedPreferences.getInstance();
  for (final category in categories) {
    _bestScoreStore[category] = prefs.getInt(_bestScoreKey(category)) ?? 0;
    _bestAccuracyStore[category] = prefs.getInt(_bestAccuracyKey(category)) ?? 0;
    _attemptsStore[category] = prefs.getInt(_attemptsKey(category)) ?? 0;
    _totalScoreStore[category] = prefs.getInt(_totalScoreKey(category)) ?? 0;
  }
}

Future<void> updateBestPracticeStats(
  String category, {
  required int score,
  required int accuracy,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // Increment attempts and accumulate total score for average
  final newAttempts = (_attemptsStore[category] ?? 0) + 1;
  final newTotal = (_totalScoreStore[category] ?? 0) + score;
  _attemptsStore[category] = newAttempts;
  _totalScoreStore[category] = newTotal;
  await prefs.setInt(_attemptsKey(category), newAttempts);
  await prefs.setInt(_totalScoreKey(category), newTotal);

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
String _attemptsKey(String category) => 'stat_attempts_$category';
String _totalScoreKey(String category) => 'stat_total_score_$category';
