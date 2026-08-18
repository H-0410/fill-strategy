import 'word.dart';

enum ExerciseMode {
  explainToWord,
  wordToExplain,
  confusing,
  examBlank,
}

class ExerciseQuestion {
  const ExerciseQuestion({
    required this.word,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.mode,
  });

  final WordEntry word;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final ExerciseMode mode;
}

class AnswerResult {
  const AnswerResult({
    required this.question,
    required this.selectedIndex,
    required this.correct,
  });

  final ExerciseQuestion question;
  final int selectedIndex;
  final bool correct;
}

