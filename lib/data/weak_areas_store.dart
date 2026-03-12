import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weak_attempt.dart';

String _weakAreasKey(String category) => 'weak_areas_$category';

Future<List<WeakAttempt>> loadWeakAttempts(String category) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_weakAreasKey(category)) ?? <String>[];
  return raw
      .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
      .map(WeakAttempt.fromJson)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

Future<void> saveWeakAttempt(String category, WeakAttempt attempt) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await loadWeakAttempts(category);
  final filtered = current.where((entry) => entry.prompt != attempt.prompt).toList();
  filtered.insert(0, attempt);
  final payload = filtered
      .map((entry) => jsonEncode(entry.toJson()))
      .toList(growable: false);
  await prefs.setStringList(_weakAreasKey(category), payload);
}

Future<void> clearWeakAttempts(String category) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_weakAreasKey(category));
}
