import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../data/bookmark_store.dart';
import '../data/category_sources.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import '../models/word_model.dart';
import '../widgets/cards/cloze_test_card.dart';
import '../widgets/cards/common_error_card.dart';
import '../widgets/cards/confusing_card.dart';
import '../widgets/cards/core_card.dart';
import '../widgets/cards/fixed_preposition_card.dart';
import '../widgets/cards/idiom_card.dart';
import '../widgets/cards/oneword_card.dart';
import '../widgets/cards/sentence_improvement_card.dart';
import '../widgets/cards/spelling_card.dart';
import '../widgets/cards/synonym_card.dart';

class LearnScreen extends StatefulWidget {
  final String category;
  final int? initialIndex;
  final bool trackProgress;

  const LearnScreen({super.key, required this.category, this.initialIndex, this.trackProgress = true});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, String> _learnTitles = {
    'core': 'Core Words',
    'synonyms': 'Synonyms & Antonyms',
    'antonyms': 'Synonyms & Antonyms',
    'synonyms_antonyms': 'Synonyms & Antonyms',
    'idioms': 'Idioms & Phrases',
    'confusing': 'Confusing Pairs',
    'oneword': 'One-word Substitutions',
    'advanced': 'Advanced Vocabulary',
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

  final ScreenshotController _screenshotController = ScreenshotController();

  int currentIndex = 0;
  bool isLoading = true;
  List<Word> words = [];
  Set<int> bookmarkedIndices = {};

  double _dragOffset = 0.0;
  bool _isThrowing = false;
  bool _isSnapBack = false;
  bool _throwForward = true;
  int? _throwingToIndex;
  bool _completionShown = false;

  late final AnimationController _throwController;
  late Animation<double> _throwAnim;

  @override
  void initState() {
    super.initState();
    _throwController = AnimationController(vsync: this);
    _throwAnim = Tween<double>(begin: 0, end: 0).animate(_throwController);
    loadWords();
  }

  @override
  void dispose() {
    _throwController.dispose();
    super.dispose();
  }

  void _snapBack() {
    final start = _dragOffset;
    _throwAnim = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _throwController, curve: Curves.elasticOut),
    );
    _throwController.duration = const Duration(milliseconds: 500);
    setState(() => _isSnapBack = true);
    _throwController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _dragOffset = 0.0;
        _isSnapBack = false;
      });
      _throwController.reset();
    });
  }

  void _showCompletionSheet() {
    if (_completionShown) return;
    _completionShown = true;
    HapticFeedback.mediumImpact();
    final title = _learnTitles[widget.category] ?? 'this category';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF059669), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category complete!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve gone through all ${words.length} words in $title.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _throw({required bool forward}) {
    HapticFeedback.lightImpact();
    final screenWidth = MediaQuery.of(context).size.width;
    final toIndex = forward ? currentIndex + 1 : currentIndex - 1;
    final target = forward ? -screenWidth * 1.5 : screenWidth * 1.5;
    _throwAnim = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _throwController, curve: Curves.easeOut),
    );
    _throwController.duration = const Duration(milliseconds: 260);
    setState(() {
      _isThrowing = true;
      _throwForward = forward;
      _throwingToIndex = toIndex;
    });
    _throwController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        currentIndex = toIndex;
        _dragOffset = 0.0;
        _isThrowing = false;
        _throwingToIndex = null;
      });
      if (forward) _updateProgress();
      _throwController.reset();
    });
  }

  Widget _cardContent(Word w, int idx) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildCard(w, indexOverride: idx)],
            ),
          ),
        );
      },
    );
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
        : (widget.initialIndex ?? savedProgress).clamp(0, loadedWords.length - 1);
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

    if (loadedWords.length > 1 && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('swipe_hint_done') ?? false;
      if (!shown && mounted) {
        await prefs.setBool('swipe_hint_done', true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Swipe cards to navigate',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
              elevation: 4,
              margin: const EdgeInsets.fromLTRB(60, 0, 60, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        });
      }
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
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                if (_isThrowing || _isSnapBack) return;
                setState(() => _dragOffset += d.delta.dx);
              },
              onHorizontalDragEnd: (d) {
                if (_isThrowing || _isSnapBack) return;
                final v = d.primaryVelocity ?? 0;
                final sw = MediaQuery.of(context).size.width;
                if ((v < -300 || _dragOffset < -sw * 0.28) &&
                    currentIndex < words.length - 1) {
                  _throw(forward: true);
                } else if ((v < -300 || _dragOffset < -sw * 0.28) &&
                    currentIndex == words.length - 1) {
                  _snapBack();
                  if (!_completionShown) {
                    Future.delayed(
                      const Duration(milliseconds: 520),
                      _showCompletionSheet,
                    );
                  }
                } else if ((v > 300 || _dragOffset > sw * 0.28) &&
                    currentIndex > 0) {
                  _throw(forward: false);
                } else {
                  _snapBack();
                }
              },
              child: AnimatedBuilder(
                animation: _throwController,
                builder: (context, _) {
                  final sw = MediaQuery.of(context).size.width;
                  final offset =
                      (_isThrowing || _isSnapBack) ? _throwAnim.value : _dragOffset;
                  final rotation = (offset / sw).clamp(-1.0, 1.0) * 0.10;
                  return Stack(
                    children: [
                      if (_isThrowing && _throwingToIndex != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            child: Transform.translate(
                              offset: Offset(
                                _throwForward
                                    ? sw * (1 - _throwController.value)
                                    : -sw * (1 - _throwController.value),
                                0,
                              ),
                              child: _cardContent(
                                  words[_throwingToIndex!], _throwingToIndex!),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Transform.translate(
                          offset: Offset(offset, 0),
                          child: Transform.rotate(
                            angle: rotation,
                            child: _cardContent(word, currentIndex),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Future<void> _shareCurrentCard() async {
    if (words.isEmpty) return;
    final word = words[currentIndex];
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        _buildShareCard(word),
        pixelRatio: 3.0,
        context: context,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/vocabo_word.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this word I learned on Vocabo! 📚',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share. Please try again.')),
      );
    }
  }

  Widget _buildShareCard(Word word) {
    switch (widget.category) {
      case 'synonyms':
      case 'antonyms':
      case 'synonyms_antonyms':
        return SynonymCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'idioms':
        return IdiomCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'confusing':
        return ConfusingCard(
          word: word, pairWord: _findConfusingPair(word),
          isBookmarked: false, onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'homophones':
        return ConfusingCard(
          word: word, pairWord: null,
          isBookmarked: false, onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'oneword':
        return OneWordCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'fixed_prepositions':
        return FixedPrepositionCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'common_errors':
        return CommonErrorCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'spellings':
        return SpellingCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'sentence_improvement':
        return SentenceImprovementCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      case 'cloze_test':
        return ClozeTestCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
      default:
        return CoreCard(
          word: word, isBookmarked: false,
          onBookmarkToggle: () {}, onShare: () {},
          index: currentIndex + 1, total: words.length, shareMode: true,
        );
    }
  }

  void _updateProgress() {
    if (!widget.trackProgress) return;
    final stored = progressStore[widget.category] ?? 0;
    // Only count progress if swiping sequentially — block jumps ahead
    if (currentIndex > stored + 1) return;
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
                        final value = int.tryParse(
                          numberController.text.trim(),
                        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No matching word found.')));
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
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
            ),
          ),
        );
        return;
      }
    }

    HapticFeedback.lightImpact();
    final updated = await toggleBookmark(widget.category, currentIndex);
    if (!mounted) return;
    setState(() {
      bookmarkedIndices = updated;
    });
  }

  Widget _buildCard(Word word, {int? indexOverride}) {
    final idx = indexOverride ?? currentIndex;
    final isBookmarked = bookmarkedIndices.contains(idx);
    switch (widget.category) {
      case 'synonyms':
      case 'antonyms':
      case 'synonyms_antonyms':
        return SynonymCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'idioms':
        return IdiomCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'confusing':
        final pairWord = _findConfusingPair(word);
        return ConfusingCard(
          word: word,
          pairWord: pairWord,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'homophones':
        return ConfusingCard(
          word: word,
          pairWord: null,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'oneword':
        return OneWordCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'fixed_prepositions':
        return FixedPrepositionCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'common_errors':
        return CommonErrorCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'spellings':
        return SpellingCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'sentence_improvement':
        return SentenceImprovementCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      case 'cloze_test':
        return ClozeTestCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
          total: words.length,
        );
      default:
        return CoreCard(
          word: word,
          isBookmarked: isBookmarked,
          onBookmarkToggle: _toggleCurrentBookmark,
          onShare: _shareCurrentCard,
          index: idx + 1,
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

