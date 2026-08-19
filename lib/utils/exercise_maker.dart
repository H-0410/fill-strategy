import 'dart:math';

import '../models/question.dart';
import '../models/word.dart';

class ExerciseMaker {
  /// The first filter is intentionally groupId-only. No word outside the
  /// selected groups can enter.
  static List<ExerciseQuestion> make({
    required List<WordGroup> groups,
    required List<int> selectedGroupIds,
    required ExerciseMode mode,
    required int count,
    required bool shuffle,
  }) {
    final selected = groups
        .where((group) => selectedGroupIds.contains(group.id))
        .toList();
    final pool = selected.expand((group) => group.words).toList();
    if (pool.isEmpty) {
      return const [];
    }

    final random = Random();
    if (shuffle) {
      pool.shuffle(random);
    }

    final chosen = pool.take(min(count, pool.length)).toList();
    return chosen.map((word) {
      final optionWords = _optionWords(word, selected, pool, random, mode);
      final options = optionWords
          .map((item) => mode == ExerciseMode.wordToEmphasis
              ? item.emphasis
              : item.name)
          .toList();
      final correct = optionWords.indexWhere((item) => item.name == word.name);
      return ExerciseQuestion(
        word: word,
        prompt: _prompt(word, mode),
        options: options,
        optionWords: optionWords,
        correctIndex: correct < 0 ? 0 : correct,
        mode: mode,
      );
    }).toList();
  }

  static String _prompt(WordEntry word, ExerciseMode mode) {
    switch (mode) {
      case ExerciseMode.emphasisToWord:
        return '根据侧重点选择最恰当的词语：\n${word.emphasis}';
      case ExerciseMode.wordToEmphasis:
        return '请选择「${word.name}」的正确侧重点';
      case ExerciseMode.confusing:
        return '${word.sentence.replaceAll(word.name, '____')}\n请选择最恰当的词语';
      case ExerciseMode.examBlank:
        final sentence = word.examSentence.isEmpty
            ? word.sentence
            : word.examSentence;
        return '${sentence.replaceAll(word.name, '____')}\n请选择最恰当的词语';
    }
  }

  static List<WordEntry> _optionWords(
    WordEntry word,
    List<WordGroup> selected,
    List<WordEntry> pool,
    Random random,
    ExerciseMode mode,
  ) {
    if (mode == ExerciseMode.wordToEmphasis) {
      final same = pool.where((item) => item.name != word.name).toList()
        ..shuffle(random);
      return [word, ...same.take(3)].toList()..shuffle(random);
    }

    final sameGroup = selected
        .firstWhere((group) => group.id == word.groupId)
        .words
        .where((item) => item.name != word.name)
        .toList();
    final preferred = <WordEntry>[];
    for (final name in word.compareWords) {
      for (final candidate in sameGroup) {
        if (candidate.name == name && !preferred.contains(candidate)) {
          preferred.add(candidate);
        }
      }
    }

    final candidates = [
      ...preferred,
      ...sameGroup.where((item) => !preferred.contains(item)),
      ...pool.where((item) => item.groupId != word.groupId),
    ];
    return [word, ...candidates.take(3)].toList()..shuffle(random);
  }
}
