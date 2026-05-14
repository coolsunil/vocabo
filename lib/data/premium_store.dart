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

const String _monthlyProductId = 'vocabo_premium_monthly';
const String _yearlyProductId = 'vocabo_premium_yearly';
const String _premiumExpiryKey = 'premium_expiry_date';
const String _practicePrefix = 'practice_attempts_';

// Legacy key — used only for migration
const String _legacyPremiumKey = 'premium_unlocked';

DateTime? _premiumExpiry;

bool get premiumUnlocked {
  if (_premiumExpiry == null) return false;
  return _premiumExpiry!.isAfter(DateTime.now());
}

DateTime? get premiumExpiryDate => _premiumExpiry;

Future<void> loadPremiumStore() async {
  final prefs = await SharedPreferences.getInstance();

  // Migrate existing lifetime purchasers to expiry-based model
  final legacyUnlocked = prefs.getBool(_legacyPremiumKey) ?? false;
  if (legacyUnlocked) {
    final lifetime = DateTime.now().add(const Duration(days: 36500));
    await prefs.setString(_premiumExpiryKey, lifetime.toIso8601String());
    await prefs.remove(_legacyPremiumKey);
  }

  final expiryStr = prefs.getString(_premiumExpiryKey);
  _premiumExpiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
}

Future<void> _setSubscriptionExpiry(String productId) async {
  final now = DateTime.now();
  final expiry = productId == _yearlyProductId
      ? now.add(const Duration(days: 370))
      : now.add(const Duration(days: 35));
  _premiumExpiry = expiry;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_premiumExpiryKey, expiry.toIso8601String());
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

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const String _fallbackMonthlyPrice = 'Rs 29/mo';
  static const String _fallbackYearlyPrice = 'Rs 99/yr';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  ProductDetails? _monthlyProduct;
  ProductDetails? _yearlyProduct;
  bool _storeAvailable = false;
  bool _isLoadingStore = true;
  bool _isProcessingPurchase = false;
  String? _storeMessage;
  String _selectedPlan = _yearlyProductId;

  String get _monthlyPriceLabel =>
      _monthlyProduct?.price ?? _fallbackMonthlyPrice;
  String get _yearlyPriceLabel => _yearlyProduct?.price ?? _fallbackYearlyPrice;

  String get _selectedPriceLabel =>
      _selectedPlan == _yearlyProductId ? _yearlyPriceLabel : _monthlyPriceLabel;

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
        _monthlyProduct = null;
        _yearlyProduct = null;
        _storeMessage =
            'Google Play Billing is unavailable on this device. Use a Play Store-installed build to test purchases.';
      });
      return;
    }

    final response = await _inAppPurchase
        .queryProductDetails({_monthlyProductId, _yearlyProductId});
    if (!mounted) return;

    ProductDetails? monthly;
    ProductDetails? yearly;
    for (final p in response.productDetails) {
      if (p.id == _monthlyProductId) monthly = p;
      if (p.id == _yearlyProductId) yearly = p;
    }

    setState(() {
      _storeAvailable = true;
      _isLoadingStore = false;
      _monthlyProduct = monthly;
      _yearlyProduct = yearly;
      if (response.error != null) {
        _storeMessage = response.error!.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        _storeMessage =
            'Some products not found in Play Console: ${response.notFoundIDs.join(", ")}';
      } else {
        _storeMessage = null;
      }
    });
  }

  Future<void> _startPurchase() async {
    await loadPremiumStore();
    if (premiumUnlocked) {
      _showSnackBar('Subscription is already active on this device.');
      return;
    }

    final product = _selectedPlan == _yearlyProductId
        ? _yearlyProduct
        : _monthlyProduct;

    if (product == null) {
      _showSnackBar(
        _storeMessage ??
            'Product not available yet. Check Play Console setup.',
      );
      return;
    }

    setState(() {
      _isProcessingPurchase = true;
      _storeMessage = null;
    });

    final param = PurchaseParam(productDetails: product);
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
      final isOurProduct = purchase.productID == _monthlyProductId ||
          purchase.productID == _yearlyProductId;

      if (!isOurProduct) {
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
              _storeMessage = 'Waiting for Google Play to confirm...';
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setSubscriptionExpiry(purchase.productID);
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
        title: Text('Subscription Active'),
        content: Text(
          'Google Play confirmed your subscription. Premium is now active on this device.',
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
    final isActive = premiumUnlocked;
    final expiry = premiumExpiryDate;

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
          // Header card
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
                  'Vocabo Premium',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isActive && expiry != null
                      ? 'Active until ${_formatDate(expiry)}'
                      : 'Unlock unlimited practice and smart revision.',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Plan selector (hidden when already active)
          if (!isActive) ...[
            const Text(
              'Choose a Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              id: _yearlyProductId,
              label: 'Yearly',
              price: _yearlyPriceLabel,
              badge: 'BEST VALUE',
            ),
            const SizedBox(height: 10),
            _buildPlanCard(
              id: _monthlyProductId,
              label: 'Monthly',
              price: _monthlyPriceLabel,
            ),
            const SizedBox(height: 18),
          ],

          // Features
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

          // Free limits
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

          // Store message
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

          // Subscribe button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isActive ||
                      _isLoadingStore ||
                      _isProcessingPurchase ||
                      !_storeAvailable
                  ? null
                  : _startPurchase,
              child: Text(
                isActive
                    ? 'Subscription Active'
                    : _isLoadingStore
                        ? 'Loading Google Play...'
                        : _isProcessingPurchase
                            ? 'Opening Google Play...'
                            : 'Subscribe for $_selectedPriceLabel',
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
          const SizedBox(height: 14),
          const Text(
            'Subscriptions auto-renew unless cancelled at least 24 hours before the renewal date. Manage or cancel anytime in Google Play.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Google Play Billing works only when products are created in Play Console and the app is installed through Play Store.',
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

  Widget _buildPlanCard({
    required String id,
    required String label,
    required String price,
    String? badge,
  }) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F766E)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF0F766E)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF475569),
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isSelected
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
