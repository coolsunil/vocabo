import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/premium_store.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const String _backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
  static const int _premiumAmountPaise = int.fromEnvironment(
    'PREMIUM_AMOUNT_PAISE',
    defaultValue: 19900,
  );
  static const String _premiumPlanName = 'Vocabo Premium Lifetime';

  late final Razorpay _razorpay;
  bool _isProcessingPayment = false;

  String get _formattedAmount {
    final rupees = _premiumAmountPaise / 100;
    if (rupees == rupees.roundToDouble()) {
      return rupees.toStringAsFixed(0);
    }
    return rupees.toStringAsFixed(2);
  }

  Uri _backendUri(String path) {
    final normalizedBase = _backendBaseUrl.endsWith('/')
        ? _backendBaseUrl.substring(0, _backendBaseUrl.length - 1)
        : _backendBaseUrl;
    return Uri.parse('$normalizedBase$path');
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    loadPremiumStore().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    await loadPremiumStore();
    if (premiumUnlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium is already active on this device.')),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final checkoutConfig = await _createOrder();
      final options = {
        'key': checkoutConfig['keyId'],
        'amount': checkoutConfig['amount'],
        'currency': checkoutConfig['currency'],
        'name': checkoutConfig['name'],
        'description': checkoutConfig['description'],
        'order_id': checkoutConfig['orderId'],
        'timeout': 300,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#1F3C6D',
        },
        'notes': {
          'plan': 'premium_lifetime',
          'platform': 'flutter_app',
        },
      };
      _razorpay.open(options);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _createOrder() async {
    final response = await http.post(
      _backendUri('/api/payments/create-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'plan': 'premium_lifetime'}),
    );

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        body['message']?.toString() ?? 'Unable to create payment order.',
      );
    }

    return body;
  }

  Future<bool> _verifyPayment(PaymentSuccessResponse response) async {
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    if (orderId == null || paymentId == null || signature == null) {
      throw Exception('Payment response is incomplete. Please try again.');
    }

    final verificationResponse = await http.post(
      _backendUri('/api/payments/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      }),
    );

    final body = verificationResponse.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(verificationResponse.body) as Map<String, dynamic>;

    if (verificationResponse.statusCode != 200) {
      throw Exception(
        body['message']?.toString() ??
            'Payment verification failed. Premium not unlocked.',
      );
    }

    return body['verified'] == true;
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verified = await _verifyPayment(response);
      if (!verified) {
        throw Exception('Payment verification failed. Premium not unlocked.');
      }

      await setPremiumUnlocked(true);
      if (!mounted) return;

      setState(() {
        _isProcessingPayment = false;
      });

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Premium Unlocked'),
          content: Text(
            'Payment successful. Premium is now active on this device. Payment ID: ${response.paymentId ?? 'Unavailable'}',
          ),
          actions: const [],
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message?.isNotEmpty == true
              ? response.message!
              : 'Payment was not completed.',
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External wallet selected: ${response.walletName ?? 'Unknown'}',
        ),
      ),
    );
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
                  'Vocabo Premium Lifetime',
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
                    'Lifetime access • Rs $_formattedAmount',
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
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: premiumUnlocked || _isProcessingPayment
                  ? null
                  : _startCheckout,
              child: Text(
                premiumUnlocked
                    ? 'Premium Active'
                    : _isProcessingPayment
                    ? 'Opening Razorpay...'
                    : 'Unlock Lifetime Premium for Rs $_formattedAmount',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Backend checkout is active at $_backendBaseUrl. For physical devices or public builds, pass --dart-define=BACKEND_BASE_URL=https://your-domain.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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

