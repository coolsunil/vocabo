import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/category_sources.dart';
import '../data/premium_store.dart';
import '../data/pyq_progress_store.dart';
import '../models/pyq_question.dart';
import '../utils/app_colors.dart';
import '../widgets/interactive_pressable.dart';

// ── Exam definitions ──────────────────────────────────────────────────────────

class _ExamInfo {
  final String name;
  final String fullName;
  final String file;
  final List<Color> gradient;
  final IconData icon;

  const _ExamInfo({
    required this.name,
    required this.fullName,
    required this.file,
    required this.gradient,
    required this.icon,
  });
}

const _exams = [
  _ExamInfo(
    name: 'SSC',
    fullName: 'CGL · CHSL · CPO · MTS',
    file: 'assets/data/pyq_ssc.json',
    gradient: [Color(0xFF1F3C6D), Color(0xFF2563EB)],
    icon: Icons.school_rounded,
  ),
  _ExamInfo(
    name: 'IBPS',
    fullName: 'PO · Clerk',
    file: 'assets/data/pyq_ibps.json',
    gradient: [Color(0xFF064E3B), Color(0xFF059669)],
    icon: Icons.account_balance_rounded,
  ),
  _ExamInfo(
    name: 'SBI',
    fullName: 'PO · Clerk',
    file: 'assets/data/pyq_sbi.json',
    gradient: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
    icon: Icons.currency_rupee_rounded,
  ),
  _ExamInfo(
    name: 'AFCAT',
    fullName: 'Air Force Common Admission Test',
    file: 'assets/data/pyq_afcat.json',
    gradient: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
    icon: Icons.flight_rounded,
  ),
  _ExamInfo(
    name: 'UPSC',
    fullName: 'CDS · NDA · CSAT',
    file: 'assets/data/pyq_upsc.json',
    gradient: [Color(0xFF701A75), Color(0xFFC026D3)],
    icon: Icons.account_balance_outlined,
  ),
  _ExamInfo(
    name: 'CLAT',
    fullName: 'Common Law Admission Test',
    file: 'assets/data/pyq_clat.json',
    gradient: [Color(0xFF1E1B4B), Color(0xFF6366F1)],
    icon: Icons.gavel_rounded,
  ),
  _ExamInfo(
    name: 'UPSSSC PET',
    fullName: 'UP Subordinate Services',
    file: 'assets/data/pyq_upsssc_pet.json',
    gradient: [Color(0xFF7C2D12), Color(0xFFEA580C)],
    icon: Icons.assignment_rounded,
  ),
  _ExamInfo(
    name: 'Insurance',
    fullName: 'LIC · NIACL · ESIC · NICL',
    file: 'assets/data/pyq_insurance.json',
    gradient: [Color(0xFF0D1B2A), Color(0xFF1565C0)],
    icon: Icons.shield_rounded,
  ),
  _ExamInfo(
    name: 'UPPSC',
    fullName: 'UP Public Service Commission',
    file: 'assets/data/pyq_uppsc.json',
    gradient: [Color(0xFF0C3D3D), Color(0xFF0F766E)],
    icon: Icons.how_to_reg_rounded,
  ),
  _ExamInfo(
    name: 'Supreme Court',
    fullName: 'Junior Court Assistant (JCA)',
    file: 'assets/data/pyq_supreme_court.json',
    gradient: [Color(0xFF4C0519), Color(0xFF9F1239)],
    icon: Icons.balance_rounded,
  ),
  _ExamInfo(
    name: 'RBI Grade B',
    fullName: 'Reserve Bank of India',
    file: 'assets/data/pyq_rbi_grade_b.json',
    gradient: [Color(0xFF713F12), Color(0xFFCA8A04)],
    icon: Icons.savings_rounded,
  ),
  _ExamInfo(
    name: 'CSIR JSA',
    fullName: 'Junior Secretariat Assistant',
    file: 'assets/data/pyq_csir_jsa.json',
    gradient: [Color(0xFF1A3A1A), Color(0xFF2E7D32)],
    icon: Icons.science_rounded,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PYQScreen extends StatefulWidget {
  const PYQScreen({super.key});

  @override
  State<PYQScreen> createState() => _PYQScreenState();
}

class _PYQScreenState extends State<PYQScreen> {
  // Phase tracking
  _ExamInfo? _selectedExam;
  bool _inQuiz = false;

  // Quiz state
  bool _isLoading = false;
  List<PYQQuestion> _allQuestions = [];
  List<PYQQuestion> _questions = [];
  List<String> _availableYears = [];
  String? _selectedYear;
  List<String> _availableSubExams = [];
  String? _selectedSubExam;
  List<int?> _allSelections = []; // parallel to _allQuestions
  List<int?> _selections = [];   // parallel to _questions (current view)
  int _currentIndex = 0;
  bool _quizDone = false;

  bool get _isPremium => premiumUnlocked;
  bool get _isLocked => !_isPremium && _currentIndex >= freePYQLimit;

  Future<void> _loadAndStart(_ExamInfo exam, {bool fresh = false}) async {
    if (fresh) await clearPYQSession(exam.name);
    setState(() {
      _isLoading = true;
      _selectedExam = exam;
    });
    try {
      final raw = await rootBundle.loadString(exam.file);
      final list = json.decode(raw) as List;
      final questions =
          list.map((e) => PYQQuestion.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _isLoading = false;
          _selectedExam = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions added yet. Check back soon!')),
        );
        return;
      }
      final years = questions.map((q) => q.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      final subExams = questions.map((q) => q.exam).toSet().toList()..sort();
      final resumeIndex = fresh
          ? 0
          : getPYQResumeIndex(exam.name).clamp(0, questions.length - 1);
      final allSel = List<int?>.filled(questions.length, null);
      if (!fresh) {
        for (final e in getPYQSelections(exam.name).entries) {
          if (e.key < questions.length) allSel[e.key] = e.value;
        }
      }
      setState(() {
        _allQuestions = questions;
        _allSelections = allSel;
        _availableYears = years;
        _availableSubExams = subExams;
        _selectedYear = null;
        _selectedSubExam = null;
        _questions = questions;
        _selections = List.from(allSel);
        _currentIndex = resumeIndex;
        _quizDone = false;
        _inQuiz = true;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetToHub() {
    if (_selectedExam != null) {
      savePYQResumeIndex(_selectedExam!.name, _currentIndex);
    }
    setState(() {
      _inQuiz = false;
      _quizDone = false;
      _selectedExam = null;
      _allQuestions = [];
      _allSelections = [];
      _questions = [];
      _availableYears = [];
      _selectedYear = null;
      _availableSubExams = [];
      _selectedSubExam = null;
      _selections = [];
      _currentIndex = 0;
    });
  }

  List<PYQQuestion> _filtered(String? subExam, String? year) {
    return _allQuestions.where((q) {
      return (subExam == null || q.exam == subExam) &&
          (year == null || q.year == year);
    }).toList();
  }

  List<int?> _selectionsFor(List<PYQQuestion> filtered) {
    return filtered.map((q) {
      final idx = _allQuestions.indexOf(q);
      return idx >= 0 ? _allSelections[idx] : null;
    }).toList();
  }

  void _applySubExamFilter(String? subExam) {
    final f = _filtered(subExam, _selectedYear);
    setState(() {
      _selectedSubExam = subExam;
      _questions = f;
      _selections = _selectionsFor(f);
      _currentIndex = 0;
    });
  }

  void _applyYearFilter(String? year) {
    final f = _filtered(_selectedSubExam, year);
    setState(() {
      _selectedYear = year;
      _questions = f;
      _selections = _selectionsFor(f);
      _currentIndex = 0;
    });
  }

  bool get _hasActiveFilter => _selectedSubExam != null || _selectedYear != null;

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Count preview — recompute as user taps chips
          final previewCount = _filtered(_selectedSubExam, _selectedYear).length;

          void tapSubExam(String? val) {
            _applySubExamFilter(val);
            setSheetState(() {});
          }

          void tapYear(String? val) {
            _applyYearFilter(val);
            setSheetState(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Filter Questions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (_hasActiveFilter)
                      TextButton(
                        onPressed: () {
                          _applySubExamFilter(null);
                          _applyYearFilter(null);
                          setSheetState(() {});
                        },
                        child: const Text('Clear all',
                            style: TextStyle(color: Color(0xFFDC2626))),
                      ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close_rounded,
                          color: ctx.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_availableSubExams.length > 1) ...[
                  Text('Sub-exam',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ctx.textSecondary)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(null, 'All', _selectedSubExam, tapSubExam),
                        ..._availableSubExams.map((e) {
                          final prefix = '${_selectedExam!.name} ';
                          final label = e.startsWith(prefix)
                              ? e.substring(prefix.length)
                              : e;
                          return _filterChip(
                              e, label, _selectedSubExam, tapSubExam);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_availableYears.length > 1) ...[
                  Text('Year',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ctx.textSecondary)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(null, 'All', _selectedYear, tapYear),
                        ..._availableYears.map(
                            (y) => _filterChip(y, y, _selectedYear, tapYear)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ctx.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 16, color: _accent),
                      const SizedBox(width: 8),
                      Text(
                        '$previewCount question${previewCount == 1 ? '' : 's'} match your filters',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _select(int optionIndex) {
    if (_selections[_currentIndex] != null) return;
    final globalIdx = _allQuestions.indexOf(_questions[_currentIndex]);
    setState(() {
      _selections[_currentIndex] = optionIndex;
      if (globalIdx >= 0) _allSelections[globalIdx] = optionIndex;
    });
    if (globalIdx >= 0) {
      savePYQSelection(_selectedExam!.name, globalIdx, optionIndex);
    }
    final answered = _allSelections.where((s) => s != null).length;
    savePYQProgress(_selectedExam!.name, answered);
    savePYQResumeIndex(_selectedExam!.name, _currentIndex);
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else if (!_isPremium && _currentIndex < freePYQLimit) {
      setState(() => _currentIndex++);
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _showQuestionGrid(int total) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Jump to Question',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close_rounded,
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _gridLegend(context.cardBg, context.borderSubtle,
                          'Unanswered', textColor: context.textSecondary),
                      const SizedBox(width: 16),
                      _gridLegend(
                          const Color(0xFF1F3C6D), const Color(0xFF1F3C6D),
                          'Answered',
                          textColor: Colors.white),
                      const SizedBox(width: 16),
                      _gridLegend(
                          const Color(0xFF22C55E).withValues(alpha: 0.15),
                          const Color(0xFF22C55E),
                          'Current', textColor: context.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: total,
              itemBuilder: (_, i) {
                final isAnswered =
                    _selections.length > i && _selections[i] != null;
                final isCurrent = i == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = i);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                          : isAnswered
                              ? const Color(0xFF1F3C6D)
                              : context.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF22C55E)
                            : isAnswered
                                ? const Color(0xFF1F3C6D)
                                : context.borderSubtle,
                        width: isCurrent ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isAnswered && !isCurrent
                              ? Colors.white
                              : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _gridLegend(Color bg, Color border, String label,
      {Color textColor = const Color(0xFF334155)}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: textColor)),
      ],
    );
  }

  int get _correctCount => _selections
      .asMap()
      .entries
      .where((e) =>
          e.value != null &&
          _questions[e.key].options[e.value!] == _questions[e.key].correctAnswer)
      .length;

  // ── Colors ──────────────────────────────────────────────────────────────────

  Color get _accent => _selectedExam?.gradient.last ?? const Color(0xFF2563EB);

  Color _optionBg(BuildContext context, int idx) {
    final selected = _selections[_currentIndex];
    if (selected == null) return context.cardBg;
    final correct = _questions[_currentIndex].correctAnswer;
    final isCorrect = _questions[_currentIndex].options[idx] == correct;
    final correctBg = context.isDark
        ? const Color(0xFF16A34A).withValues(alpha: 0.2)
        : const Color(0xFFDCFCE7);
    final wrongBg = context.isDark
        ? const Color(0xFFDC2626).withValues(alpha: 0.2)
        : const Color(0xFFFEE2E2);
    if (idx == selected) return isCorrect ? correctBg : wrongBg;
    if (isCorrect) return correctBg;
    return context.cardBg;
  }

  Color _optionBorder(BuildContext context, int idx) {
    final selected = _selections[_currentIndex];
    if (selected == null) return context.borderSubtle;
    final correct = _questions[_currentIndex].correctAnswer;
    final isCorrect = _questions[_currentIndex].options[idx] == correct;
    if (idx == selected) {
      return isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    }
    if (isCorrect) return const Color(0xFF16A34A);
    return context.borderSubtle;
  }

  void _shareQuestion() {
    if (_questions.isEmpty) return;
    final q = _questions[_currentIndex];
    final optionLabels = ['A', 'B', 'C', 'D'];
    final optionsText = q.options
        .asMap()
        .entries
        .map((e) => '${optionLabels[e.key]}) ${e.value}')
        .join('\n');
    final topicLine = [
      if (q.topic.isNotEmpty) q.topic,
      '${q.exam} ${q.year}',
      if (q.difficulty.isNotEmpty) q.difficulty,
    ].join(' · ');

    final text = '''🧠 Can you crack this?

${q.question}

$optionsText

📌 $topicLine

— Vocabo''';

    Share.share(text);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _inQuiz ? const Color(0xFF1F3C6D) : Colors.transparent,
        foregroundColor: _inQuiz ? Colors.white : context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _inQuiz ? '${_selectedExam!.name} PYQs' : 'Previous Year Questions',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_inQuiz) {
              _resetToHub();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_inQuiz && !_quizDone) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareQuestion,
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt_rounded),
                  onPressed: _showFilterSheet,
                ),
                if (_hasActiveFilter)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inQuiz
              ? (_quizDone ? _buildResult() : _buildQuiz())
              : _buildHub(),
    );
  }

  // ── Hub ──────────────────────────────────────────────────────────────────────

  Widget _buildHub() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose an Exam',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Practice real questions from previous papers',
            style: TextStyle(fontSize: 14, color: context.textSecondary),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: _exams
                .map((exam) => _ExamGridCard(
                      exam: exam,
                      onTap: () => _loadAndStart(exam),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: context.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPremium
                        ? 'All questions unlocked — Premium active'
                        : 'First $freePYQLimit questions free per exam · Upgrade for unlimited access',
                    style: TextStyle(
                        fontSize: 12, color: context.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz ──────────────────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    if (_isLocked) return _buildPremiumLock();

    final q = _questions[_currentIndex];
    final total = _isPremium ? _questions.length : freePYQLimit;
    final navBtnColor = context.isDark ? const Color(0xFF60A5FA) : const Color(0xFF1F3C6D);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress row
          Row(
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: TextStyle(
                    color: context.textSecondary, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (!_isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '${freePYQLimit - _currentIndex - 1} free left',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: context.borderSubtle,
            color: _accent,
          ),
          const SizedBox(height: 10),
          // Active filter indicator
          if (_hasActiveFilter) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt_rounded, size: 14, color: _accent),
                  const SizedBox(width: 6),
                  Text(
                    [
                      if (_selectedSubExam != null)
                        () {
                          final prefix = '${_selectedExam!.name} ';
                          return _selectedSubExam!.startsWith(prefix)
                              ? _selectedSubExam!.substring(prefix.length)
                              : _selectedSubExam!;
                        }(),
                      ?_selectedYear,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      _applySubExamFilter(null);
                      _applyYearFilter(null);
                    },
                    child: Icon(Icons.close_rounded, size: 14, color: _accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (q.topic.isNotEmpty)
                _buildTag(q.topic, const Color(0xFF16A34A),
                    Icons.label_outline_rounded),
              if (q.difficulty.isNotEmpty)
                _buildTag(q.difficulty, const Color(0xFFD97706),
                    Icons.signal_cellular_alt_rounded),
              _buildTag('${q.exam} · ${q.year}',
                  _selectedExam!.gradient.last, _selectedExam!.icon),
            ],
          ),
          const SizedBox(height: 14),
          // Question card + options + explanation — all scrollable together
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Passage card (CLAT-style comprehension)
                  if (q.passage.isNotEmpty) ...[
                    _PassageCard(passage: q.passage, accent: _accent),
                    const SizedBox(height: 12),
                  ],
                  // Question card — practice style
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F3C6D),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            'Q${_currentIndex + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.question,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...q.options.asMap().entries.map((e) {
                    final idx = e.key;
                    final label = String.fromCharCode(65 + idx);
                    final selected = _selections[_currentIndex];
                    final isSelected = selected == idx;
                    final isCorrectOption =
                        _questions[_currentIndex].options[idx] ==
                            _questions[_currentIndex].correctAnswer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: selected == null ? () => _select(idx) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(14),
                          constraints: const BoxConstraints(minHeight: 56),
                          decoration: BoxDecoration(
                            color: _optionBg(context, idx),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _optionBorder(context, idx),
                              width: isSelected || (selected != null && isCorrectOption) ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected != null && isCorrectOption
                                      ? const Color(0xFF16A34A)
                                      : isSelected && selected != null
                                          ? const Color(0xFFDC2626)
                                          : isSelected
                                              ? const Color(0xFF1F3C6D)
                                              : context.surfaceMuted,
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: (selected != null && isCorrectOption) ||
                                              (isSelected && selected != null) ||
                                              isSelected
                                          ? Colors.white
                                          : context.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected
                                        ? _optionBorder(context, idx)
                                        : context.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_selections[_currentIndex] != null) ...[
                    const SizedBox(height: 8),
                    _buildExplanationCard(q, total),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Prev / Grid / Next row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0 ? _goPrev : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Prev'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: navBtnColor),
                    foregroundColor: navBtnColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledForegroundColor: const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _showQuestionGrid(total),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: navBtnColor),
                  foregroundColor: navBtnColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                child: const Icon(Icons.grid_view_rounded, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (!_isPremium && _currentIndex < freePYQLimit) || _currentIndex < _questions.length - 1
                      ? _goNext
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next'),
                  iconAlignment: IconAlignment.end,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: navBtnColor),
                    foregroundColor: navBtnColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledForegroundColor: const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => _quizDone = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F3C6D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'Finish  (${_selections.where((s) => s != null).length}/${_questions.length} answered)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label, String? selectedValue,
      void Function(String?) onTap) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _accent : context.cardBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? _accent : context.borderMedium,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color, IconData icon) {
    final dark = Color.lerp(color, Colors.black, 0.25)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [dark, color],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(PYQQuestion q, int total) {
    final selected = _selections[_currentIndex]!;
    final isCorrect = q.options[selected] == q.correctAnswer;
    final cardColor = isCorrect
        ? (context.isDark
            ? const Color(0xFF16A34A).withValues(alpha: 0.15)
            : const Color(0xFFDCFCE7))
        : (context.isDark
            ? const Color(0xFFDC2626).withValues(alpha: 0.15)
            : const Color(0xFFFEE2E2));
    final borderColor =
        isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final iconColor =
        isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon =
        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 4),
            Text(
              'Correct answer: ${q.correctAnswer}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              q.explanation,
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final total = _selections.where((s) => s != null).length;
    final correct = _correctCount;
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final gradient = _selectedExam!.gradient;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$correct out of $total correct',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedExam!.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _loadAndStart(_selectedExam!, fresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradient.last,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Retry This Exam',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetToHub,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Choose Another Exam',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Premium lock ──────────────────────────────────────────────────────────────

  Widget _buildPremiumLock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 36, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 20),
            Text(
              'Unlock All PYQs',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve completed $freePYQLimit free questions.\nUpgrade to access all questions from every exam.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PremiumScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('View Premium Plans',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _quizDone = true),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('See My Results',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Passage card (for comprehension-based exams like CLAT) ───────────────────

class _PassageCard extends StatefulWidget {
  final String passage;
  final Color accent;

  const _PassageCard({required this.passage, required this.accent});

  @override
  State<_PassageCard> createState() => _PassageCardState();
}

class _PassageCardState extends State<_PassageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.08),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(14))
                    : BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.article_outlined, size: 16, color: widget.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Read Passage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.accent,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: widget.accent,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                widget.passage,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.65,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// ── Exam grid card widget ─────────────────────────────────────────────────────

class _ExamGridCard extends StatelessWidget {
  final _ExamInfo exam;
  final VoidCallback onTap;

  const _ExamGridCard({required this.exam, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final attempted = getPYQProgress(exam.name);
    return InteractivePressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      overlayColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: exam.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: exam.gradient.last.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                exam.icon,
                size: 90,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(exam.icon, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      if (attempted > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$attempted done',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    exam.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    exam.fullName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.80),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
