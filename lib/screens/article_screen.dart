import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../data/article_store.dart';
import '../models/article_model.dart';
import '../utils/app_colors.dart';

class ArticleScreen extends StatefulWidget {
  final Article article;

  const ArticleScreen({super.key, required this.article});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final _scrollCtrl = ScrollController();
  final _recognizers = <TapGestureRecognizer>[];
  bool _hasFinishedReading = false;
  double _readProgress = 0;

  static const _highlightColor = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    setState(() {
      _readProgress = progress;
      if (progress >= 0.92) _hasFinishedReading = true;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  List<TextSpan> _buildArticleSpans(BuildContext context) {
    final text = widget.article.body;
    final lower = text.toLowerCase();

    // Collect all match ranges
    final markers = <(int, int, HighlightedWord)>[];
    for (final hw in widget.article.highlightedWords) {
      final needle = hw.word.toLowerCase();
      int from = 0;
      while (true) {
        final i = lower.indexOf(needle, from);
        if (i == -1) break;
        markers.add((i, i + hw.word.length, hw));
        from = i + hw.word.length;
      }
    }
    markers.sort((a, b) => a.$1.compareTo(b.$1));

    final baseStyle = TextStyle(
      fontSize: 16,
      height: 1.75,
      color: context.textPrimary,
    );
    final hlStyle = baseStyle.copyWith(
      color: _highlightColor,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: _highlightColor.withValues(alpha: 0.5),
    );

    final spans = <TextSpan>[];
    int pos = 0;

    for (final (start, end, hw) in markers) {
      if (start < pos) continue; // skip overlaps
      if (pos < start) {
        spans.add(TextSpan(text: text.substring(pos, start), style: baseStyle));
      }
      final rec = TapGestureRecognizer()
        ..onTap = () => _showWordSheet(hw);
      _recognizers.add(rec);
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: hlStyle,
        recognizer: rec,
      ));
      pos = end;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: baseStyle));
    }
    return spans;
  }

  void _showWordSheet(HighlightedWord hw) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordSheet(word: hw),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final wordCount = article.highlightedWords.length;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // — Header —
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            article.topic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.schedule_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${article.readTime} min read',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _readProgress,
                              minHeight: 4,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(_readProgress * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // — Article body —
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlighted words legend
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _highlightColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _highlightColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFA5B4FC)
                                : _highlightColor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tap any highlighted word to see its meaning',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFA5B4FC)
                                  : _highlightColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Article text
                  RichText(
                    text: TextSpan(children: _buildArticleSpans(context)),
                  ),

                  const SizedBox(height: 32),
                  // Bottom hint when not finished
                  if (!_hasFinishedReading)
                    Center(
                      child: Text(
                        'Keep reading to unlock vocabulary review',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // — Bottom action bar —
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(
                top: BorderSide(color: context.borderSubtle),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _hasFinishedReading
                    ? () {
                        articleReadToday = true;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _VocabReviewScreen(
                              article: widget.article,
                            ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  disabledBackgroundColor:
                      context.borderSubtle,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  _hasFinishedReading
                      ? Icons.school_rounded
                      : Icons.lock_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  _hasFinishedReading
                      ? 'Review $wordCount Words →'
                      : 'Finish reading to unlock',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Word detail bottom sheet ────────────────────────────────────────────────

class _WordSheet extends StatelessWidget {
  final HighlightedWord word;

  const _WordSheet({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            word.word,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            word.meaningEn,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            word.meaningHi,
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${word.example}"',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }
}

// ─── Vocabulary review screen ─────────────────────────────────────────────────

class _VocabReviewScreen extends StatefulWidget {
  final Article article;

  const _VocabReviewScreen({required this.article});

  @override
  State<_VocabReviewScreen> createState() => _VocabReviewScreenState();
}

class _VocabReviewScreenState extends State<_VocabReviewScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < widget.article.highlightedWords.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      // Done — pop back to article, then pop to home
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.article.highlightedWords;
    final total = words.length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: context.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vocabulary Review',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_current + 1} / $total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_current + 1) / total,
                  minHeight: 5,
                  backgroundColor: context.borderSubtle,
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF059669)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Cards
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: total,
                itemBuilder: (context, i) =>
                    _WordCard(word: words[i], gradient: _gradient),
              ),
            ),
            // Next / Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _current < total - 1 ? 'Next Word →' : 'Done ✓',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final HighlightedWord word;
  final LinearGradient gradient;

  const _WordCard({required this.word, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.menu_book_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Today's Word",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  word.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  word.meaningEn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  word.meaningHi,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${word.example}"',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
