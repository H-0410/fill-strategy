import 'package:flutter_test/flutter_test.dart';
import 'package:tiankong_ce/models/word.dart';
import 'package:tiankong_ce/models/question.dart';
import 'package:tiankong_ce/utils/exercise_maker.dart';

void main() {
  test('题目和干扰项只能来自选中的组别', () {
    const a = WordEntry(name: '甲', colorTag: '褒', emphasis: '侧重甲', explain: '释义甲', sentence: '甲句', examSentence: '', compareWords: [], chapterId: 1, groupId: 1, groupTitle: '第1组');
    const b = WordEntry(name: '乙', colorTag: '贬', emphasis: '侧重乙', explain: '释义乙', sentence: '乙句', examSentence: '', compareWords: [], chapterId: 1, groupId: 1, groupTitle: '第1组');
    const outside = WordEntry(name: '丙', colorTag: '中性', emphasis: '侧重丙', explain: '释义丙', sentence: '丙句', examSentence: '', compareWords: [], chapterId: 1, groupId: 2, groupTitle: '第2组');
    final questions = ExerciseMaker.make(groups: [const WordGroup(id: 1, title: '第1组', words: [a, b]), const WordGroup(id: 2, title: '第2组', words: [outside])], selectedGroupIds: const [1], mode: ExerciseMode.emphasisToWord, count: 10, shuffle: false);
    expect(questions, isNotEmpty);
    expect(questions.every((q) => q.word.groupId == 1 && q.options.every((o) => o != '丙')), isTrue);
  });

  test('侧重点模式使用侧重点作为题干和选项，并保留选项词语', () {
    const a = WordEntry(name: '甲', colorTag: '褒', emphasis: '侧重甲', explain: '释义甲', sentence: '甲句', examSentence: '', compareWords: [], chapterId: 1, groupId: 1, groupTitle: '第1组');
    const b = WordEntry(name: '乙', colorTag: '贬', emphasis: '侧重乙', explain: '释义乙', sentence: '乙句', examSentence: '', compareWords: [], chapterId: 1, groupId: 1, groupTitle: '第1组');
    const c = WordEntry(name: '丙', colorTag: '中性', emphasis: '侧重丙', explain: '释义丙', sentence: '丙句', examSentence: '', compareWords: [], chapterId: 1, groupId: 1, groupTitle: '第1组');
    const d = WordEntry(name: '丁', colorTag: '中性', emphasis: '侧重丁', explain: '释义丁', sentence: '丁句', examSentence: '', compareWords: [], chapterId: 1, groupId: 1, groupTitle: '第1组');
    const group = WordGroup(id: 1, title: '第1组', words: [a, b, c, d]);

    final emphasisToWord = ExerciseMaker.make(groups: [group], selectedGroupIds: const [1], mode: ExerciseMode.emphasisToWord, count: 1, shuffle: false).single;
    expect(emphasisToWord.prompt, contains('侧重甲'));
    expect(emphasisToWord.options, containsAll(['甲', '乙', '丙', '丁']));
    expect(emphasisToWord.optionWords.map((word) => word.name), containsAll(['甲', '乙', '丙', '丁']));

    final wordToEmphasis = ExerciseMaker.make(groups: [group], selectedGroupIds: const [1], mode: ExerciseMode.wordToEmphasis, count: 1, shuffle: false).single;
    expect(wordToEmphasis.prompt, contains('正确侧重点'));
    expect(wordToEmphasis.options, containsAll(['侧重甲', '侧重乙', '侧重丙', '侧重丁']));
    expect(wordToEmphasis.optionWords.map((word) => word.name), containsAll(['甲', '乙', '丙', '丁']));
  });
}
