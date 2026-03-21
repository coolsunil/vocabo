import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const String _productId = 'vocabo_premium_lifetime';
  static const String _premiumPlanName = 'Vocabo Premium Lifetime';
  static const String _fallbackPriceLabel = 'Rs 199';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  ProductDetails? _premiumProduct;
  bool _storeAvailable = false;
  bool _isLoadingStore = true;
  bool _isProcessingPurchase = false;
  String? _storeMessage;

  String get _priceLabel => _premiumProduct?.price ?? _fallbackPriceLabel;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isProcessingPurchase = false;
          _storeMessage = 'Purchase updates are temporarily unavailable.';
        });
      },
    );

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await loadPremiumStore();
    await _loadStore();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadStore() async {
    setState(() {
      _isLoadingStore = true;
      _storeMessage = null;
    });

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!mounted) return;

    if (!isAvailable) {
      setState(() {
        _storeAvailable = false;
        _isLoadingStore = false;
        _premiumProduct = null;
        _storeMessage =
            'Google Play Billing is unavailable on this device. Use a Play Store-installed build to test purchases.';
      });
      return;
    }

    final response = await _inAppPurchase.queryProductDetails({_productId});
    if (!mounted) return;

    setState(() {
      _storeAvailable = true;
      _isLoadingStore = false;
      _premiumProduct = response.productDetails.isNotEmpty
          ? response.productDetails.first
          : null;
      if (response.error != null) {
        _storeMessage = response.error!.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        _storeMessage =
            'Play Console product not found. Create a non-consumable product with ID $_productId.';
      } else {
        _storeMessage = null;
      }
    });
  }

  Future<void> _startPurchase() async {
    await loadPremiumStore();
    if (premiumUnlocked) {
      _showSnackBar('Premium is already active on this device.');
      return;
    }

    if (_premiumProduct == null) {
      _showSnackBar(
        _storeMessage ??
            'Premium product is not available yet. Check Play Console setup.',
      );
      return;
    }

    setState(() {
      _isProcessingPurchase = true;
      _storeMessage = null;
    });

    final param = PurchaseParam(productDetails: _premiumProduct!);
    final purchaseStarted = await _inAppPurchase.buyNonConsumable(
      purchaseParam: param,
    );

    if (!purchaseStarted && mounted) {
      setState(() {
        _isProcessingPurchase = false;
        _storeMessage = 'Google Play could not start the purchase flow.';
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (!_storeAvailable) {
      _showSnackBar('Google Play Billing is unavailable on this device.');
      return;
    }

    setState(() {
      _isProcessingPurchase = true;
      _storeMessage = null;
    });

    await _inAppPurchase.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    var unlockedInThisBatch = false;

    for (final purchase in purchaseDetailsList) {
      if (purchase.productID != _productId) {
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _isProcessingPurchase = true;
              _storeMessage = 'Waiting for Google Play to confirm the purchase...';
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await setPremiumUnlocked(true);
          unlockedInThisBatch = true;
          break;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _isProcessingPurchase = false;
              _storeMessage = purchase.error?.message ?? 'Purchase failed.';
            });
          }
          break;
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _isProcessingPurchase = false;
              _storeMessage = 'Purchase cancelled.';
            });
          }
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }

    if (!mounted) return;

    if (unlockedInThisBatch) {
      setState(() {
        _isProcessingPurchase = false;
        _storeMessage = null;
      });
      await _showSuccessAndClose();
      return;
    }

    setState(() {});
  }

  Future<void> _showSuccessAndClose() async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Premium Unlocked'),
        content: Text(
          'Google Play confirmed your purchase. Premium is now active on this device.',
        ),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
    Navigator.pop(context, true);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = PremiumFeature.values;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Premium'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF1F3C6D), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F3C6D).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  _premiumPlanName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  premiumUnlocked
                      ? 'Premium is unlocked on this device.'
                      : 'One-time payment. Unlock unlimited practice and smart revision.',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Lifetime access • $_priceLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Included Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(_buildFeatureTile),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Free Plan Limits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bookmarks: up to $freeBookmarkLimit saved words',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Category Practice: $freePracticeAttemptsPerDay sessions per day',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Take a Quiz: $freeMixedQuizAttemptsPerDay session per day',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Revise: up to $freeReviseItemLimit bookmarked words visible',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          if (_storeMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _storeMessage!,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: premiumUnlocked ||
                      _isLoadingStore ||
                      _isProcessingPurchase ||
                      !_storeAvailable
                  ? null
                  : _startPurchase,
              child: Text(
                premiumUnlocked
                    ? 'Premium Active'
                    : _isLoadingStore
                        ? 'Loading Google Play...'
                        : _isProcessingPurchase
                            ? 'Opening Google Play...'
                            : 'Unlock Lifetime Premium for $_priceLabel',
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _isLoadingStore || _isProcessingPurchase || !_storeAvailable
                ? null
                : _restorePurchases,
            child: const Text('Restore Purchase'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Google Play Billing works only when this product is created in Play Console and the app is tested through a Play-supported build.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(PremiumFeature feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premiumFeatureTitles[feature]!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  premiumFeatureDescriptions[feature]!,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

