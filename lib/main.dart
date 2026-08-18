import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'models/question.dart';
import 'models/word.dart';
import 'services/local_store.dart';
import 'theme.dart';
import 'utils/exercise_maker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(LocalStore(prefs));
  await state.load();
  runApp(App(state: state));
}

class App extends StatelessWidget {
  const App({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '填空策',
          theme: buildTheme(
            eyeCare: state.eyeCare,
            scale: state.fontScale,
          ),
          home: state.loading
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Shell(state: state),
        );
      },
    );
  }
}

// ==================== 底部导航框架 ====================

class Shell extends StatefulWidget {
  const Shell({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PracticePage(state: widget.state),
      DictionaryPage(state: widget.state),
      MistakesPage(state: widget.state),
      StatisticsPage(state: widget.state),
    ];
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BottomNavigationBar(
              currentIndex: tab,
              onTap: (value) => setState(() => tab = value),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_box_outline_blank, size: 26),
                  activeIcon: Icon(Icons.check_box, size: 26),
                  label: '专项练习',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined, size: 26),
                  activeIcon: Icon(Icons.menu_book, size: 26),
                  label: '词库词典',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined, size: 26),
                  activeIcon: Icon(Icons.assignment, size: 26),
                  label: '错题&收藏',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined, size: 26),
                  activeIcon: Icon(Icons.bar_chart, size: 26),
                  label: '学习统计',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 通用标签与侧重点 ====================

Color tagColor(String tag) {
  return tag.contains('贬')
      ? dangerRed
      : tag.contains('褒')
          ? successGreen
          : neutralGray;
}

Widget tag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: tagColor(text),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget emphasisText(String text) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(
        color: accentOrange,
        fontWeight: FontWeight.bold,
        height: 1.6,
        fontSize: 15,
      ),
      children: [
        const WidgetSpan(
          child: Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.push_pin, size: 16, color: accentOrange),
          ),
        ),
        const TextSpan(text: '侧重点：'),
        TextSpan(
          text: text.replaceFirst(RegExp(r'^侧重：'), ''),
        ),
      ],
    ),
  );
}

