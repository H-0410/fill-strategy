import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word.dart';

class WordBankRepository {
  Future<List<Chapter>> load() async {
    final raw = await rootBundle.loadString('assets/json/word_bank.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['chapterList'] as List).map((c) {
      final chapterId = c['chapterId'] as int;
      final groups = (c['groupList'] as List).map((g) {
        final groupId = g['groupId'] as int;
        final title = g['groupTitle'] as String;
        return WordGroup(id: groupId, title: title, words: (g['words'] as List).map((w) => WordEntry.fromJson(w, chapterId, groupId, title)).toList());
      }).toList();
      return Chapter(id: chapterId, title: c['chapterTitle'] as String, groups: groups);
    }).toList();
  }
}
