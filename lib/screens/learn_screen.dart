import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bookmark_store.dart';
import '../data/category_sources.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import '../models/word_model.dart';
import '../widgets/cards/confusing_card.dart';
import '../widgets/cards/core_card.dart';
import '../widgets/cards/idiom_card.dart';
import '../widgets/cards/oneword_card.dart';
import '../widgets/cards/synonym_card.dart';

class LearnScreen extends StatefulWidget {
  final String category;

  const LearnScreen({super.key, required this.category});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const Map<String, String> _learnTitles = {
    'core': 'Core Words',
    'synonyms': 'Synonyms & Antonyms',
    'idioms': 'Idioms & Phrases',
    'confusing': 'Confusing Pairs',
    'oneword': 'One-word Substitutions',
    'advanced': 'Advanced Vocabulary',
  };

  int currentIndex = 0;
  bool isLoading = true;
  List<Word> words = [];
  Set<int> bookmarkedIndices = {};

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  Future<void> loadWords() async {
    final path = categoryFiles[widget.category];
    if (path == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString) as List<dynamic>;
    final loadedWords = jsonData.map((e) => Word.fromJson(e)).toList();
    final savedProgress = progressStore[widget.category] ?? 0;
    final resumeIndex = loadedWords.isEmpty
        ? 0
        : savedProgress.clamp(0, loadedWords.length - 1);
    final loadedBookmarks = await loadBookmarks(widget.category);

    setState(() {
      words = loadedWords;
      currentIndex = resumeIndex;
      bookmarkedIndices = loadedBookmarks;
      isLoading = false;
    });

    if (loadedWords.isNotEmpty) {
      updateProgressIfHigher(widget.category, 1, total: loadedWords.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = _learnTitles[widget.category] ?? 'Learn';

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (words.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F3C6D),
          foregroundColor: Colors.white,
          title: Text(screenTitle),
        ),
        body: const Center(
          child: Text(
            'No words found for this category yet.',
            style: TextStyle(color: Color(0xFF475569)),
          ),
        ),
      );
    }

    final word = words[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C6D),
        foregroundColor: Colors.white,
        title: Text(screenTitle),
        actions: [
          IconButton(
            tooltip: 'Jump to word',
            icon: const Icon(Icons.swap_horiz_rounded, size: 28),
            onPressed: _showJumpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0 &&
                    currentIndex < words.length - 1) {
                  setState(() {
                    currentIndex++;
                    _updateProgress();
                  });
                } else if (details.primaryVelocity! > 0 && currentIndex > 0) {
                  setState(() {
                    currentIndex--;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          minWidth: constraints.maxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_buildCard(word)],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateProgress() {
    updateProgressIfHigher(
      widget.category,
      currentIndex + 1,
      total: words.length,
    );
  }

  Future<void> _showJumpDialog() async {
    if (words.isEmpty) return;
    final numberController = TextEditingController(
      text: (currentIndex + 1).toString(),
    );
    final searchController = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to word'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jump by number',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Word number (1-${words.length})',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(numberController.text.trim());
                        Navigator.pop(context, value);
                      },
                      child: const Text('Go'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find by word',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search word text',
                      hintText: 'Type a word and tap Search',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final query = searchController.text.trim();
                        final found = _findWordIndexByQuery(query);
                        Navigator.pop(context, found == null ? -1 : found + 1);
                      },
                      child: const Text('Search'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick ranges',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildQuickRangeChips(context),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    if (result == -1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching word found.')),
      );
      return;
    }
    if (result < 1 || result > words.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a valid number or word (1 to ${words.length}).'),
        ),
      );
      return;
    }

    _jumpToIndex(result - 1);
  }

  void _jumpToIndex(int targetIndex) {
    setState(() {
      currentIndex = targetIndex;
    });
    if (targetIndex + 1 > (progressStore[widget.category] ?? 0)) {
      _updateProgress();
    }
  }

  int? _findWordIndexByQuery(String query) {
    if (query.isEmpty) return null;
    final normalized = query.toLowerCase().trim();

    for (var i = 0; i < words.length; i++) {
      if (words[i].word.toLowerCase().trim() == normalized) return i;
    }
    for (var i = 0; i < words.length; i++) {
      if (words[i].word.toLowerCase().trim().startsWith(normalized)) {
        return i;
      }
    }
    for (var i = 0; i < words.length; i++) {
      if (words[i].word.toLowerCase().contains(normalized)) return i;
    }
    return null;
  }

  List<Widget> _buildQuickRangeChips(BuildContext dialogContext) {
    final widgets = <Widget>[];
    for (int start = 1; start <= words.length; start += 100) {
      final end = (start + 99 <= words.length) ? start + 99 : words.length;
      widgets.add(
        ActionChip(
          label: Text('$start-$end'),
          onPressed: () {
            Navigator.pop(dialogContext, start);
          },
        ),
      );
    }
    return widgets;
  }

  Future<void> _toggleCurrentBookmark() async {
    final isCurrentlyBookmarked = bookmarkedIndices.contains(currentIndex);
    if (!isCurrentlyBookmarked) {
      await loadPremiumStore();
      final canSave = await canAddBookmark();
      if (!mounted) return;
      if (!canSave) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Free plan allows up to $freeBookmarkLimit bookmarks. Unlock premium to save more.',
            ),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }
    }

    final updated = await toggleBookmark(widget.category, currentIndex);
    if (!mounted) return;
    setState(() {
      bookmarkedIndices = updated;
    });
  }

  Widget _buildCard(Word word) {
    switch (widget.category) {
      case 'synonyms':
        return SynonymCard(
          word: word,
          isBookmarked: bookmarkedIndices.contains(currentIndex),
          onBookmarkToggle: _toggleCurrentBookmark,
          index: currentIndex + 1,
          total: words.length,
        );
      case 'idioms':
        return IdiomCard(
          word: word,
          isBookmarked: bookmarkedIndices.contains(currentIndex),
          onBookmarkToggle: _toggleCurrentBookmark,
          index: currentIndex + 1,
          total: words.length,
        );
      case 'confusing':
        final pairWord = _findConfusingPair(word);
        return ConfusingCard(
          word: word,
          pairWord: pairWord,
          isBookmarked: bookmarkedIndices.contains(currentIndex),
          onBookmarkToggle: _toggleCurrentBookmark,
          index: currentIndex + 1,
          total: words.length,
        );
      case 'oneword':
        return OneWordCard(
          word: word,
          isBookmarked: bookmarkedIndices.contains(currentIndex),
          onBookmarkToggle: _toggleCurrentBookmark,
          index: currentIndex + 1,
          total: words.length,
        );
      default:
        return CoreCard(
          word: word,
          isBookmarked: bookmarkedIndices.contains(currentIndex),
          onBookmarkToggle: _toggleCurrentBookmark,
          index: currentIndex + 1,
          total: words.length,
        );
    }
  }

  Word? _findConfusingPair(Word current) {
    if (current.confusionWith.isEmpty) return null;
    final target = current.confusionWith.first.toLowerCase().trim();
    for (final word in words) {
      if (word.word.toLowerCase().trim() == target) {
        return word;
      }
    }
    return null;
  }
}



