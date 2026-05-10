import 'package:shared_preferences/shared_preferences.dart';

int _currentStreak = 0;
DateTime? _lastActiveDate;

int get currentStreak => _currentStreak;

Future<void> loadStreakStore() async {
  final prefs = await SharedPreferences.getInstance();
  _currentStreak = prefs.getInt('streak_count') ?? 0;
  final lastStr = prefs.getString('streak_last_active');
  _lastActiveDate = lastStr != null ? DateTime.tryParse(lastStr) : null;
}

Future<void> recordActivityToday() async {
  final today = _dateOnly(DateTime.now());

  if (_lastActiveDate != null) {
    final last = _dateOnly(_lastActiveDate!);
    final diff = today.difference(last).inDays;
    if (diff == 0) return;
    _currentStreak = diff == 1 ? _currentStreak + 1 : 1;
  } else {
    _currentStreak = 1;
  }

  _lastActiveDate = today;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('streak_count', _currentStreak);
  await prefs.setString('streak_last_active', today.toIso8601String());
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
