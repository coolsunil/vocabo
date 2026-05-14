import 'package:flutter/material.dart';
import 'app/vocabo_app.dart';
import 'data/progress_store.dart';
import 'data/streak_store.dart';
import 'data/word_of_day_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    loadProgressStore(),
    loadStreakStore(),
    loadWordOfDay(),
  ]);
  await recordActivityToday();
  runApp(const VocaboApp());
}
