import 'package:shared_preferences/shared_preferences.dart';

String _bookmarkKey(String category) => 'bookmarks_$category';

Future<Set<int>> loadBookmarks(String category) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_bookmarkKey(category)) ?? <String>[];
  return raw.map(int.tryParse).whereType<int>().toSet();
}

Future<void> saveBookmarks(String category, Set<int> indices) async {
  final prefs = await SharedPreferences.getInstance();
  final values = indices.map((e) => e.toString()).toList()..sort();
  await prefs.setStringList(_bookmarkKey(category), values);
}

Future<Set<int>> toggleBookmark(String category, int index) async {
  final current = await loadBookmarks(category);
  if (current.contains(index)) {
    current.remove(index);
  } else {
    current.add(index);
  }
  await saveBookmarks(category, current);
  return current;
}

Future<void> clearAllBookmarks(Iterable<String> categories) async {
  final prefs = await SharedPreferences.getInstance();
  for (final category in categories) {
    await prefs.remove(_bookmarkKey(category));
  }
}
