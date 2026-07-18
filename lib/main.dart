import 'package:flutter/material.dart';
import 'app/vocabo_app.dart';
import 'data/daily_goal_store.dart';
import 'data/progress_store.dart';
import 'data/pyq_progress_store.dart';
import 'data/streak_store.dart';
import 'data/theme_store.dart';
import 'data/word_of_day_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    loadProgressStore(),
    loadStreakStore(),
    loadWordOfDay(),
    loadDailyGoalStore(),
    loadPYQProgressStore(),
    loadThemeStore(),
  ]);
  await recordActivityToday();
  runApp(const VocaboApp());
}
