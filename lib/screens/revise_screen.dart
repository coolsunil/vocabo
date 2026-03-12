import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/bookmark_store.dart';
import '../data/category_sources.dart';
import '../data/premium_store.dart';
import '../models/word_model.dart';
import 'learn_screen.dart';
import 'premium_screen.dart';

class ReviseScreen extends StatefulWidget {
  final String category;
  final String title;

  const ReviseScreen({super.key, required this.category, required this.title});

  @override
  State<ReviseScreen> createState() => _ReviseScreenState();
}

class _ReviseScreenState extends State<ReviseScreen> {
  bool isLoading = true;
  List<Word> bookmarkedWords = [];
  int totalBookmarkedCount = 0;
  Set<int> bookmarkedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarkedWords();
  }

  Future<void> _loadBookmarkedWords() async {
    await loadPremiumStore();
    final path = categoryFiles[widget.category];
    if (path == null) {
      setState(() => isLoading = false);
      return;
    }

    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString) as List<dynamic>;
    final words = jsonData.map((e) => Word.fromJson(e)).toList();
    final indices = await loadBookmarks(widget.category);
    final filtered = <Word>[];

    for (final idx in indices.toList()..sort()) {
      if (idx >= 0 && idx < words.length) {
        filtered.add(words[idx]);
      }
    }

    final visibleWords = hasPremiumAccess(PremiumFeature.fullRevise)
        ? filtered
        : filtered.take(freeReviseItemLimit).toList();

    if (!mounted) return;
    setState(() {
      bookmarkedIndices = indices;
      totalBookmarkedCount = filtered.length;
      bookmarkedWords = visibleWords;
      isLoading = false;
    });
  }

  Future<void> _removeBookmark(int localIndex) async {
    final sorted = bookmarkedIndices.toList()..sort();
    final originalIndex = sorted[localIndex];
    final updated = Set<int>.from(bookmarkedIndices)..remove(originalIndex);
    await saveBookmarks(widget.category, updated);
    await _loadBookmarkedWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C6D),
        foregroundColor: Colors.white,
        title: Text('${widget.title} - Revise'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedWords.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F3C6D).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 32,
                          color: Color(0xFF1F3C6D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No bookmarks yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bookmark words while learning and they will appear here for quick revision.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LearnScreen(category: widget.category),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F3C6D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Go to Learn'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!hasPremiumAccess(PremiumFeature.fullRevise) &&
                    totalBookmarkedCount > freeReviseItemLimit) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free revise limit reached',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You can revise the first $freeReviseItemLimit bookmarked words on the free plan. Upgrade to access all $totalBookmarkedCount saved words.',
                          style: const TextStyle(
                            color: Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PremiumScreen(),
                              ),
                            ).then((_) => _loadBookmarkedWords());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F3C6D),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Unlock Full Revise'),
                        ),
                      ],
                    ),
                  ),
                ],
                ...List.generate(bookmarkedWords.length, (index) {
                  final word = bookmarkedWords[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                word.word,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.bookmark_remove_rounded,
                                color: Color(0xFF1F3C6D),
                              ),
                              onPressed: () => _removeBookmark(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (word.meaningHi.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F3C6D).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              word.meaningHi,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          word.meaningEn,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
