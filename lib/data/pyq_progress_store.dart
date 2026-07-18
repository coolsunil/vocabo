import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final Map<String, int> _pyqProgress = {};
final Map<String, int> _pyqResumeIndex = {};
// examName → {questionIndex: selectedOptionIndex}
final Map<String, Map<int, int>> _pyqSelections = {};

Future<void> loadPYQProgressStore() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys()) {
    if (key.startsWith('pyq_progress_')) {
      final name = key.substring('pyq_progress_'.length);
      _pyqProgress[name] = prefs.getInt(key) ?? 0;
    } else if (key.startsWith('pyq_resume_')) {
      final name = key.substring('pyq_resume_'.length);
      _pyqResumeIndex[name] = prefs.getInt(key) ?? 0;
    } else if (key.startsWith('pyq_selections_')) {
      final name = key.substring('pyq_selections_'.length);
      final raw = prefs.getString(key);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _pyqSelections[name] =
            decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      }
    }
  }
}

int getPYQProgress(String examName) => _pyqProgress[examName] ?? 0;

int getPYQResumeIndex(String examName) => _pyqResumeIndex[examName] ?? 0;

Map<int, int> getPYQSelections(String examName) =>
    Map.from(_pyqSelections[examName] ?? {});

Future<void> savePYQProgress(String examName, int count) async {
  final current = _pyqProgress[examName] ?? 0;
  if (count <= current) return;
  _pyqProgress[examName] = count;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('pyq_progress_$examName', count);
}

Future<void> savePYQResumeIndex(String examName, int index) async {
  _pyqResumeIndex[examName] = index;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('pyq_resume_$examName', index);
}

Future<void> savePYQSelection(
    String examName, int questionIndex, int optionIndex) async {
  _pyqSelections[examName] ??= {};
  _pyqSelections[examName]![questionIndex] = optionIndex;
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(
    _pyqSelections[examName]!.map((k, v) => MapEntry(k.toString(), v)),
  );
  await prefs.setString('pyq_selections_$examName', encoded);
}

Future<void> clearPYQSession(String examName) async {
  _pyqResumeIndex.remove(examName);
  _pyqSelections.remove(examName);
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('pyq_resume_$examName');
  await prefs.remove('pyq_selections_$examName');
}
