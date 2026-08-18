class WordEntry {
  const WordEntry({
    required this.name,
    required this.colorTag,
    required this.emphasis,
    required this.explain,
    required this.sentence,
    required this.examSentence,
    required this.compareWords,
    required this.chapterId,
    required this.groupId,
    required this.groupTitle,
  });

  final String name;
  final String colorTag;
  final String emphasis;
  final String explain;
  final String sentence;
  final String examSentence;
  final String groupTitle;
  final List<String> compareWords;
  final int chapterId;
  final int groupId;

  factory WordEntry.fromJson(
    Map<String, dynamic> json,
    int chapterId,
    int groupId,
    String groupTitle,
  ) {
    return WordEntry(
      name: json['wordName'] ?? '',
      colorTag: json['colorTag'] ?? '中性',
      emphasis: json['emphasis'] ?? '',
      explain: json['explain'] ?? '',
      sentence: json['sentence'] ?? '',
      examSentence: json['examSentence'] ?? '',
      compareWords: List<String>.from(json['compareWords'] ?? const []),
      chapterId: chapterId,
      groupId: groupId,
      groupTitle: groupTitle,
    );
  }
}

class WordGroup {
  const WordGroup({
    required this.id,
    required this.title,
    required this.words,
  });

  final int id;
  final String title;
  final List<WordEntry> words;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.groups,
  });

  final int id;
  final String title;
  final List<WordGroup> groups;
}

