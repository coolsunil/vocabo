class Word {
  final String word;
  final String meaningHi;
  final String meaningEn;
  final String example;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> confusionWith;
  final String category;

  Word({
    required this.word,
    required this.meaningHi,
    required this.meaningEn,
    required this.example,
    required this.synonyms,
    required this.antonyms,
    required this.confusionWith,
    required this.category,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      word: json['word'] ?? '',
      meaningHi: json['meaning_hi'] ?? '',
      meaningEn: json['meaning_en'] ?? '',
      example: json['example'] ?? '', // safe if missing
      synonyms: json['synonyms'] != null
          ? List<String>.from(json['synonyms'])
          : <String>[], // safe if missing
      antonyms: json['antonyms'] != null
          ? List<String>.from(json['antonyms'])
          : <String>[], // safe if missing
      confusionWith: json['confusion_with'] != null
          ? List<String>.from(json['confusion_with'])
          : <String>[],
      category: json['category'] ?? '',
    );
  }
}
