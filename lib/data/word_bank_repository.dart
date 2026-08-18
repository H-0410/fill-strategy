import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word.dart';

class WordBankRepository {
  Future<List<Chapter>> load() async {
    final raw = await rootBundle.loadString('assets/json/word_bank.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    return (data['chapterList'] as List).map((chapter) {
      final chapterId = chapter['chapterId'] as int;
      final groups = (chapter['groupList'] as List).map((group) {
        final groupId = group['groupId'] as int;
        final title = group['groupTitle'] as String;
        final words = (group['words'] as List)
            .map(
              (word) => WordEntry.fromJson(
                word,
                chapterId,
                groupId,
                title,
              ),
            )
            .toList();

        return WordGroup(
          id: groupId,
          title: title,
          words: words,
        );
      }).toList();

      return Chapter(
        id: chapterId,
        title: chapter['chapterTitle'] as String,
        groups: groups,
      );
    }).toList();
  }
}

