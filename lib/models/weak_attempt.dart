class WeakAttempt {
  final String prompt;
  final String correctAnswer;
  final String selectedAnswer;
  final String category;
  final DateTime updatedAt;

  const WeakAttempt({
    required this.prompt,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.category,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'correct_answer': correctAnswer,
      'selected_answer': selectedAnswer,
      'category': category,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WeakAttempt.fromJson(Map<String, dynamic> json) {
    return WeakAttempt(
      prompt: json['prompt'] ?? '',
      correctAnswer: json['correct_answer'] ?? '',
      selectedAnswer: json['selected_answer'] ?? '',
      category: json['category'] ?? '',
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
