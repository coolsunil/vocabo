import 'package:shared_preferences/shared_preferences.dart';

const _kGoalPresets = {25, 50, 75, 100};

int dailyGoal = 25;

int _todayCount = 0;

int get todayWordCount => _todayCount;

Future<void> loadDailyGoalStore() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getInt('daily_goal');
  if (stored != null && _kGoalPresets.contains(stored)) {
    dailyGoal = stored;
  } else {
    dailyGoal = 25;
    await prefs.setInt('daily_goal', 25);
  }
  _todayCount = prefs.getInt('daily_words_${_todayKey()}') ?? 0;
}

Future<void> setDailyGoal(int goal) async {
  dailyGoal = goal;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('daily_goal', goal);
}

Future<void> incrementDailyWords() async {
  _todayCount++;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('daily_words_${_todayKey()}', _todayCount);
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
