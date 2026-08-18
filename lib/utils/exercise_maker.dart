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
      final options = _options(word, selected, pool, random, mode);
      final correct = options.indexOf(_answer(word, mode));
      return ExerciseQuestion(
        word: word,
        prompt: _prompt(word, mode),
        options: options,
        correctIndex: correct < 0 ? 0 : correct,
        mode: mode,
      );
    }).toList();
  }

  static String _answer(WordEntry word, ExerciseMode mode) {
    return mode == ExerciseMode.explainToWord
        ? word.name
        : mode == ExerciseMode.wordToExplain
            ? word.explain
            : word.name;
  }

  static String _prompt(WordEntry word, ExerciseMode mode) {
    switch (mode) {
      case ExerciseMode.explainToWord:
        return '根据释义选择最恰当的词语：\n${word.explain}';
      case ExerciseMode.wordToExplain:
        return '请选择「${word.name}」的正确释义';
      case ExerciseMode.confusing:
        return '${word.sentence.replaceAll(word.name, '____')}\n请选择最恰当的词语';
      case ExerciseMode.examBlank:
        final sentence = word.examSentence.isEmpty
            ? word.sentence
            : word.examSentence;
        return '${sentence.replaceAll(word.name, '____')}\n请选择最恰当的词语';
    }
  }

  static List<String> _options(
    WordEntry word,
    List<WordGroup> selected,
    List<WordEntry> pool,
    Random random,
    ExerciseMode mode,
  ) {
    final answer = _answer(word, mode);
    if (mode == ExerciseMode.wordToExplain) {
      final same = pool.where((item) => item.name != word.name).toList()
        ..shuffle(random);
      return [answer, ...same.take(3).map((item) => item.explain)].toList()
        ..shuffle(random);
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
    return [answer, ...candidates.take(3).map((item) => item.name)].toList()
      ..shuffle(random);
  }
}
