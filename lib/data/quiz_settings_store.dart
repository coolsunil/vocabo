import 'package:shared_preferences/shared_preferences.dart';

const _kNegativeMarking = 'quiz_negative_marking';

bool _negativeMarkingEnabled = false;

bool get negativeMarkingEnabled => _negativeMarkingEnabled;

Future<void> loadQuizSettings() async {
  final prefs = await SharedPreferences.getInstance();
  _negativeMarkingEnabled = prefs.getBool(_kNegativeMarking) ?? false;
}

Future<void> setNegativeMarking(bool value) async {
  _negativeMarkingEnabled = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kNegativeMarking, value);
}
