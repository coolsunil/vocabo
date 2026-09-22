class HighlightedWord {
  final String word;
  final String meaningEn;
  final String meaningHi;
  final String example;

  const HighlightedWord({
    required this.word,
    required this.meaningEn,
    required this.meaningHi,
    required this.example,
  });

  factory HighlightedWord.fromJson(Map<String, dynamic> json) => HighlightedWord(
        word: json['word'] as String,
        meaningEn: json['meaning_en'] as String,
        meaningHi: json['meaning_hi'] as String,
        example: json['example'] as String,
      );
}

class Article {
  final String id;
  final String title;
  final String topic;
  final int readTime;
  final String body;
  final List<HighlightedWord> highlightedWords;

  const Article({
    required this.id,
    required this.title,
    required this.topic,
    required this.readTime,
    required this.body,
    required this.highlightedWords,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        title: json['title'] as String,
        topic: json['topic'] as String,
        readTime: json['read_time'] as int,
        body: json['article'] as String,
        highlightedWords: (json['highlighted_words'] as List<dynamic>)
            .map((e) => HighlightedWord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
