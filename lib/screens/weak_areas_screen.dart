import 'package:flutter/material.dart';

import '../data/premium_store.dart';
import '../data/weak_areas_store.dart';
import '../models/weak_attempt.dart';

class WeakAreasScreen extends StatefulWidget {
  final String category;
  final String title;

  const WeakAreasScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<WeakAreasScreen> createState() => _WeakAreasScreenState();
}

class _WeakAreasScreenState extends State<WeakAreasScreen> {
  bool isLoading = true;
  bool isLocked = false;
  List<WeakAttempt> attempts = [];

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    await loadPremiumStore();
    if (!hasPremiumAccess(PremiumFeature.weakAreas)) {
      if (!mounted) return;
      setState(() {
        isLocked = true;
        isLoading = false;
      });
      return;
    }

    final loaded = await loadWeakAttempts(widget.category);
    if (!mounted) return;
    setState(() {
      attempts = loaded;
      isLoading = false;
      isLocked = false;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear weak areas?'),
        content: const Text(
          'This will remove all saved mistaken questions for this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await clearWeakAttempts(widget.category);
    if (!mounted) return;
    setState(() {
      attempts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C6D),
        foregroundColor: Colors.white,
        title: Text('${widget.title} - Weak Areas'),
        actions: attempts.isEmpty || isLocked
            ? null
            : [
                IconButton(
                  tooltip: 'Clear all',
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isLocked
          ? _PremiumLockedWeakAreas(onRefresh: _loadAttempts)
          : attempts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        size: 40,
                        color: Color(0xFF1F3C6D),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No weak areas yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Wrong answers from Practice will appear here for focused revision.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attempt.prompt,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnswerChip(
                        label: 'Your answer',
                        value: attempt.selectedAnswer,
                        backgroundColor: const Color(0xFFFEF2F2),
                        valueColor: const Color(0xFFB91C1C),
                      ),
                      const SizedBox(height: 8),
                      _AnswerChip(
                        label: 'Correct answer',
                        value: attempt.correctAnswer,
                        backgroundColor: const Color(0xFFF0FDF4),
                        valueColor: const Color(0xFF166534),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PremiumLockedWeakAreas extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _PremiumLockedWeakAreas({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 32,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Weak Areas is a premium feature',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock focused mistake review so you can revisit wrong answers after practice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumScreen(),
                    ),
                  ).then((_) => onRefresh());
                },
                child: const Text('View Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color valueColor;

  const _AnswerChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}


