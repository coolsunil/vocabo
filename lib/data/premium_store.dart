import 'package:shared_preferences/shared_preferences.dart';

import 'bookmark_store.dart';
import 'progress_store.dart';

const int freeBookmarkLimit = 30;
const int freeReviseItemLimit = 10;
const int freePracticeAttemptsPerDay = 3;
const int freeMixedQuizAttemptsPerDay = 1;

enum PremiumFeature {
  unlimitedPractice,
  mixedQuizAccess,
  weakAreas,
  fullRevise,
  unlimitedBookmarks,
}

const Map<PremiumFeature, String> premiumFeatureTitles = {
  PremiumFeature.unlimitedPractice: 'Unlimited Practice',
  PremiumFeature.mixedQuizAccess: 'Mixed Quiz Access',
  PremiumFeature.weakAreas: 'Weak Areas Review',
  PremiumFeature.fullRevise: 'Full Revise Access',
  PremiumFeature.unlimitedBookmarks: 'Unlimited Bookmarks',
};

const Map<PremiumFeature, String> premiumFeatureDescriptions = {
  PremiumFeature.unlimitedPractice:
      'Remove daily limits from category-wise practice.',
  PremiumFeature.mixedQuizAccess:
      'Unlock unlimited Take a Quiz sessions across all categories.',
  PremiumFeature.weakAreas:
      'Review all mistaken questions and improve weak spots faster.',
  PremiumFeature.fullRevise:
      'Access saved revision content without free-tier caps.',
  PremiumFeature.unlimitedBookmarks:
      'Save as many words as you want for later revision.',
};

bool premiumUnlocked = false;

Future<void> loadPremiumStore() async {
  final prefs = await SharedPreferences.getInstance();
  premiumUnlocked = prefs.getBool(_premiumKey) ?? false;
}

Future<void> setPremiumUnlocked(bool value) async {
  premiumUnlocked = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_premiumKey, value);
}

bool hasPremiumAccess(PremiumFeature feature) {
  switch (feature) {
    case PremiumFeature.unlimitedPractice:
    case PremiumFeature.mixedQuizAccess:
    case PremiumFeature.weakAreas:
    case PremiumFeature.fullRevise:
    case PremiumFeature.unlimitedBookmarks:
      return premiumUnlocked;
  }
}

Future<int> getRemainingPracticeSessions(
  String category, {
  bool mixed = false,
}) async {
  await loadPremiumStore();
  if (premiumUnlocked) return 999;

  final prefs = await SharedPreferences.getInstance();
  final key = _dailyPracticeKey(mixed ? 'mixed' : category);
  final used = prefs.getInt(key) ?? 0;
  final limit = mixed ? freeMixedQuizAttemptsPerDay : freePracticeAttemptsPerDay;
  final remaining = limit - used;
  return remaining < 0 ? 0 : remaining;
}

Future<bool> canStartPractice(
  String category, {
  bool mixed = false,
}) async {
  return (await getRemainingPracticeSessions(category, mixed: mixed)) > 0;
}

Future<bool> consumePracticeSession(
  String category, {
  bool mixed = false,
}) async {
  await loadPremiumStore();
  if (premiumUnlocked) return true;

  final prefs = await SharedPreferences.getInstance();
  final key = _dailyPracticeKey(mixed ? 'mixed' : category);
  final used = prefs.getInt(key) ?? 0;
  final limit = mixed ? freeMixedQuizAttemptsPerDay : freePracticeAttemptsPerDay;
  if (used >= limit) return false;

  await prefs.setInt(key, used + 1);
  return true;
}

Future<int> getTotalBookmarkCount() async {
  var total = 0;
  for (final category in progressCategories) {
    total += (await loadBookmarks(category)).length;
  }
  return total;
}

Future<int> getRemainingBookmarkSlots() async {
  await loadPremiumStore();
  if (premiumUnlocked) return 999;

  final total = await getTotalBookmarkCount();
  final remaining = freeBookmarkLimit - total;
  return remaining < 0 ? 0 : remaining;
}

Future<bool> canAddBookmark() async {
  return (await getRemainingBookmarkSlots()) > 0;
}

Future<void> resetPremiumUsageState() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayStamp();
  final keysToRemove = <String>[];

  for (final key in prefs.getKeys()) {
    if (!key.startsWith(_practicePrefix)) continue;
    if (key.endsWith(today)) continue;
    keysToRemove.add(key);
  }

  for (final key in keysToRemove) {
    await prefs.remove(key);
  }
}

String _dailyPracticeKey(String bucket) =>
    '$_practicePrefix${bucket}_${_todayStamp()}';

String _todayStamp() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

const String _premiumKey = 'premium_unlocked';
const String _practicePrefix = 'practice_attempts_';
