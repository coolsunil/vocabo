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

  const PracticeScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const int _questionLimit = 10;

  final Random _random = Random();
  bool isLoading = true;
  bool isLocked = false;
  bool isProcessingNewSet = false;
  List<_PracticeQuestion> allQuestions = [];
  List<_PracticeQuestion> questions = [];
  int currentIndex = 0;
  int? selectedIndex;
  int correctCount = 0;
  int bestScore = 0;
  int bestAccuracy = 0;
  int remainingSessions = 0;

  bool get _isMixedQuiz => widget.category == 'mixed';

  @override
  void initState() {
    super.initState();
    _initializePractice();
  }

  Future<void> _initializePractice() async {
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
      });
      return;
    }

    final allowed = await consumePracticeSession(
      widget.category,
      mixed: _isMixedQuiz,
    );
    final remaining = await getRemainingPracticeSessions(
      widget.category,
      mixed: _isMixedQuiz,
    );

    if (!mounted) return;

    if (!allowed) {
      setState(() {
        isLocked = true;
        isLoading = false;
        bestScore = getStoredBestScore(widget.category);
        bestAccuracy = getStoredBestAccuracy(widget.category);
        remainingSessions = remaining;
      });
      return;
    }

    setState(() {
      isLocked = false;
      allQuestions = generated;
      questions = _pickNextSet();
      isLoading = false;
      bestScore = getStoredBestScore(widget.category);
      bestAccuracy = getStoredBestAccuracy(widget.category);
      remainingSessions = remaining;
    });
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
        return _buildIdiomQuestions(words);
      case 'oneword':
        return _buildOneWordQuestions(words);
      case 'confusing':
        return _buildConfusingQuestions(words);
      case 'advanced':
      case 'core':
      default:
        return _isMixedQuiz
            ? _buildMixedQuestions(words)
            : _buildMeaningToWordQuestions(words);
    }
  }

  List<_PracticeQuestion> _buildMixedQuestions(List<Word> words) {
    final byCategory = <String, List<Word>>{};
    for (final word in words) {
      byCategory.putIfAbsent(word.category, () => <Word>[]).add(word);
    }

    final mixed = <_PracticeQuestion>[];
    mixed.addAll(_buildMeaningToWordQuestions(byCategory['core'] ?? const []));
    mixed.addAll(
      _buildMeaningToWordQuestions(byCategory['advanced'] ?? const []),
    );
    mixed.addAll(_buildSynonymQuestions(byCategory['synonyms'] ?? const []));
    mixed.addAll(_buildIdiomQuestions(byCategory['idioms'] ?? const []));
    mixed.addAll(_buildOneWordQuestions(byCategory['oneword'] ?? const []));
    mixed.addAll(_buildConfusingQuestions(byCategory['confusing'] ?? const []));
    return mixed;
  }

  List<_PracticeQuestion> _buildMeaningToWordQuestions(List<Word> words) {
    final wordPool = words
        .map((word) => word.word.trim())
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList();

    final questions = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.meaningEn.trim().isEmpty || word.word.trim().isEmpty) continue;
      final options = _buildOptions(word.word.trim(), wordPool);
      if (options.length < 4) continue;
      questions.add(
        _PracticeQuestion(
          prompt: 'Choose the correct word:\n${word.meaningEn}',
          options: options,
          correctAnswer: word.word.trim(),
        ),
      );
    }
    return questions;
  }

  List<_PracticeQuestion> _buildSynonymQuestions(List<Word> words) {
    final synonymPool = words
        .expand((word) => word.synonyms)
        .map((synonym) => synonym.trim())
        .where((synonym) => synonym.isNotEmpty)
        .toSet()
        .toList();

    final questions = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.synonyms.isEmpty) continue;
      final correct = word.synonyms.first.trim();
      if (correct.isEmpty) continue;
      final options = _buildOptions(correct, synonymPool);
      if (options.length < 4) continue;
      questions.add(
        _PracticeQuestion(
          prompt: 'Select the best synonym for:\n${word.word}',
          options: options,
          correctAnswer: correct,
        ),
      );
    }
    return questions;
  }

  List<_PracticeQuestion> _buildIdiomQuestions(List<Word> words) {
    final meaningPool = words
        .map((word) => word.meaningEn.trim())
        .where((meaning) => meaning.isNotEmpty)
        .toSet()
        .toList();

    final questions = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.meaningEn.trim().isEmpty) continue;
      final options = _buildOptions(word.meaningEn.trim(), meaningPool);
      if (options.length < 4) continue;
      questions.add(
        _PracticeQuestion(
          prompt: 'What does this idiom mean?\n${word.word}',
          options: options,
          correctAnswer: word.meaningEn.trim(),
        ),
      );
    }
    return questions;
  }

  List<_PracticeQuestion> _buildOneWordQuestions(List<Word> words) {
    final oneWordPool = words
        .map((word) => word.word.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    final questions = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.meaningEn.trim().isEmpty || word.word.trim().isEmpty) continue;
      final options = _buildOptions(word.word.trim(), oneWordPool);
      if (options.length < 4) continue;
      questions.add(
        _PracticeQuestion(
          prompt: 'Select the one-word substitution:\n${word.meaningEn}',
          options: options,
          correctAnswer: word.word.trim(),
        ),
      );
    }
    return questions;
  }

  List<_PracticeQuestion> _buildConfusingQuestions(List<Word> words) {
    final meaningPool = words
        .map((word) => word.meaningEn.trim())
        .where((meaning) => meaning.isNotEmpty)
        .toSet()
        .toList();

    final questions = <_PracticeQuestion>[];
    for (final word in words) {
      if (word.word.trim().isEmpty || word.meaningEn.trim().isEmpty) continue;
      final options = _buildOptions(word.meaningEn.trim(), meaningPool);
      if (options.length < 4) continue;
      questions.add(
        _PracticeQuestion(
          prompt: 'Choose the correct meaning for:\n${word.word}',
          options: options,
          correctAnswer: word.meaningEn.trim(),
        ),
      );
    }
    return questions;
  }

  List<String> _buildOptions(String correct, List<String> pool) {
    final options = <String>{correct};
    final candidates = pool.where((item) => item != correct).toList()
      ..shuffle(_random);
    for (final candidate in candidates) {
      if (options.length >= 4) break;
      options.add(candidate);
    }
    return options.toList()..shuffle(_random);
  }

  void _selectOption(int index) {
    if (selectedIndex != null) return;
    final question = questions[currentIndex];
    final selected = question.options[index];
    final isCorrectSelection = selected == question.correctAnswer;

    setState(() {
      selectedIndex = index;
      if (isCorrectSelection) {
        correctCount++;
      }
    });

    if (!isCorrectSelection) {
      saveWeakAttempt(
        widget.category,
        WeakAttempt(
          prompt: question.prompt,
          correctAnswer: question.correctAnswer,
          selectedAnswer: selected,
          category: widget.category,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _next() {
    if (selectedIndex == null) return;
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
      });
      return;
    }
    _showResult();
  }

  void _restartCurrentSet() {
    setState(() {
      currentIndex = 0;
      selectedIndex = null;
      correctCount = 0;
    });
  }

  Future<void> _startNewSet() async {
    if (isProcessingNewSet) return;

    setState(() {
      isProcessingNewSet = true;
    });

    if (!premiumUnlocked) {
      final allowed = await consumePracticeSession(
        widget.category,
        mixed: _isMixedQuiz,
      );
      final remaining = await getRemainingPracticeSessions(
        widget.category,
        mixed: _isMixedQuiz,
      );

      if (!mounted) return;

      if (!allowed) {
        setState(() {
          remainingSessions = remaining;
          isLocked = true;
          isProcessingNewSet = false;
        });
        return;
      }

      setState(() {
        remainingSessions = remaining;
      });
    }

    setState(() {
      questions = _pickNextSet(excludeCurrentSet: true);
      currentIndex = 0;
      selectedIndex = null;
      correctCount = 0;
      isProcessingNewSet = false;
    });
  }

  Future<void> _showResult() async {
    final total = questions.length;
    final percent = total == 0 ? 0 : ((correctCount / total) * 100).round();
    final incorrectCount = total - correctCount;

    await updateBestPracticeStats(
      widget.category,
      score: correctCount,
      accuracy: percent,
    );

    if (!mounted) return;
    setState(() {
      bestScore = getStoredBestScore(widget.category);
      bestAccuracy = getStoredBestAccuracy(widget.category);
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Practice Complete'),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ResultStatCard(
                      label: 'Score',
                      value: '$correctCount/$total',
                      valueColor: const Color(0xFF0F172A),
                      backgroundColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultStatCard(
                      label: 'Accuracy',
                      value: '$percent%',
                      valueColor: const Color(0xFF0F766E),
                      backgroundColor: const Color(0xFFF0FDFA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ResultStatCard(
                      label: 'Correct',
                      value: '$correctCount',
                      valueColor: const Color(0xFF15803D),
                      backgroundColor: const Color(0xFFF0FDF4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultStatCard(
                      label: 'Incorrect',
                      value: '$incorrectCount',
                      valueColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best Performance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Best Score: $bestScore/$total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Best Accuracy: $bestAccuracy%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose your next step',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isMixedQuiz
                          ? 'Repeat Same Set keeps these questions. New Set uses another daily mixed quiz session.'
                          : 'Repeat Same Set keeps these questions. New Set uses one more daily practice session.',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      premiumUnlocked
                          ? 'Premium active: unlimited new sets.'
                          : 'Remaining new sets today: $remainingSessions',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(this.context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _restartCurrentSet();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1F3C6D)),
                      foregroundColor: const Color(0xFF1F3C6D),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Repeat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessingNewSet
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _startNewSet();
                      },
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Start New Set'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3C6D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_PracticeQuestion> _pickNextSet({bool excludeCurrentSet = false}) {
    if (allQuestions.isEmpty) return [];
    final pool = List<_PracticeQuestion>.from(allQuestions);

    if (excludeCurrentSet && questions.isNotEmpty) {
      final currentPrompts = questions.map((question) => question.prompt).toSet();
      final filtered = pool
          .where((question) => !currentPrompts.contains(question.prompt))
          .toList();
      if (filtered.length >= _questionLimit) {
        filtered.shuffle(_random);
        return filtered.take(_questionLimit).toList();
      }
    }

    pool.shuffle(_random);
    return pool.take(_questionLimit).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F3C6D),
          foregroundColor: Colors.white,
          title: Text('${widget.title} Practice'),
        ),
        body: Center(
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
                      color: Color(0xFFF59E0B),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isMixedQuiz
                        ? 'Daily mixed quiz limit reached'
                        : 'Daily practice limit reached',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isMixedQuiz
                        ? 'Free plan includes $freeMixedQuizAttemptsPerDay Take a Quiz session per day. Unlock premium for unlimited mixed quizzes.'
                        : 'Free plan includes $freePracticeAttemptsPerDay practice sessions per category each day. Unlock premium for unlimited practice.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Remaining today: $remainingSessions',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
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
                      ).then((_) {
                        if (mounted) {
                          setState(() {
                            isLoading = true;
                          });
                          _initializePractice();
                        }
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
        appBar: AppBar(
          title: const Text('Practice'),
          backgroundColor: const Color(0xFF1F3C6D),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Not enough data to generate practice questions.',
            style: TextStyle(color: Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final question = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;
    final showFreeTierInfo = !premiumUnlocked;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C6D),
        foregroundColor: Colors.white,
        title: Text('${widget.title} Practice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Best Score',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$bestScore/${questions.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Best Accuracy',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$bestAccuracy%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showFreeTierInfo) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isMixedQuiz
                            ? '$remainingSessions mixed quiz session left today.'
                            : '$remainingSessions free practice sessions left today in this category.',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Question ${currentIndex + 1} of ${questions.length}',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                question.prompt,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final isSelected = selectedIndex == index;
                  final isCorrect = option == question.correctAnswer;
                  var borderColor = const Color(0xFFE2E8F0);
                  var backgroundColor = Colors.white;

                  if (selectedIndex != null) {
                    if (isCorrect) {
                      borderColor = const Color(0xFF16A34A);
                      backgroundColor = const Color(0xFFECFDF3);
                    } else if (isSelected) {
                      borderColor = const Color(0xFFDC2626);
                      backgroundColor = const Color(0xFFFEECEC);
                    }
                  }

                  return GestureDetector(
                    onTap: () => _selectOption(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: selectedIndex == null ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F3C6D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                currentIndex == questions.length - 1 ? 'Finish' : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeQuestion {
  final String prompt;
  final List<String> options;
  final String correctAnswer;

  const _PracticeQuestion({
    required this.prompt,
    required this.options,
    required this.correctAnswer,
  });
}

class _ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color backgroundColor;

  const _ResultStatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}


