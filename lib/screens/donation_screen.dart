import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_colors.dart';

// Create these as consumable (one-time) products in Google Play Console.
const _kTipIds = {'tip_rs25', 'tip_rs50', 'tip_rs75', 'tip_rs100'};
const _kTipAmounts = <String, int>{
  'tip_rs25': 25,
  'tip_rs50': 50,
  'tip_rs75': 75,
  'tip_rs100': 100,
};

// Replace with your UPI ID before releasing.
const _kUpiId = 'thelocker@ybl';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Map<String, ProductDetails> _products = {};
  String? _selectedId = 'tip_rs50';
  bool _storeAvailable = false;
  bool _isLoadingStore = true;
  bool _isProcessing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _sub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _sub?.cancel(),
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _message = 'Purchase updates unavailable. Try again.';
        });
      },
    );
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() {
      _isLoadingStore = true;
      _message = null;
    });

    final isAvailable = await _iap.isAvailable();
    if (!mounted) return;

    if (!isAvailable) {
      setState(() {
        _storeAvailable = false;
        _isLoadingStore = false;
        _message =
            'Google Play Billing unavailable. You can donate via UPI below.';
      });
      return;
    }

    final response = await _iap.queryProductDetails(_kTipIds);
    if (!mounted) return;

    final map = <String, ProductDetails>{};
    for (final p in response.productDetails) {
      map[p.id] = p;
    }

    setState(() {
      _storeAvailable = true;
      _isLoadingStore = false;
      _products = map;
      if (response.error != null) {
        _message = response.error!.message;
      } else if (response.productDetails.isEmpty &&
          response.notFoundIDs.isNotEmpty) {
        _message =
            'Donation products not yet live in Play Console: ${response.notFoundIDs.join(", ")}';
      }
    });
  }

  Future<void> _donate() async {
    if (_selectedId == null) return;

    final product = _products[_selectedId];
    if (product == null) {
      _showSnackBar(
        _message ?? 'Product not available. Check Play Console setup.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _message = null;
    });

    final started = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );

    if (!started && mounted) {
      setState(() {
        _isProcessing = false;
        _message = 'Could not open Google Play. Please try again.';
      });
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> list) async {
    var donated = false;

    for (final purchase in list) {
      if (!_kTipIds.contains(purchase.productID)) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _isProcessing = true;
              _message = 'Waiting for Google Play to confirm…';
            });
          }
        case PurchaseStatus.purchased:
          donated = true;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _message = purchase.error?.message ?? 'Payment failed.';
            });
          }
        case PurchaseStatus.canceled:
          if (mounted) setState(() => _isProcessing = false);
        case PurchaseStatus.restored:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    if (!mounted) return;
    if (donated) {
      setState(() {
        _isProcessing = false;
        _message = null;
      });
      _showThankYouDialog();
    } else {
      setState(() {});
    }
  }

  void _showThankYouDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFBE185D),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your support means the world. Every rupee goes directly into keeping Vocabo free for every exam aspirant who needs it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.55),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _donateViaUpi(int amount) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': _kUpiId,
        'pn': 'Vocabo',
        'am': '$amount',
        'cu': 'INR',
        'tn': 'Support Vocabo',
      },
    );
    try {
      var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri);
      }
      if (!launched && mounted) {
        _showSnackBar('No UPI app found on this device.');
      }
    } catch (_) {
      if (mounted) _showSnackBar('No UPI app found on this device.');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Support Vocabo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 22),
          Text(
            'Choose an amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTierGrid(),
          if (_message != null) ...[
            const SizedBox(height: 14),
            _buildMessageBanner(),
          ],
          const SizedBox(height: 18),
          _buildDonateButton(),
          const SizedBox(height: 14),
          _buildOrDivider(),
          const SizedBox(height: 14),
          Text(
            'Pay via UPI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildUpiRow(),
          const SizedBox(height: 24),
          Text(
            'No subscription. No pressure. Donate once, or never — Vocabo stays free either way.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFBE185D), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBE185D).withValues(alpha: 0.22),
            blurRadius: 18,
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep Vocabo free.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vocabo is built and maintained by one person — no team, no funding. '
            'Every exam aspirant deserves quality vocabulary preparation without paying a subscription. '
            'If this app helped you even a little, a small donation keeps it alive and growing.',
            style: TextStyle(
              color: Color(0xFFFFE4E6),
              height: 1.55,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierGrid() {
    final tiers = <(String, String, String?)>[
      ('tip_rs25', '₹25', null),
      ('tip_rs50', '₹50', 'POPULAR'),
      ('tip_rs75', '₹75', null),
      ('tip_rs100', '₹100', null),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiers.map((tier) {
        final (id, label, badge) = tier;
        final isSelected = _selectedId == id;
        return GestureDetector(
          onTap: () => setState(() => _selectedId = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFBE185D).withValues(alpha: 0.08)
                  : context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFBE185D)
                    : context.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFFBE185D)
                          : context.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBE185D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message!,
              style: const TextStyle(color: Color(0xFF92400E), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton() {
    final canDonate =
        !_isLoadingStore &&
        !_isProcessing &&
        _storeAvailable &&
        _selectedId != null;

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        icon: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.favorite_rounded, size: 20),
        label: Text(_donateButtonLabel),
        onPressed: canDonate ? _donate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBE185D),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(
            0xFFBE185D,
          ).withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: context.borderSubtle)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: context.borderSubtle)),
      ],
    );
  }

  Widget _buildUpiRow() {
    const amounts = [25, 50, 75, 100];
    return Row(
      children: List.generate(amounts.length, (i) {
        final amount = amounts[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < amounts.length - 1 ? 8 : 0),
            child: OutlinedButton(
              onPressed: () => _donateViaUpi(amount),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('₹$amount'),
            ),
          ),
        );
      }),
    );
  }

  String get _donateButtonLabel {
    if (_isLoadingStore) return 'Loading Google Play…';
    if (_isProcessing) return 'Processing…';
    if (_selectedId == null) return 'Select an amount';
    final product = _products[_selectedId!];
    if (product != null) return 'Donate ${product.price} via Google Play';
    final amount = _kTipAmounts[_selectedId!];
    return 'Donate ₹$amount via Google Play';
  }
}
