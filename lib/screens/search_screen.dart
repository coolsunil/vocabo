import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/category_sources.dart';
import '../models/word_model.dart';
import '../utils/app_colors.dart';
import 'learn_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchResult {
  final Word word;
  final String categoryKey;
  final int indexInCategory;
  const _SearchResult(this.word, this.categoryKey, this.indexInCategory);
}

class _SearchScreenState extends State<SearchScreen> {
  static const Map<String, String> _categoryTitles = {
    'core': 'Core Words',
    'synonyms': 'Synonyms & Antonyms',
    'oneword': 'One-word',
    'confusing': 'Confusing Pairs',
    'idioms': 'Idioms & Phrases',
    'advanced': 'Advanced',
    'fixed_prepositions': 'Fixed Prepositions',
    'phrasal_verbs': 'Phrasal Verbs',
    'root_words': 'Root Words',
    'common_errors': 'Common Errors',
    'homophones': 'Homophones',
    'spellings': 'Spellings',
    'foreign_words': 'Foreign Words',
    'proverbs': 'Proverbs',
    'sentence_improvement': 'Sentence Improvement',
    'cloze_test': 'Cloze Test',
  };

  static const Map<String, Color> _categoryColors = {
    'core': Color(0xFF1D4ED8),
    'synonyms': Color(0xFF3B82F6),
    'oneword': Color(0xFF10B981),
    'confusing': Color(0xFFF59E0B),
    'idioms': Color(0xFF8B5CF6),
    'advanced': Color(0xFFB45309),
    'fixed_prepositions': Color(0xFF0F766E),
    'phrasal_verbs': Color(0xFFBE185D),
    'root_words': Color(0xFF7C2D12),
    'common_errors': Color(0xFFD97706),
    'homophones': Color(0xFF4F46E5),
    'spellings': Color(0xFF0891B2),
    'foreign_words': Color(0xFF9333EA),
    'proverbs': Color(0xFF4D7C0F),
    'sentence_improvement': Color(0xFF475569),
    'cloze_test': Color(0xFFC2410C),
  };

  final _controller = TextEditingController();
  List<_SearchResult> _allWords = [];
  List<_SearchResult> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final all = <_SearchResult>[];
    for (final entry in categoryFiles.entries) {
      try {
        final jsonString = await rootBundle.loadString(entry.value);
        final list = json.decode(jsonString) as List<dynamic>;
        for (int i = 0; i < list.length; i++) {
          all.add(_SearchResult(Word.fromJson(list[i]), entry.key, i));
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _allWords = all;
      _loading = false;
    });
  }

  void _onQueryChanged() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final filtered = _allWords
        .where((r) =>
            r.word.word.toLowerCase().contains(q) ||
            r.word.meaningEn.toLowerCase().contains(q))
        .take(60)
        .toList()
      ..sort((a, b) {
        final aStarts = a.word.word.toLowerCase().startsWith(q);
        final bStarts = b.word.word.toLowerCase().startsWith(q);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.word.word.compareTo(b.word.word);
      });
    setState(() => _results = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search words, meanings…',
            border: InputBorder.none,
            hintStyle: TextStyle(color: context.textSecondary),
          ),
          style: TextStyle(fontSize: 16, color: context.textPrimary),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => _controller.clear(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _controller.text.trim().isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, size: 48, color: context.borderMedium),
                      const SizedBox(height: 12),
                      Text(
                        'Search across all categories',
                        style: TextStyle(color: context.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: context.textSecondary, fontSize: 15),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        final title = _categoryTitles[r.categoryKey] ?? r.categoryKey;
                        final color = _categoryColors[r.categoryKey] ?? const Color(0xFF64748B);
                        return _ResultTile(
                          result: r,
                          categoryTitle: title,
                          categoryColor: color,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LearnScreen(
                                category: r.categoryKey,
                                initialIndex: r.indexInCategory,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final String categoryTitle;
  final Color categoryColor;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.categoryTitle,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meaning = result.word.meaningEn.isNotEmpty
        ? result.word.meaningEn
        : result.word.meaningHi;
    final brief = meaning.length > 90 ? '${meaning.substring(0, 90)}…' : meaning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.word.word,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  if (brief.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      brief,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoryTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
