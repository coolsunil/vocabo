import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo/models/word_model.dart';
import 'package:vocabo/screens/practice_screen.dart';

void main() {
  test('voice and narration practice uses the stored grammar answer set', () {
    final words = [
      Word(
        word: "She writes a letter.",
        meaningHi: '',
        meaningEn: 'Simple Present → Passive',
        example: 'A letter is written by her.',
        synonyms: const [],
        antonyms: const [],
        confusionWith: const [],
        category: 'voices',
        options: const [
          'A letter is written by her.',
          'A letter was written by her.',
          'A letter is being written by her.',
          'A letter has been written by her.',
        ],
      ),
      Word(
        word: "He said, 'I am very tired.'",
        meaningHi: '',
        meaningEn: 'Simple Present → Past',
        example: 'He said that he was very tired.',
        synonyms: const [],
        antonyms: const [],
        confusionWith: const [],
        category: 'narration',
        options: const [
          'He said that he was very tired.',
          'He said that he is very tired.',
          'He told that he was very tired.',
          'He said that I was very tired.',
        ],
      ),
    ];

    final questions = buildGrammarQuestionSpecsForCategory(words, Random(1));

    expect(questions.length, 2);
    expect(questions[0]['correctAnswer'], 'A letter is written by her.');
    expect(questions[1]['correctAnswer'], 'He said that he was very tired.');
    expect(questions[0]['options'], contains('A letter is written by her.'));
    expect(
      questions[1]['options'],
      contains('He said that he was very tired.'),
    );
  });
}
