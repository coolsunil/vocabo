class Word {
  final String word;
  final String meaningHi;
  final String meaningEn;
  final String example;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> confusionWith;
  final String category;
  final String spellingTip;
  final List<String> options;
  final String origin;

  Word({
    required this.word,
    required this.meaningHi,
    required this.meaningEn,
    required this.example,
    required this.synonyms,
    required this.antonyms,
    required this.confusionWith,
    required this.category,
    this.spellingTip = '',
    this.options = const [],
    this.origin = '',
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      // common_errors → "wrong", sentence_improvement → "question", cloze_test → "sentence"
      word: json['word'] ?? json['wrong'] ?? json['question'] ?? json['sentence'] ?? '',
      // common_errors / sentence_improvement → "explanation_hi"
      meaningHi: json['meaning_hi'] ?? json['explanation_hi'] ?? '',
      // common_errors / sentence_improvement → "explanation_en"
      meaningEn: json['meaning_en'] ?? json['explanation_en'] ?? '',
      // common_errors / sentence_improvement → "correct", cloze_test → "answer"
      example: json['example'] ?? json['correct'] ?? json['answer'] ?? json['phrase'] ?? '',
      synonyms: json['synonyms'] != null
          ? List<String>.from(json['synonyms'])
          : <String>[],
      antonyms: json['antonyms'] != null
          ? List<String>.from(json['antonyms'])
          : <String>[],
      confusionWith: json['confusion_with'] != null
          ? List<String>.from(json['confusion_with'])
          : <String>[],
      category: json['category'] ?? '',
      spellingTip: json['spelling_tip'] ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : <String>[],
      origin: json['origin'] ?? '',
    );
  }
}
