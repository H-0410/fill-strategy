import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this.prefs);

  final SharedPreferences prefs;

  List<int> get selectedGroups =>
      (prefs.getStringList('selected_groups') ?? []).map(int.parse).toList();

  Future<void> saveSelectedGroups(List<int> ids) {
    return prefs.setStringList(
      'selected_groups',
      ids.map((id) => '$id').toList(),
    );
  }

  Set<String> get favorites =>
      (prefs.getStringList('favorites') ?? []).toSet();

  Future<void> setFavorite(String word, bool value) async {
    final values = favorites;
    if (value) {
      values.add(word);
    } else {
      values.remove(word);
    }
    await prefs.setStringList('favorites', values.toList());
  }

  Map<String, String> get notes => Map<String, String>.from(
        jsonDecode(prefs.getString('notes') ?? '{}').map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

  Future<void> setNote(String word, String note) async {
    final values = notes;
    values[word] = note;
    await prefs.setString('notes', jsonEncode(values));
  }

  Map<String, int> get wrongCounts => Map<String, int>.from(
        (jsonDecode(prefs.getString('wrong_counts') ?? '{}') as Map).map(
          (key, value) => MapEntry(key, value as int),
        ),
      );

  Future<void> addWrong(String word) async {
    final values = wrongCounts;
    values[word] = (values[word] ?? 0) + 1;
    await prefs.setString('wrong_counts', jsonEncode(values));
  }

  Future<void> removeWrong(String word) async {
    final values = wrongCounts;
    values.remove(word);
    await prefs.setString('wrong_counts', jsonEncode(values));
  }

  bool get eyeCare => prefs.getBool('eye_care') ?? false;
  double get fontScale => prefs.getDouble('font_scale') ?? 1;

  Future<void> setEyeCare(bool value) {
    return prefs.setBool('eye_care', value);
  }

  Future<void> setFontScale(double value) {
    return prefs.setDouble('font_scale', value);
  }

  Map<String, dynamic> get stats => jsonDecode(
        prefs.getString('stats') ??
            '{"total":0,"correct":0,"minutes":0,"groups":{}}',
      );

  /// 实时记录单题答题结果（每答一题调用一次）
  /// [wordName] 词语名称，用于判断是否首次答题
  /// [wasWrong] 该词之前是否在错题本中（用于判断是否错题重做）
  Future<void> recordAnswer(
    int groupId,
    String wordName,
    bool isCorrect,
    bool wasWrong,
  ) async {
    final old = stats;
    // 全局已答词语列表，用于避免重复计数
    final answered =
        List<String>.from(old['answeredWords'] as List? ?? []);
    final isFirstTime = !answered.contains(wordName);

    if (isFirstTime) {
      // 首次答这个词：total +1
      answered.add(wordName);
      old['total'] = (old['total'] as int) + 1;
      if (isCorrect) {
        old['correct'] = (old['correct'] as int) + 1;
      }
    } else {
      // 非首次：不增加 total
      if (isCorrect && wasWrong) {
        // 错题重做答对 → correct +1（正确率上升）
        old['correct'] = (old['correct'] as int) + 1;
      } else if (!isCorrect && !wasWrong) {
        // 已掌握的词重做答错 → correct -1（正确率下降）
        old['correct'] = (old['correct'] as int) - 1;
      }
      // 错题重做答错 → correct 不变（不再下降）
    }
    old['answeredWords'] = answered;

    // 组别统计同理
    final groups = Map<String, dynamic>.from(old['groups'] as Map? ?? {});
    final item = Map<String, dynamic>.from(
      groups['$groupId'] as Map? ??
          {'total': 0, 'correct': 0, 'answeredWords': []},
    );
    final groupAnswered =
        List<String>.from(item['answeredWords'] as List? ?? []);
    final groupFirstTime = !groupAnswered.contains(wordName);

    if (groupFirstTime) {
      groupAnswered.add(wordName);
      item['total'] = (item['total'] as int) + 1;
      if (isCorrect) {
        item['correct'] = (item['correct'] as int) + 1;
      }
    } else {
      if (isCorrect && wasWrong) {
        item['correct'] = (item['correct'] as int) + 1;
      } else if (!isCorrect && !wasWrong) {
        item['correct'] = (item['correct'] as int) - 1;
      }
    }
    item['answeredWords'] = groupAnswered;
    groups['$groupId'] = item;
    old['groups'] = groups;

    await prefs.setString('stats', jsonEncode(old));
  }

  /// 记录学习时长（练习结束时调用）
  Future<void> recordMinutes(int minutes) async {
    final old = stats;
    old['minutes'] = (old['minutes'] as int) + minutes;
    await prefs.setString('stats', jsonEncode(old));
  }

  Future<void> record({
    required int total,
    required int correct,
    required int minutes,
    required Map<int, List<int>> groupScore,
  }) async {
    final old = stats;
    old['total'] = (old['total'] as int) + total;
    old['correct'] = (old['correct'] as int) + correct;
    old['minutes'] = (old['minutes'] as int) + minutes;
    final groups = Map<String, dynamic>.from(old['groups'] as Map? ?? {});
    groupScore.forEach((id, score) {
      final item = Map<String, dynamic>.from(
        groups['$id'] as Map? ?? {'total': 0, 'correct': 0},
      );
      item['total'] = (item['total'] as int) + score[0];
      item['correct'] = (item['correct'] as int) + score[1];
      groups['$id'] = item;
    });
    old['groups'] = groups;
    await prefs.setString('stats', jsonEncode(old));
  }

  Future<void> clearLearning() async {
    await prefs.remove('wrong_counts');
    await prefs.remove('stats');
    await prefs.remove('favorites');
    await prefs.remove('notes');
  }
}
