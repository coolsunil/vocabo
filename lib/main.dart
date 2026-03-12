import 'package:flutter/material.dart';
import 'app/vocabo_app.dart';
import 'data/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadProgressStore();
  runApp(const VocaboApp());
}