// ==================== 专项练习首页 ====================

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final expanded = <int>{1};
  ExerciseMode mode = ExerciseMode.explainToWord;
  double count = 20;
  bool shuffle = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final groups = state.allGroups;
    final words = groups
        .where((group) => state.selectedGroups.contains(group.id))
        .expand((group) => group.words)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('逻辑填空 400 词｜专项练习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // 统计卡片
          cardContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '已选 ${state.selectedGroups.length} 个组别',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '可用词汇 $words 个',
                            style: const TextStyle(
                              fontSize: 15,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: dividerColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '共 ${groups.length} 组',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _smallBtn('清空', () => state.setGroups([])),
                              const SizedBox(width: 8),
                              _smallBtn('恢复上次选择', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已恢复上次选择')),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 折叠章节列表
          ...state.chapters.map(_chapter),

          // 练习模式选择
          cardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择练习模式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.2,
                  children: [
                    _modeRadio(ExerciseMode.explainToWord, '释义选词语'),
                    _modeRadio(ExerciseMode.wordToExplain, '词语选释义'),
                    _modeRadio(ExerciseMode.confusing, '易混辨析题（国考重点）'),
                    _modeRadio(ExerciseMode.examBlank, '真题挖空模式'),
                  ],
                ),
              ],
            ),
          ),

          // 刷题参数设置
          cardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '题量',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: count,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: '${count.round()}',
                        onChanged: (value) => setState(() => count = value),
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${count.round()}',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '题目打乱顺序',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: shuffle,
                      onChanged: (value) => setState(() => shuffle = value),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // 开始按钮
          bigButton(
            text: '开始专项练习',
            onPressed: state.selectedGroups.isEmpty
                ? null
                : () {
                    final questions = ExerciseMaker.make(
                      groups: groups,
                      selectedGroupIds: state.selectedGroups.toList(),
                      mode: mode,
                      count: count.round(),
                      shuffle: shuffle,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(
                          state: state,
                          questions: questions,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _smallBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: textSecondary),
        ),
      ),
    );
  }

  Widget _modeRadio(ExerciseMode value, String label) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => setState(() => mode = value),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? primaryBlue : neutralGray,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryBlue,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? primaryBlue : textPrimary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapter(Chapter chapter) {
    final open = expanded.contains(chapter.id);
    final state = widget.state;
    final all = chapter.groups.every(
      (group) => state.selectedGroups.contains(group.id),
    );

    return cardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(
              () => open
                  ? expanded.remove(chapter.id)
                  : expanded.add(chapter.id),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    open ? Icons.expand_more : Icons.chevron_right,
                    color: textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => state.setGroups(
                      all
                          ? state.selectedGroups.difference(
                              chapter.groups
                                  .map((group) => group.id)
                                  .toSet(),
                            )
                          : {
                              ...state.selectedGroups,
                              ...chapter.groups.map((group) => group.id),
                            },
                    ),
                    child: Text(
                      all ? '取消全选' : '全选',
                      style: const TextStyle(
                        fontSize: 14,
                        color: primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            ...chapter.groups.map(
              (group) {
                final checked = state.selectedGroups.contains(group.id);
                return GestureDetector(
                  onTap: () => state.toggleGroup(group.id),
                  child: Container(
                    color: checked
                        ? primaryBlue.withOpacity(0.06)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: checked ? primaryBlue : Colors.white,
                            border: Border.all(
                              color: checked ? primaryBlue : neutralGray,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: checked
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            group.title,
                            style: TextStyle(
                              fontSize: 15,
                              color: checked ? primaryBlue : textPrimary,
                              fontWeight: checked
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '${group.words.length}词',
                          style: const TextStyle(
                            fontSize: 13,
                            color: neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==================== 刷题答题页 ====================

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.state,
    required this.questions,
  });

  final AppState state;
  final List<ExerciseQuestion> questions;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int index = 0;
  int selected = -1;
  int correct = 0;
  bool submitted = false;
  bool showImmediately = true;
  final started = DateTime.now();
  final results = <AnswerResult>[];

  ExerciseQuestion get q => widget.questions[index];

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('刷题')),
        body: const Center(
          child: Text('当前选中组别暂无足够词语'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (index + 1) / widget.questions.length,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E6EB),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${index + 1}/${widget.questions.length}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.state.favorites.contains(q.word.name)
                  ? Icons.star
                  : Icons.star_border,
              color: widget.state.favorites.contains(q.word.name)
                  ? accentOrange
                  : neutralGray,
            ),
            onPressed: () => widget.state.toggleFavorite(q.word.name),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: neutralGray),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('答完立刻看解析'),
                        trailing: showImmediately
                            ? const Icon(Icons.check, color: primaryBlue)
                            : null,
                        onTap: () {
                          setState(() => showImmediately = true);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('全部做完再看解析'),
                        trailing: !showImmediately
                            ? const Icon(Icons.check, color: primaryBlue)
                            : null,
                        onTap: () {
                          setState(() => showImmediately = false);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sticky_note_2_outlined, color: neutralGray),
            onPressed: _note,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 题干区
          cardContainer(
            padding: const EdgeInsets.all(22),
            child: Text(
              q.prompt,
              style: const TextStyle(
                fontSize: 17,
                height: 1.7,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 选项区
          ...List.generate(q.options.length, _option),

          // 解析面板
          if (submitted && showImmediately) _analysis(),

          const SizedBox(height: 16),
          // 底部按钮
          bigButton(
            text: submitted
                ? (index == widget.questions.length - 1
                    ? '查看练习报告'
                    : '下一题')
                : '提交答案',
            color: primaryBlue,
            onPressed: selected < 0
                ? null
                : submitted
                    ? _next
                    : _submit,
          ),
        ],
      ),
    );
  }

  Widget _option(int optionIndex) {
    final active = selected == optionIndex;
    final right = submitted && optionIndex == q.correctIndex;
    final wrong = submitted && active && !right;

    // 尝试获取选项词语的褒贬标签
    String? optionTag;
    if (q.mode != ExerciseMode.wordToExplain) {
      final w = widget.state.wordByName(q.options[optionIndex]);
      if (w != null) optionTag = w.colorTag;
    }

    return GestureDetector(
      onTap: submitted ? null : () => setState(() => selected = optionIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: right
              ? successGreen.withOpacity(0.08)
              : wrong
                  ? dangerRed.withOpacity(0.08)
                  : active
                      ? primaryBlue.withOpacity(0.06)
                      : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: right
                ? successGreen
                : wrong
                    ? dangerRed
                    : active
                        ? primaryBlue
                        : dividerColor,
            width: right || wrong || active ? 1.5 : 1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? primaryBlue : const Color(0xFFF2F3F5),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + optionIndex),
                  style: TextStyle(
                    color: active ? Colors.white : textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                q.options[optionIndex],
                style: TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  color: right
                      ? successGreen
                      : wrong
                          ? dangerRed
                          : textPrimary,
                  fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (optionTag != null) tag(optionTag),
            if (right)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: successGreen, size: 24),
              ),
            if (wrong)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.cancel, color: dangerRed, size: 24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _analysis() {
    return cardContainer(
      color: const Color(0xFFF6FFED),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: successGreen, size: 28),
              const SizedBox(width: 10),
              Text(
                q.word.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              tag(q.word.colorTag),
            ],
          ),
          const SizedBox(height: 14),
          emphasisText(q.word.emphasis),
          const SizedBox(height: 12),
          _detailRow(Icons.menu_book, '释义', q.word.explain),
          if (q.word.sentence.isNotEmpty)
            _detailRow(Icons.edit_note, '普通例句', q.word.sentence),
          if (q.word.examSentence.isNotEmpty)
            _detailRow(Icons.article, '真题例句', q.word.examSentence),
          if (q.word.compareWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '错误选项辨析：${q.word.compareWords.join('、')} 等词语侧重点各有不同……',
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _details(q.word),
            child: const Text(
              '查看完整词语详情 →',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: neutralGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label：$content',
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final correctAnswer = selected == q.correctIndex;
    if (correctAnswer) {
      correct++;
      // 答对时，如果该词在错题本中则移除
      if (widget.state.wrongCounts.containsKey(q.word.name)) {
        await widget.state.removeWrong(q.word.name);
      }
    }
    if (!correctAnswer) {
      await widget.state.wrong(q.word.name);
    }
    results.add(
      AnswerResult(
        question: q,
        selectedIndex: selected,
        correct: correctAnswer,
      ),
    );
    setState(() => submitted = true);
  }

  void _next() {
    if (index == widget.questions.length - 1) {
      final elapsed = DateTime.now().difference(started).inMinutes;
      final scores = <int, List<int>>{};
      for (final result in results) {
        final score = scores.putIfAbsent(
          result.question.word.groupId,
          () => [0, 0],
        );
        score[0]++;
        if (result.correct) {
          score[1]++;
        }
      }
      widget.state.store.record(
        total: results.length,
        correct: correct,
        minutes: elapsed,
        groupScore: scores,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportPage(
            state: widget.state,
            results: results,
            duration: DateTime.now().difference(started),
          ),
        ),
      );
    } else {
      setState(() {
        index++;
        selected = -1;
        submitted = false;
      });
    }
  }

  void _details(WordEntry word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordDetail(word: word, state: widget.state),
    );
  }

  void _note() {
    final controller = TextEditingController(
      text: widget.state.notes[q.word.name] ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('给「${q.word.name}」添加笔记'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '记录你的辨析要点',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.state.setNote(q.word.name, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// ==================== 练习报告页 ====================

class ReportPage extends StatelessWidget {
  const ReportPage({
    super.key,
    required this.state,
    required this.results,
    required this.duration,
  });

  final AppState state;
  final List<AnswerResult> results;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final right = results.where((result) => result.correct).length;
    final wrong = results
        .where((result) => !result.correct)
        .map((result) => result.question.word)
        .toList();
    final rates = <int, List<int>>{};
    for (final result in results) {
      final rate = rates.putIfAbsent(
        result.question.word.groupId,
        () => [0, 0],
      );
      rate[0]++;
      if (result.correct) {
        rate[1]++;
      }
    }
    final ratePercent =
        results.isEmpty ? 0 : (right * 100 ~/ results.length);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        title: const Text(
          '练习报告',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 顶部大卡片
          cardContainer(
            color: primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric('${results.length}', '总题数', Colors.white),
                    Container(
                        width: 1, height: 50, color: Colors.white24),
                    _metric('$right', '答对', const Color(0xFF7FFFAA)),
                    Container(
                        width: 1, height: 50, color: Colors.white24),
                    _metric('$ratePercent%', '正确率', Colors.white),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '用时：${duration.inMinutes.toString().padLeft(2, '0')} 分 '
                  '${(duration.inSeconds % 60).toString().padLeft(2, '0')} 秒',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // 薄弱组别提示
          ...rates.entries
              .where(
                (entry) =>
                    entry.value[0] > 0 &&
                    entry.value[1] * 100 / entry.value[0] < 60,
              )
              .map((entry) {
            final group = state.allGroups.firstWhere(
              (item) => item.id == entry.key,
            );
            return cardContainer(
              color: const Color(0xFFFFF3E8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: accentOrange, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${group.title} 正确率 ${entry.value[1] * 100 ~/ entry.value[0]}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const Text(
                          '建议继续强化练习',
                          style:
                              TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      state.setGroups([group.id]);
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '一键选中该组刷题',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // 做错词语清单
          if (wrong.isNotEmpty)
            cardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '做错词语（${wrong.length}个）',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...wrong.map(
                    (word) => GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            WordDetail(word: word, state: state),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: dangerRed.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              word.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            tag(word.colorTag),
                            const Spacer(),
                            Text(
                              word.groupTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: neutralGray,
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: neutralGray),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          // 底部按钮
          Row(
            children: [
              Expanded(
                child: bigButton(
                  text: '返回专项选择',
                  color: neutralGray,
                  outlined: true,
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: bigButton(
                  text: '查看错题本',
                  color: primaryBlue,
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                ),
              ),
            ],
          ),
          if (wrong.isNotEmpty) ...[
            const SizedBox(height: 12),
            bigButton(
              text: '重做错题',
              color: accentOrange,
              onPressed: () {
                final questions = ExerciseMaker.make(
                  groups: state.allGroups,
                  selectedGroupIds:
                      wrong.map((word) => word.groupId).toSet().toList(),
                  mode: ExerciseMode.explainToWord,
                  count: wrong.length,
                  shuffle: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(
                      state: state,
                      questions: questions,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String number, String label, Color color) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 36,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
        ),
      ],
    );
  }
}

// ==================== 词库词典页 ====================

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final search = TextEditingController();
  String query = '';
  final openChapters = <int>{1};
  final openGroups = <int>{};

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final words = state.allWords
        .where(
          (word) =>
              query.isEmpty ||
              word.name.contains(query) ||
              word.explain.contains(query),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        title: const Text(
          '词库词典',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 搜索框
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: search,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: neutralGray),
                hintText: '搜索成语、词语……',
                hintStyle: TextStyle(color: neutralGray),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (query.isNotEmpty)
            ...words.map(_wordTile)
          else
            ...state.chapters.map(_chapter),
        ],
      ),
    );
  }

  Widget _chapter(Chapter chapter) {
    final open = openChapters.contains(chapter.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 深蓝色章节标题栏
          GestureDetector(
            onTap: () => setState(
              () => open
                  ? openChapters.remove(chapter.id)
                  : openChapters.add(chapter.id),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                color: primaryBlueDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      chapter.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_more : Icons.chevron_right,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            ...chapter.groups.map(_group),
        ],
      ),
    );
  }

  Widget _group(WordGroup group) {
    final open = openGroups.contains(group.id);
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(
            () => open
                ? openGroups.remove(group.id)
                : openGroups.add(group.id),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(
                  open ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                  color: textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${group.words.length}词',
                  style: const TextStyle(fontSize: 13, color: neutralGray),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Container(
            color: const Color(0xFFFAFBFC),
            child: Column(
              children: group.words.map(_wordTile).toList(),
            ),
          ),
      ],
    );
  }

  Widget _wordTile(WordEntry word) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WordDetail(word: word, state: widget.state),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        word.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      tag(word.colorTag),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.emphasis,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: neutralGray),
          ],
        ),
      ),
    );
  }
}

// ==================== 词语详情弹窗 ====================

class WordDetail extends StatelessWidget {
  const WordDetail({
    super.key,
    required this.word,
    required this.state,
  });

  final WordEntry word;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 顶部抓手
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        word.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: neutralGray),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  tag(word.colorTag),
                  const SizedBox(height: 16),
                  emphasisText(word.emphasis),
                  const SizedBox(height: 16),
                  _detailSection(Icons.menu_book, '释义', word.explain),
                  _detailSection(Icons.edit_note, '例句', word.sentence),
                  if (word.examSentence.isNotEmpty)
                    _detailSection(
                        Icons.article, '真题例句', word.examSentence),
                  if (word.compareWords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.swap_horiz,
                              size: 18, color: neutralGray),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '同组易混辨析：${word.compareWords.join(' VS ')}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: primaryBlue,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if ((state.notes[word.name] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '我的笔记：${state.notes[word.name]}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => _editNote(context),
                            icon: const Icon(Icons.edit_note),
                            label: const Text('添加笔记'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textSecondary,
                              side: const BorderSide(color: dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () => state.toggleFavorite(word.name),
                            icon: Icon(
                              state.favorites.contains(word.name)
                                  ? Icons.star
                                  : Icons.star_border,
                            ),
                            label: Text(
                              state.favorites.contains(word.name)
                                  ? '已收藏'
                                  : '收藏词语',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: accentOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(IconData icon, String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: neutralGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label：$content',
              style: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editNote(BuildContext context) {
    final controller = TextEditingController(
      text: state.notes[word.name] ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('给「${word.name}」添加笔记'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '记录你的辨析要点',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await state.setNote(word.name, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// ==================== 错题 & 收藏页 ====================

class MistakesPage extends StatefulWidget {
  const MistakesPage({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<MistakesPage> createState() => _MistakesPageState();
}

class _MistakesPageState extends State<MistakesPage> {
  int tab = 0;
  final selected = <String>{};
  bool showReviewCard = false;
  int reviewIndex = 0;
  bool reviewFlipped = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final names = tab == 0
        ? state.wrongCounts.keys.toList()
        : state.favorites.toList();
    final reviewWords = names
        .map((name) => state.wordByName(name))
        .where((w) => w != null)
        .cast<WordEntry>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        title: const Text(
          '错题 & 收藏',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab 切换
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _tabItem(0, '错题本', Icons.close),
                  _tabItem(1, '我的薄弱词', Icons.star_border),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 筛选和生成按钮
          if (names.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    '按组别筛选',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: neutralGray),
                  const Spacer(),
                  GestureDetector(
                    onTap: selected.isEmpty
                        ? null
                        : () {
                            final questions = ExerciseMaker.make(
                              groups: state.allGroups,
                              selectedGroupIds: names
                                  .where(selected.contains)
                                  .map((name) =>
                                      state.wordByName(name)!.groupId)
                                  .toSet()
                                  .toList(),
                              mode: ExerciseMode.explainToWord,
                              count: selected.length,
                              shuffle: false,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizPage(
                                  state: state,
                                  questions: questions,
                                ),
                              ),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected.isEmpty
                            ? neutralGray.withOpacity(0.3)
                            : primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '生成专项刷题',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // 艾宾浩斯复习入口
          if (names.isNotEmpty && reviewWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => setState(() {
                  showReviewCard = !showReviewCard;
                  reviewIndex = 0;
                  reviewFlipped = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.autorenew, color: primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '艾宾浩斯复习：今日有 ${reviewWords.length} 个词语待复习',
                          style: const TextStyle(
                            fontSize: 14,
                            color: primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '开始复习',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 复习卡片
          if (showReviewCard && reviewWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _reviewCard(reviewWords),
            ),

          // 列表
          Expanded(
            child: names.isEmpty
                ? _empty(
                    tab == 0
                        ? '还没有做错的题目，快去专项练习吧'
                        : '刷题时点击收藏词语，加入薄弱词本',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: names.length,
                    itemBuilder: (_, index) {
                      final word = state.wordByName(names[index]);
                      if (word == null) return const SizedBox();
                      final isSelected = selected.contains(word.name);
                      return GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              WordDetail(word: word, state: state),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryBlue.withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? primaryBlue.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => isSelected
                                      ? selected.remove(word.name)
                                      : selected.add(word.name),
                                ),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryBlue
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryBlue
                                          : neutralGray,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: tab == 0
                                      ? dangerRed.withOpacity(0.1)
                                      : accentOrange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  tab == 0 ? Icons.close : Icons.star,
                                  size: 16,
                                  color: tab == 0 ? dangerRed : accentOrange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          word.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        tag(word.colorTag),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${word.groupTitle}'
                                      '${tab == 0 ? ' · 错误 ${state.wrongCounts[word.name]} 次' : ''}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: neutralGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: neutralGray),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, IconData icon) {
    final active = tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          tab = index;
          selected.clear();
        }),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? primaryBlue : neutralGray),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? primaryBlue : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(List<WordEntry> words) {
    if (reviewIndex >= words.length) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '今日复习完成！',
            style: TextStyle(
              fontSize: 16,
              color: successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    final word = words[reviewIndex];
    return StatefulBuilder(
      builder: (context, setSt) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => setSt(() {
                    if (reviewIndex > 0) reviewIndex--;
                    reviewFlipped = false;
                  }),
                  child: const Icon(Icons.chevron_left, color: neutralGray),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSt(() => reviewFlipped = !reviewFlipped),
                    child: Column(
                      children: [
                        Text(
                          word.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (reviewFlipped) ...[
                          tag(word.colorTag),
                          const SizedBox(height: 10),
                          Text(
                            word.emphasis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: accentOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            word.explain,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ] else
                          const Text(
                            '点击翻面查看释义',
                            style: TextStyle(
                              fontSize: 13,
                              color: neutralGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setSt(() {
                    if (reviewIndex < words.length - 1) reviewIndex++;
                    reviewFlipped = false;
                  }),
                  child: const Icon(Icons.chevron_right, color: neutralGray),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 72,
            color: neutralGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 15, color: neutralGray),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
            ),
            child: const Text('去专项练习'),
          ),
        ],
      ),
    );
  }
}

// ==================== 学习统计页 ====================

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final data = state.store.stats;
    final total = data['total'] as int;
    final correct = data['correct'] as int;
    final minutes = data['minutes'] as int;
    final groups =
        Map<String, dynamic>.from(data['groups'] as Map? ?? {});
    final rate = total == 0 ? 0 : correct * 100 ~/ total;

    // 计算各章节正确率
    final chapterRates = <int, double>{};
    for (final chapter in state.chapters) {
      int t = 0, c = 0;
      for (final group in chapter.groups) {
        final gData = Map<String, dynamic>.from(
          groups['${group.id}'] as Map? ?? {'total': 0, 'correct': 0},
        );
        t += gData['total'] as int;
        c += gData['correct'] as int;
      }
      chapterRates[chapter.id] = t == 0 ? 0 : c * 100 / t;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        title: const Text(
          '学习统计',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(state: state),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 概览卡片（三列）
          Row(
            children: [
              Expanded(
                child: _overviewCard('$total', '总刷题数', textPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewCard('$rate%', '总正确率', successGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewCard('${minutes}h', '学习时长', primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 六大章节正确率柱状图
          cardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '六大章节正确率',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: _barChart(chapterRates),
                ),
              ],
            ),
          ),

          // 65 小组别正确率
          cardContainer(
            color: const Color(0xFFFFF8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '65 小组别正确率',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.chapters.expand(
                  (chapter) => chapter.groups.map(
                    (group) {
                      final gData = Map<String, dynamic>.from(
                        groups['${group.id}'] as Map? ??
                            {'total': 0, 'correct': 0},
                      );
                      final gTotal = gData['total'] as int;
                      final gRate =
                          gTotal == 0 ? 0 : (gData['correct'] as int) * 100 ~/ gTotal;
                      final isWeak = gTotal > 0 && gRate < 60;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  gTotal == 0 ? '暂无数据' : '$gRate%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isWeak
                                        ? accentOrange
                                        : gTotal == 0
                                            ? neutralGray
                                            : successGreen,
                                  ),
                                ),
                                if (isWeak) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      state.setGroups([group.id]);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              '已选中该组，请切换到专项练习开始刷题'),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accentOrange,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        '一键刷题',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: gTotal == 0 ? 0 : gRate / 100,
                                minHeight: 6,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isWeak ? accentOrange : successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: neutralGray),
          ),
        ],
      ),
    );
  }

  Widget _barChart(Map<int, double> rates) {
    final maxRate = 100.0;
    final entries = state.chapters.map((c) {
      return (
        label: '第${_chapterNum(c.id)}章',
        rate: rates[c.id] ?? 0.0,
      );
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: entries.map((e) {
        final heightRatio = e.rate / maxRate;
        final color = e.rate < 60 ? accentOrange : successGreen;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${e.rate.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 130 * heightRatio,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              e.label,
              style: const TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _chapterNum(int id) {
    const nums = ['一', '二', '三', '四', '五', '六'];
    return id >= 1 && id <= 6 ? nums[id - 1] : '$id';
  }
}

// ==================== 设置页 ====================

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 阅读体验
          _sectionTitle('阅读体验'),
          cardContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // 字体大小
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '字体大小',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _fontBtn('A', 0.9, state.fontScale == 0.9, () => state.setScale(0.9)),
                      const Text(' - ', style: TextStyle(color: neutralGray)),
                      _fontBtn('A', 1.0, state.fontScale == 1.0, () => state.setScale(1.0)),
                      const Text(' - ', style: TextStyle(color: neutralGray)),
                      _fontBtn('A', 1.3, state.fontScale == 1.3, () => state.setScale(1.3), large: true),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                // 背景模式
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '背景模式',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _bgBtn('默认白', !state.eyeCare, () => state.setEye(false)),
                      const SizedBox(width: 10),
                      _bgBtn('米黄护眼', state.eyeCare, () => state.setEye(true)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 学习数据
          _sectionTitle('学习数据'),
          cardContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: textSecondary),
                  title: const Text('清除本地缓存'),
                  trailing: const Text(
                    '2.3 MB',
                    style: TextStyle(color: neutralGray, fontSize: 14),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('缓存已清除')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                ListTile(
                  leading: const Icon(Icons.warning_amber_outlined, color: dangerRed),
                  title: const Text(
                    '重置学习记录',
                    style: TextStyle(color: dangerRed),
                  ),
                  trailing: const Text(
                    '清警示',
                    style: TextStyle(color: dangerRed, fontSize: 14),
                  ),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('确认清空？'),
                        content: const Text('将删除错题、收藏与统计数据，此操作不可恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确认'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await state.clearLearning();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('本地学习记录已清空')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // 关于
          _sectionTitle('关于'),
          cardContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                ListTile(
                  title: Text('版本号'),
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(color: neutralGray),
                  ),
                ),
                Divider(height: 1, indent: 18, endIndent: 18),
                ListTile(
                  title: Text('用户协议'),
                  trailing: Icon(Icons.chevron_right, color: neutralGray),
                ),
                Divider(height: 1, indent: 18, endIndent: 18),
                ListTile(
                  title: Text('隐私政策'),
                  trailing: Icon(Icons.chevron_right, color: neutralGray),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              '逻辑填空 400 词｜专为国考考生打造',
              style: TextStyle(fontSize: 13, color: neutralGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _fontBtn(String text, double scale, bool active, VoidCallback onTap,
      {bool large = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: active ? primaryBlue : dividerColor,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: large ? 20 : 16,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? primaryBlue : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _bgBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: active ? primaryBlue : dividerColor,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? primaryBlue : textSecondary,
          ),
        ),
      ),
    );
  }
}
