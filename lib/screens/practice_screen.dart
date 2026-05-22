import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/category_sources.dart';
import '../data/practice_stats_store.dart';
import '../data/premium_store.dart';
import '../data/weak_areas_store.dart';
import '../models/weak_attempt.dart';
import '../models/word_model.dart';

class PracticeScreen extends StatefulWidget {
  final String category;
  final String title;
  final List<WeakAttempt>? weakAttempts;

  const PracticeScreen({
    super.key,
    required this.category,
    required this.title,
    this.weakAttempts,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const int _timerDuration = 15 * 60; // 15 minutes

  final Random _random = Random();
  Timer? _overallTimer;
  int _timeLeft = _timerDuration;

  bool isLoading = true;
  bool isLocked = false;
  bool isProcessingNewSet = false;
  List<_PracticeQuestion> allQuestions = [];
  List<_PracticeQuestion> questions = [];
  int currentIndex = 0;
  int bestScore = 0;
  int bestAccuracy = 0;
  int remainingSessions = 0;
  int attempts = 0;
  int averageScore = 0;

  List<int?> _userSelections = [];
  final Set<int> _bookmarkedIndices = {};

  // Completion state — shown in-place after submit so Review back-nav is clean
  bool _quizCompleted = false;
  bool _isNewPersonalBest = false;
  int _prevBestScore = 0;
  int _lastCorrectCount = 0;
  int _lastTotal = 0;
  int _lastPercent = 0;
  int _lastClearedCount = 0;
  List<_PracticeQuestion> _reviewQuestions = [];
  List<int?> _reviewSelections = [];
  Set<int> _reviewBookmarks = {};

  bool get _isMixedQuiz => widget.category == 'mixed';
  bool get _isWeakAreasMode => widget.weakAttempts != null;
  int get _answeredCount => _userSelections.where((s) => s != null).length;

  @override
  void initState() {
    super.initState();
    _initializePractice();
  }

  @override
  void dispose() {
    _overallTimer?.cancel();
    super.dispose();
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void _startOverallTimer() {
    _overallTimer?.cancel();
    if (mounted) setState(() => _timeLeft = _timerDuration);
    _overallTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _showResult(); // auto-submit on expiry
      }
    });
  }

