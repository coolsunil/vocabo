class PYQQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String exam;
  final String year;
  final String topic;
  final String difficulty;
  final String explanation;

  const PYQQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.exam,
    required this.year,
    this.topic = '',
    this.difficulty = '',
    this.explanation = '',
  });

  factory PYQQuestion.fromJson(Map<String, dynamic> json) {
    return PYQQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correct_answer'] as String,
      exam: json['exam'] as String,
      year: json['year'] as String,
      topic: (json['topic'] as String?) ?? '',
      difficulty: (json['difficulty'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}