  void _cancelTimer() {
    _overallTimer?.cancel();
    _overallTimer = null;
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  Future<void> _initializePractice() async {
    if (_isWeakAreasMode) {
      await _initializeWeakAreasPractice();
      return;
    }
    await loadPremiumStore();
    await resetPremiumUsageState();
    await loadPracticeStatsStore([widget.category]);

    final words = await _loadWords();
    if (words.isEmpty) {
      if (!mounted) return;
      setState(() {
        allQuestions = [];
        questions = [];
        isLoading = false;
        bestScore = getStoredBestScore(widget.category);
        bestAccuracy = getStoredBestAccuracy(widget.category);
        attempts = getStoredAttempts(widget.category);
        averageScore = getStoredAverageScore(widget.category);
      });
      return;
    }

    final generated = _buildQuestions(words);
    generated.shuffle(_random);
    if (generated.isEmpty) {
      if (!mounted) return;
      setState(() {
        allQuestions = [];
        questions = [];
        isLoading = false;
        bestScore = getStoredBestScore(widget.category);
        bestAccuracy = getStoredBestAccuracy(widget.category);
        attempts = getStoredAttempts(widget.category);
        averageScore = getStoredAverageScore(widget.category);
      });
      return;
    }

    final allowed = await consumePracticeSession(widget.category, mixed: _isMixedQuiz);
    final remaining = await getRemainingPracticeSessions(widget.category, mixed: _isMixedQuiz);

    if (!mounted) return;

    if (!allowed) {
      setState(() {
        isLocked = true;
        isLoading = false;
        bestScore = getStoredBestScore(widget.category);
        bestAccuracy = getStoredBestAccuracy(widget.category);
        attempts = getStoredAttempts(widget.category);
        averageScore = getStoredAverageScore(widget.category);
        remainingSessions = remaining;
      });
      return;
    }

    setState(() {
      isLocked = false;
      allQuestions = generated;
      questions = _pickNextSet();
      _userSelections = List.filled(questions.length, null);
      _bookmarkedIndices.clear();
      currentIndex = 0;
      isLoading = false;
      bestScore = getStoredBestScore(widget.category);
      bestAccuracy = getStoredBestAccuracy(widget.category);
      attempts = getStoredAttempts(widget.category);
      averageScore = getStoredAverageScore(widget.category);
      remainingSessions = remaining;
    });
    _startOverallTimer();
  }

  Future<void> _initializeWeakAreasPractice() async {
    final attempts = widget.weakAttempts!;
    if (attempts.isEmpty) {
      if (!mounted) return;
      setState(() { allQuestions = []; questions = []; isLoading = false; });
      return;
    }

    // Pool of all correct answers — used as distractors for other questions
    final correctPool = attempts.map((a) => a.correctAnswer).toSet().toList();

    final generated = <_PracticeQuestion>[];
    for (final attempt in attempts) {
      final optionSet = <String>{attempt.correctAnswer};

      // Include the user's previous wrong answer as a distractor (high learning value)
      if (attempt.selectedAnswer.isNotEmpty &&
          attempt.selectedAnswer != '(No answer)' &&
          attempt.selectedAnswer != attempt.correctAnswer) {
        optionSet.add(attempt.selectedAnswer);
      }

      // Fill up to 4 options with random correct answers from other questions
      final others = correctPool.where((a) => !optionSet.contains(a)).toList()..shuffle(_random);
      for (final o in others) {
        if (optionSet.length >= 4) break;
        optionSet.add(o);
      }

      if (optionSet.length < 2) continue; // skip if can't form a valid question
      generated.add(_PracticeQuestion(
        prompt: attempt.prompt,
        options: optionSet.toList()..shuffle(_random),
        correctAnswer: attempt.correctAnswer,
      ));
    }

    generated.shuffle(_random);
    if (!mounted) return;
    setState(() {
      allQuestions = generated;
      questions = generated.take(practiceQuestionLimit).toList();
      _userSelections = List.filled(questions.length, null);
      _bookmarkedIndices.clear();
      currentIndex = 0;
      isLoading = false;
      bestScore = 0;
      bestAccuracy = 0;
    });
    // No timer in weak areas review mode
  }

  Future<List<Word>> _loadWords() async {
    if (_isMixedQuiz) {
      final all = <Word>[];
      for (final path in categoryFiles.values) {
        final jsonString = await rootBundle.loadString(path);
        final jsonData = json.decode(jsonString) as List<dynamic>;
        all.addAll(jsonData.map((e) => Word.fromJson(e)));
      }
      return all;
    }
    final path = categoryFiles[widget.category];
    if (path == null) return [];
    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((e) => Word.fromJson(e)).toList();
  }

  List<_PracticeQuestion> _buildQuestions(List<Word> words) {
    switch (widget.category) {
      case 'synonyms':
        return _buildSynonymQuestions(words);
      case 'idioms':
      case 'proverbs':
        return _buildIdiomQuestions(words);
      case 'oneword':
        return _buildOneWordQuestions(words);
      case 'confusing':
      case 'homophones':
        return _buildConfusingQuestions(words);
      case 'common_errors':
      case 'sentence_improvement':
        return _buildSentenceCorrectionQuestions(words);
      case 'cloze_test':
        return _buildClozeTestQuestions(words);
      case 'fixed_prepositions':
      case 'phrasal_verbs':
      case 'root_words':
      case 'spellings':
      case 'foreign_words':
      case 'advanced':
      case 'core':
      default:
        return _isMixedQuiz ? _buildMixedQuestions(words) : _buildMeaningToWordQuestions(words);
    }
  }

  List<_PracticeQuestion> _buildMixedQuestions(List<Word> words) {
    final byCategory = <String, List<Word>>{};
    for (final word in words) {
      byCategory.putIfAbsent(word.category, () => <Word>[]).add(word);
    }
    final mixed = <_PracticeQuestion>[];
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['core'] ?? const []));
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['advanced'] ?? const []));
    mixed.addAll(_buildSynonymQuestions(byCategory['synonyms'] ?? const []));
    mixed.addAll(_buildIdiomQuestions(byCategory['idioms'] ?? const []));
    mixed.addAll(_buildOneWordQuestions(byCategory['oneword'] ?? const []));
    mixed.addAll(_buildConfusingQuestions(byCategory['confusing'] ?? const []));
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['fixed_prepositions'] ?? const []));
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['phrasal_verbs'] ?? const []));
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['root_words'] ?? const []));
    mixed.addAll(_buildSentenceCorrectionQuestions(byCategory['common_errors'] ?? const []));
    mixed.addAll(_buildConfusingQuestions(byCategory['homophones'] ?? const []));
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['spellings'] ?? const []));
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['foreign_words'] ?? const []));
    mixed.addAll(_buildIdiomQuestions(byCategory['proverbs'] ?? const []));
    mixed.addAll(_buildSentenceCorrectionQuestions(byCategory['sentence_improvement'] ?? const []));
    mixed.addAll(_buildClozeTestQuestions(byCategory['cloze_test'] ?? const []));
    return mixed;
  }

  List<_PracticeQuestion> _buildMeaningToWordQuestions(List<Word> words) {
    final wordPool = words.map((w) => w.word.trim()).where((w) => w.isNotEmpty).toSet().toList();
    final qs = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.meaningEn.trim().isEmpty || word.word.trim().isEmpty) continue;
      final options = _buildOptions(word.word.trim(), wordPool);
      if (options.length < 4) continue;
      qs.add(_PracticeQuestion(prompt: 'Choose the correct word:\n${word.meaningEn}', options: options, correctAnswer: word.word.trim()));
    }
    return qs;
  }

  List<_PracticeQuestion> _buildSynonymQuestions(List<Word> words) {
    final synonymPool = words.expand((w) => w.synonyms).map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
    final qs = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.synonyms.isEmpty) continue;
      final correct = word.synonyms.first.trim();
      if (correct.isEmpty) continue;
      final options = _buildOptions(correct, synonymPool);
      if (options.length < 4) continue;
      qs.add(_PracticeQuestion(prompt: 'Select the best synonym for:\n${word.word}', options: options, correctAnswer: correct));
    }
    return qs;
  }

  List<_PracticeQuestion> _buildIdiomQuestions(List<Word> words) {
    final meaningPool = words.map((w) => w.meaningEn.trim()).where((m) => m.isNotEmpty).toSet().toList();
    final qs = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.meaningEn.trim().isEmpty) continue;
      final options = _buildOptions(word.meaningEn.trim(), meaningPool);
      if (options.length < 4) continue;
      qs.add(_PracticeQuestion(prompt: 'What does this idiom mean?\n${word.word}', options: options, correctAnswer: word.meaningEn.trim()));
    }
    return qs;
  }

  List<_PracticeQuestion> _buildOneWordQuestions(List<Word> words) {
    final pool = words.map((w) => w.word.trim()).where((w) => w.isNotEmpty).toSet().toList();
    final qs = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty) continue;
      final phrase = word.example.isNotEmpty ? word.example : word.meaningEn;
      if (phrase.trim().isEmpty) continue;
      final options = _buildOptions(word.word.trim(), pool);
      if (options.length < 4) continue;
      qs.add(_PracticeQuestion(prompt: 'Select the one-word substitution:\n$phrase', options: options, correctAnswer: word.word.trim()));
    }
    return qs;
  }

  List<_PracticeQuestion> _buildConfusingQuestions(List<Word> words) {
    final meaningPool = words.map((w) => w.meaningEn.trim()).where((m) => m.isNotEmpty).toSet().toList();
    final qs = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.meaningEn.trim().isEmpty) continue;
      final options = _buildOptions(word.meaningEn.trim(), meaningPool);
      if (options.length < 4) continue;
      qs.add(_PracticeQuestion(prompt: 'Choose the correct meaning for:\n${word.word}', options: options, correctAnswer: word.meaningEn.trim()));
    }
    return qs;
  }

  List<_PracticeQuestion> _buildSentenceCorrectionQuestions(List<Word> words) {
    // Diff every pair to extract the exact changed phrase.
    final diffs = <({String wrong, String correct, String wrongPhrase, String correctPhrase})>[];
    for (final word in words) {
      final orig = word.word.trim();
      final corr = word.example.trim();
      if (orig.isEmpty || corr.isEmpty || orig == corr) continue;
      final d = _diffEntry(orig, corr);
      if (d != null) diffs.add(d);
    }

    // Group wrong phrases by their correctPhrase — these are the most natural
    // variants of the same grammatical slot (e.g. correctPhrase "loves" collects
    // wrong forms "love", "loved", "loving" from other entries in the data).
    final wrongByCorrect = <String, List<String>>{};
    for (final d in diffs) {
      wrongByCorrect.putIfAbsent(d.correctPhrase, () => []).add(d.wrongPhrase);
    }
    // Flat fallback pool of every wrong phrase in the dataset.
    final allWrong = diffs.map((d) => d.wrongPhrase).toSet().toList();

    final qs = <_PracticeQuestion>[];
    for (final d in diffs) {
      // Seed with the correct sentence and the original wrong sentence.
      final optionSet = <String>{d.correct, d.wrong};

      // Primary distractors: substitute same-slot wrong phrases into THIS correct
      // sentence. These are conjugations / forms of the exact same word that
      // appear elsewhere in the dataset, so they sound natural in context.
      final sameSlot = (wrongByCorrect[d.correctPhrase] ?? [])
          .where((p) => p != d.wrongPhrase)
          .toSet()
          .toList()..shuffle(_random);
      for (final p in sameSlot) {
        if (optionSet.length >= 4) break;
        final s = _substitute(d.correct, d.correctPhrase, p);
        if (s != null && !optionSet.contains(s)) optionSet.add(s);
      }

      // Fallback: any wrong phrase from any entry, substituted at the same spot.
      if (optionSet.length < 4) {
        final rest = allWrong
            .where((p) => p != d.wrongPhrase && p != d.correctPhrase)
            .toList()..shuffle(_random);
        for (final p in rest) {
          if (optionSet.length >= 4) break;
          final s = _substitute(d.correct, d.correctPhrase, p);
          if (s != null && !optionSet.contains(s)) optionSet.add(s);
        }
      }

      if (optionSet.length < 4) continue;
      qs.add(_PracticeQuestion(
        prompt: 'Choose the correct sentence:\n${d.wrong}',
        options: optionSet.toList()..shuffle(_random),
        correctAnswer: d.correct,
      ));
    }
    return qs;
  }

  // Word-level diff: extracts the changed fragments between [wrong] and [correct].
  ({String wrong, String correct, String wrongPhrase, String correctPhrase})? _diffEntry(
      String wrong, String correct) {
    final ww = wrong.split(RegExp(r'\s+'));
    final cw = correct.split(RegExp(r'\s+'));
    String norm(String w) => w.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();

    int pre = 0;
    while (pre < ww.length && pre < cw.length && norm(ww[pre]) == norm(cw[pre])) { pre++; }
    int suf = 0;
    while (suf < ww.length - pre &&
        suf < cw.length - pre &&
        norm(ww[ww.length - 1 - suf]) == norm(cw[cw.length - 1 - suf])) { suf++; }

    final wrongPhrase = ww.sublist(pre, ww.length - suf).join(' ');
    final correctPhrase = cw.sublist(pre, cw.length - suf).join(' ');

    if (wrongPhrase.isEmpty || correctPhrase.isEmpty || wrongPhrase == correctPhrase) return null;
    if (correctPhrase.split(' ').length > 5) return null;

    return (wrong: wrong, correct: correct, wrongPhrase: wrongPhrase, correctPhrase: correctPhrase);
  }

  // Replaces [target] phrase inside [sentence] (word-level match) with [replacement].
  // Returns null if target is not found as a contiguous word sequence.
  String? _substitute(String sentence, String target, String replacement) {
    final sw = sentence.split(RegExp(r'\s+'));
    final tw = target.split(RegExp(r'\s+'));
    String norm(String w) => w.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    for (int i = 0; i <= sw.length - tw.length; i++) {
      bool match = true;
      for (int j = 0; j < tw.length; j++) {
        if (norm(sw[i + j]) != norm(tw[j])) { match = false; break; }
      }
      if (match) {
        return [...sw.take(i), replacement, ...sw.skip(i + tw.length)].join(' ');
      }
    }
    return null;
  }

  List<_PracticeQuestion> _buildClozeTestQuestions(List<Word> words) {
    final qs = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.example.trim().isEmpty || word.options.length < 2) continue;
      final shuffled = List<String>.from(word.options)..shuffle(_random);
      qs.add(_PracticeQuestion(prompt: 'Fill in the blank:\n${word.word}', options: shuffled, correctAnswer: word.example.trim()));
    }
    return qs;
  }

  List<String> _buildOptions(String correct, List<String> pool) {
    final options = <String>{correct};
    final candidates = pool.where((item) => item != correct).toList()..shuffle(_random);
    for (final candidate in candidates) {
      if (options.length >= 4) break;
      options.add(candidate);
    }
    return options.toList()..shuffle(_random);
  }

  // ── Interaction ──────────────────────────────────────────────────────────

  void _selectOption(int index) {
    HapticFeedback.lightImpact();
    setState(() => _userSelections[currentIndex] = index);
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarkedIndices.contains(currentIndex)) {
        _bookmarkedIndices.remove(currentIndex);
      } else {
        _bookmarkedIndices.add(currentIndex);
      }
    });
  }

  void _goToIndex(int i) {
    if (i >= 0 && i < questions.length) setState(() => currentIndex = i);
  }

  void _showQuestionGrid() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QuestionGridSheet(
        total: questions.length,
        currentIndex: currentIndex,
        userSelections: _userSelections,
        bookmarkedIndices: _bookmarkedIndices,
        onSelect: (i) {
          Navigator.pop(context);
          _goToIndex(i);
        },
      ),
    );
  }

  void _tryFinish() {
    final unanswered = questions.length - _answeredCount;
    if (unanswered > 0) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit Quiz?'),
          content: Text(
            '$unanswered question${unanswered == 1 ? '' : 's'} left unanswered. Submit anyway?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go Back')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F3C6D), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _cancelTimer();
                _showResult();
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    } else {
      _cancelTimer();
      _showResult();
    }
  }

  void _restartCurrentSet() {
    _cancelTimer();
    setState(() {
      _quizCompleted = false;
      currentIndex = 0;
      _userSelections = List.filled(questions.length, null);
      _bookmarkedIndices.clear();
    });
    if (!_isWeakAreasMode) _startOverallTimer();
  }

  Future<void> _startNewSet() async {
    if (isProcessingNewSet) return;
    _cancelTimer();
    setState(() => isProcessingNewSet = true);

    if (!premiumUnlocked) {
      final allowed = await consumePracticeSession(widget.category, mixed: _isMixedQuiz);
      final remaining = await getRemainingPracticeSessions(widget.category, mixed: _isMixedQuiz);
      if (!mounted) return;
      if (!allowed) {
        setState(() { remainingSessions = remaining; isLocked = true; isProcessingNewSet = false; });
        return;
      }
      setState(() => remainingSessions = remaining);
    }

    setState(() {
      _quizCompleted = false;
      questions = _pickNextSet(excludeCurrentSet: true);
      _userSelections = List.filled(questions.length, null);
      _bookmarkedIndices.clear();
      currentIndex = 0;
      isProcessingNewSet = false;
    });
    _startOverallTimer();
  }

  int _computeCorrectCount() {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      final sel = _userSelections[i];
      if (sel != null && sel >= 0 && sel < questions[i].options.length) {
        if (questions[i].options[sel] == questions[i].correctAnswer) count++;
      }
    }
    return count;
  }

  void _saveWeakAttempts() {
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final sel = _userSelections[i];
      final isAnswered = sel != null && sel >= 0 && sel < q.options.length;
      final selectedAnswer = isAnswered ? q.options[sel] : '(No answer)';
      final isCorrect = isAnswered && q.options[sel] == q.correctAnswer;
      if (!isCorrect) {
        saveWeakAttempt(widget.category, WeakAttempt(
          prompt: q.prompt,
          correctAnswer: q.correctAnswer,
          selectedAnswer: selectedAnswer,
          category: widget.category,
          updatedAt: DateTime.now(),
        ));
      }
    }
  }

  Future<void> _showResult() async {
    _cancelTimer();
    final correctCount = _computeCorrectCount();
    final total = questions.length;
    final percent = total == 0 ? 0 : ((correctCount / total) * 100).round();

    // Capture pre-update values for comparison
    final prevBest = bestScore;
    final hadPreviousAttempt = attempts > 0 || bestScore > 0;

    // In weak areas mode: remove correctly-answered questions from the store
    int clearedCount = 0;
    if (_isWeakAreasMode) {
      for (int i = 0; i < questions.length; i++) {
        final sel = _userSelections[i];
        if (sel == null || sel < 0 || sel >= questions[i].options.length) continue;
        if (questions[i].options[sel] == questions[i].correctAnswer) {
          await removeWeakAttempt(widget.category, questions[i].prompt);
          clearedCount++;
        }
      }
    } else {
      _saveWeakAttempts();
      await updateBestPracticeStats(widget.category, score: correctCount, accuracy: percent);
    }

    if (!mounted) return;
    setState(() {
      if (!_isWeakAreasMode) {
        bestScore = getStoredBestScore(widget.category);
        bestAccuracy = getStoredBestAccuracy(widget.category);
        attempts = getStoredAttempts(widget.category);
        averageScore = getStoredAverageScore(widget.category);
      }
      _prevBestScore = prevBest;
      _isNewPersonalBest = hadPreviousAttempt && !_isWeakAreasMode && correctCount > prevBest;
      _lastCorrectCount = correctCount;
      _lastTotal = total;
      _lastPercent = percent;
      _lastClearedCount = clearedCount;
      _reviewQuestions = List<_PracticeQuestion>.from(questions);
      _reviewSelections = List<int?>.from(_userSelections);
      _reviewBookmarks = Set<int>.from(_bookmarkedIndices);
      _quizCompleted = true;
    });
  }

  List<_PracticeQuestion> _pickNextSet({bool excludeCurrentSet = false}) {
    if (allQuestions.isEmpty) return [];
    final pool = List<_PracticeQuestion>.from(allQuestions);
    if (excludeCurrentSet && questions.isNotEmpty) {
      final currentPrompts = questions.map((q) => q.prompt).toSet();
      final filtered = pool.where((q) => !currentPrompts.contains(q.prompt)).toList();
      if (filtered.length >= practiceQuestionLimit) {
        filtered.shuffle(_random);
        return filtered.take(practiceQuestionLimit).toList();
      }
    }
    pool.shuffle(_random);
    return pool.take(practiceQuestionLimit).toList();
  }

  // ── Completion view ───────────────────────────────────────────────────────

  Widget _buildCompletionView() {
    final skippedCount = _lastTotal - _reviewSelections.where((s) => s != null).length;
    final wrongCount = _lastTotal - _lastCorrectCount - skippedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C6D),
        foregroundColor: Colors.white,
        title: Text(_isWeakAreasMode ? '${widget.title} — Weak Areas' : '${widget.title} Practice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Personal best banner
            if (_isNewPersonalBest) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1F3C6D), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New Personal Best!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            'Previous best: $_prevBestScore/$_lastTotal. You\'re improving!',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Header result card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 52),
                  const SizedBox(height: 10),
                  const Text('Submitted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _ResultStatCard(label: 'Score', value: '$_lastCorrectCount/$_lastTotal', valueColor: const Color(0xFF0F172A), backgroundColor: const Color(0xFFF8FAFC))),
                      const SizedBox(width: 10),
                      Expanded(child: _ResultStatCard(label: 'Accuracy', value: '$_lastPercent%', valueColor: const Color(0xFF0F766E), backgroundColor: const Color(0xFFF0FDFA))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _ResultStatCard(label: 'Correct', value: '$_lastCorrectCount', valueColor: const Color(0xFF15803D), backgroundColor: const Color(0xFFF0FDF4))),
                      const SizedBox(width: 10),
                      Expanded(child: _ResultStatCard(label: 'Wrong', value: '$wrongCount', valueColor: const Color(0xFFDC2626), backgroundColor: const Color(0xFFFEF2F2))),
                    ],
                  ),
                  if (skippedCount > 0) ...[
                    const SizedBox(height: 10),
                    _ResultStatCard(label: 'Skipped', value: '$skippedCount', valueColor: const Color(0xFFB45309), backgroundColor: const Color(0xFFFFFBEB)),
                  ],
                  if (!_isWeakAreasMode && _prevBestScore > 0) ...[
                    const SizedBox(height: 12),
                    _DeltaChip(current: _lastCorrectCount, previous: _prevBestScore, total: _lastTotal),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Weak areas cleared banner
            if (_isWeakAreasMode)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF15803D), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lastClearedCount > 0
                            ? '$_lastClearedCount question${_lastClearedCount == 1 ? '' : 's'} removed from your weak areas. Keep going!'
                            : 'Review the answers below and practise again to clear weak areas.',
                        style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            // Best performance (normal mode only)
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBFDBFE))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Best Performance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Text('Best Score: $bestScore/$_lastTotal', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Best Accuracy: $bestAccuracy%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Review answers
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ReviewPage(
                  questions: _reviewQuestions,
                  userSelections: _reviewSelections,
                  bookmarkedIndices: _reviewBookmarks,
                ))),
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('Review Answers'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1D4ED8)),
                  foregroundColor: const Color(0xFF1D4ED8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _restartCurrentSet,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1F3C6D)),
                      foregroundColor: const Color(0xFF1F3C6D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Repeat'),
                  ),
                ),
              ],
            ),
            if (!_isWeakAreasMode) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessingNewSet ? null : _startNewSet,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Start New Set'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3C6D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_quizCompleted) return _buildCompletionView();

    if (isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(backgroundColor: const Color(0xFF1F3C6D), foregroundColor: Colors.white, title: Text('${widget.title} Practice')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isMixedQuiz ? 'Daily mixed quiz limit reached' : 'Daily practice limit reached',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isMixedQuiz
                        ? 'Free plan includes $freeMixedQuizAttemptsPerDay Take a Quiz session per day. Unlock premium for unlimited mixed quizzes.'
                        : 'Free plan includes $freePracticeAttemptsPerDay practice sessions per category each day. Unlock premium for unlimited practice.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Text('Remaining today: $remainingSessions', style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())).then((_) {
                        if (mounted) { setState(() => isLoading = true); _initializePractice(); }
                      });
                    },
                    child: const Text('View Premium'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice'), backgroundColor: const Color(0xFF1F3C6D), foregroundColor: Colors.white),
        body: const Center(child: Text('Not enough data to generate practice questions.', style: TextStyle(color: Color(0xFF475569)), textAlign: TextAlign.center)),
      );
    }

    final question = questions[currentIndex];
    final selectedOption = _userSelections.length > currentIndex ? _userSelections[currentIndex] : null;
    final isBookmarked = _bookmarkedIndices.contains(currentIndex);
    final showFreeTierInfo = !premiumUnlocked;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C6D),
        foregroundColor: Colors.white,
        title: Text(_isWeakAreasMode ? '${widget.title} — Weak Areas' : '${widget.title} Practice'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _isWeakAreasMode
                  ? const _ReviewModeBadge()
                  : _TimerWidget(seconds: _timeLeft),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats row
            if (_isWeakAreasMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.track_changes_rounded, color: Color(0xFF1D4ED8), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${questions.length} weak area${questions.length == 1 ? '' : 's'} to clear',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8), fontSize: 15),
                      ),
                    ),
                    const Text('Answer correctly to remove', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    Expanded(child: _StatBox(label: 'Best Score', value: '$bestScore/${questions.length}')),
                    Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: _StatBox(label: 'Avg Score', value: attempts > 0 ? '$averageScore/${questions.length}' : '—'),
                    )),
                    Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: _StatBox(label: 'Attempts', value: attempts > 0 ? '$attempts' : '—'),
                    )),
                  ],
                ),
              ),
            if (showFreeTierInfo) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A))),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isMixedQuiz ? '$remainingSessions mixed quiz session left today.' : '$remainingSessions free sessions left today.',
                        style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Progress row
            Row(
              children: [
                Text('Question ${currentIndex + 1} of ${questions.length}', style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Text(
                    'Answered: $_answeredCount/${questions.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _answeredCount / questions.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 16),
            // Question card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1F3C6D), borderRadius: BorderRadius.circular(7)),
                        child: Text(
                          'Q${currentIndex + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isBookmarked ? const Color(0xFF1F3C6D) : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(question.prompt, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final isSelected = selectedOption == index;

                  return GestureDetector(
                    onTap: () => _selectOption(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1F3C6D) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF1F3C6D) : const Color(0xFFF1F5F9),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected ? const Color(0xFF1F3C6D) : const Color(0xFF1E293B),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Prev / Grid / Next row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentIndex > 0 ? () => _goToIndex(currentIndex - 1) : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Prev'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _showQuestionGrid,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: const Icon(Icons.grid_view_rounded, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentIndex < questions.length - 1 ? () => _goToIndex(currentIndex + 1) : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    iconAlignment: IconAlignment.end,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _tryFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F3C6D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Submit Quiz  ($_answeredCount/${questions.length} answered)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timer widget ──────────────────────────────────────────────────────────────

class _ReviewModeBadge extends StatelessWidget {
  const _ReviewModeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes_rounded, size: 14, color: Colors.white),
          SizedBox(width: 5),
          Text('Review Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int seconds;
  const _TimerWidget({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final text = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final Color color = seconds <= 120
        ? Colors.red.shade300
        : seconds <= 300
            ? Colors.amber.shade300
            : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_rounded, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

// ── Question grid bottom sheet ────────────────────────────────────────────────

class _QuestionGridSheet extends StatelessWidget {
  final int total;
  final int currentIndex;
  final List<int?> userSelections;
  final Set<int> bookmarkedIndices;
  final ValueChanged<int> onSelect;

  const _QuestionGridSheet({
    required this.total,
    required this.currentIndex,
    required this.userSelections,
    required this.bookmarkedIndices,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Jump to Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _legendDot(Colors.white, const Color(0xFFE2E8F0), 'Unanswered'),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFF1F3C6D), const Color(0xFF1F3C6D), 'Answered', textColor: Colors.white),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFF22C55E).withValues(alpha: 0.15), const Color(0xFF22C55E), 'Current'),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: total,
              itemBuilder: (context, i) {
                final isAnswered = userSelections.length > i && userSelections[i] != null;
                final isCurrent = i == currentIndex;
                final isBookmarked = bookmarkedIndices.contains(i);

                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                          : isAnswered
                              ? const Color(0xFF1F3C6D)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF22C55E) : isAnswered ? const Color(0xFF1F3C6D) : const Color(0xFFE2E8F0),
                        width: isCurrent ? 2 : 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isAnswered && !isCurrent ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        if (isBookmarked)
                          Positioned(
                            top: 3,
                            right: 3,
                            child: Icon(
                              Icons.bookmark_rounded,
                              size: 10,
                              color: isAnswered ? Colors.white70 : const Color(0xFF1F3C6D),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color bg, Color border, String label, {Color textColor = const Color(0xFF334155)}) {
    return Row(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}

// ── Review page ───────────────────────────────────────────────────────────────

class _ReviewPage extends StatelessWidget {
  final List<_PracticeQuestion> questions;
  final List<int?> userSelections;
  final Set<int> bookmarkedIndices;

  const _ReviewPage({required this.questions, required this.userSelections, required this.bookmarkedIndices});

  @override
  Widget build(BuildContext context) {
    final hasBookmarks = bookmarkedIndices.isNotEmpty;
    return DefaultTabController(
      length: hasBookmarks ? 2 : 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F3C6D),
          foregroundColor: Colors.white,
          title: const Text('Review Answers'),
          bottom: hasBookmarks
              ? const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  tabs: [Tab(text: 'All Questions'), Tab(text: 'Bookmarked')],
                )
              : null,
        ),
        body: hasBookmarks
            ? TabBarView(children: [
                _QuestionList(questions: questions, userSelections: userSelections, bookmarkedIndices: bookmarkedIndices, filterBookmarked: false),
                _QuestionList(questions: questions, userSelections: userSelections, bookmarkedIndices: bookmarkedIndices, filterBookmarked: true),
              ])
            : _QuestionList(questions: questions, userSelections: userSelections, bookmarkedIndices: bookmarkedIndices, filterBookmarked: false),
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  final List<_PracticeQuestion> questions;
  final List<int?> userSelections;
  final Set<int> bookmarkedIndices;
  final bool filterBookmarked;

  const _QuestionList({required this.questions, required this.userSelections, required this.bookmarkedIndices, required this.filterBookmarked});

  @override
  Widget build(BuildContext context) {
    final indices = List.generate(questions.length, (i) => i).where((i) => !filterBookmarked || bookmarkedIndices.contains(i)).toList();
    if (indices.isEmpty) {
      return const Center(child: Text('No bookmarked questions.', style: TextStyle(color: Color(0xFF64748B))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: indices.length,
      itemBuilder: (context, listIdx) {
        final i = indices[listIdx];
        final q = questions[i];
        final sel = userSelections.length > i ? userSelections[i] : null;
        final isSkipped = sel == null;
        final isCorrect = !isSkipped && sel >= 0 && sel < q.options.length && q.options[sel] == q.correctAnswer;
        final isBookmarked = bookmarkedIndices.contains(i);

        final Color statusColor;
        final IconData statusIcon;
        final String statusLabel;
        if (isSkipped) {
          statusColor = const Color(0xFFB45309);
          statusIcon = Icons.remove_circle_outline_rounded;
          statusLabel = 'Skipped';
        } else if (isCorrect) {
          statusColor = const Color(0xFF16A34A);
          statusIcon = Icons.check_circle_rounded;
          statusLabel = 'Correct';
        } else {
          statusColor = const Color(0xFFDC2626);
          statusIcon = Icons.cancel_rounded;
          statusLabel = 'Wrong';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1F3C6D).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text('Q${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F3C6D), fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Icon(statusIcon, color: statusColor, size: 17),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    if (isBookmarked) const Icon(Icons.bookmark_rounded, color: Color(0xFF1F3C6D), size: 18),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.prompt, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), height: 1.45)),
                    const SizedBox(height: 12),
                    if (!isCorrect && !isSkipped && sel >= 0 && sel < q.options.length) ...[
                      _answerRow(label: 'Your Answer', text: q.options[sel], color: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2)),
                      const SizedBox(height: 6),
                    ],
                    if (isSkipped) ...[
                      _answerRow(label: 'Skipped', text: 'No answer selected', color: const Color(0xFFB45309), bg: const Color(0xFFFFFBEB)),
                      const SizedBox(height: 6),
                    ],
                    _answerRow(label: 'Correct Answer', text: q.correctAnswer, color: const Color(0xFF16A34A), bg: const Color(0xFFECFDF3)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _answerRow({required String label, required String text, required Color color, required Color bg}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 14, color: color, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Stat widgets ──────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final int current;
  final int previous;
  final int total;

  const _DeltaChip({required this.current, required this.previous, required this.total});

  @override
  Widget build(BuildContext context) {
    final delta = current - previous;
    final isPositive = delta > 0;
    final isEqual = delta == 0;
    final Color color = isEqual
        ? const Color(0xFF64748B)
        : isPositive
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    final IconData icon = isEqual
        ? Icons.remove_rounded
        : isPositive
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;
    final String text = isEqual
        ? 'Matched your best of $previous/$total'
        : isPositive
            ? '+$delta vs your previous best ($previous/$total)'
            : '$delta vs your previous best ($previous/$total)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _PracticeQuestion {
  final String prompt;
  final List<String> options;
  final String correctAnswer;

  const _PracticeQuestion({required this.prompt, required this.options, required this.correctAnswer});
}

class _ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color backgroundColor;

  const _ResultStatCard({required this.label, required this.value, required this.valueColor, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }
}
