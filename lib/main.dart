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
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: '专项练习',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '词库词典',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '错题&收藏',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '学习统计',
          ),
        ],
      ),
    );
  }
}

Color tagColor(String tag) {
  return tag.contains('贬')
      ? dangerRed
      : tag.contains('褒')
          ? successGreen
          : neutralGray;
}

Widget tag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 3,
    ),
    decoration: BoxDecoration(
      color: tagColor(text),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    ),
  );
}

Widget emphasis(String text) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(
        color: accentOrange,
        fontWeight: FontWeight.bold,
        height: 1.6,
      ),
      children: [
        const TextSpan(text: '侧重点：'),
        TextSpan(
          text: text.replaceFirst(RegExp(r'^侧重：'), ''),
        ),
      ],
    ),
  );
}

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
  double count = 10;
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
            icon: const Icon(Icons.settings_outlined),
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
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已选 ${state.selectedGroups.length} 个组别',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '可用词汇 $words 个',
                        style: const TextStyle(color: neutralGray),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('共 ${groups.length} 组'),
                      TextButton(
                        onPressed: () => state.setGroups([]),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ...state.chapters.map(_chapter),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择练习模式',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final item in [
                        (ExerciseMode.explainToWord, '释义选词语'),
                        (ExerciseMode.wordToExplain, '词语选释义'),
                        (ExerciseMode.confusing, '易混辨析题'),
                        (ExerciseMode.examBlank, '真题挖空模式'),
                      ])
                        SizedBox(
                          width: 155,
                          child: RadioListTile<ExerciseMode>(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(item.$2),
                            value: item.$1,
                            groupValue: mode,
                            onChanged: (value) => setState(
                              () => mode = value!,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('题量：${count.round()} 题'),
                  Slider(
                    value: count,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${count.round()}',
                    onChanged: (value) => setState(() => count = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('打乱题目顺序'),
                    value: shuffle,
                    onChanged: (value) => setState(() => shuffle = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: state.selectedGroups.isEmpty
                    ? neutralGray
                    : accentOrange,
              ),
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
              child: const Text(
                '开始专项练习',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              chapter.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: TextButton(
              onPressed: () => state.setGroups(
                all
                    ? state.selectedGroups.difference(
                        chapter.groups.map((group) => group.id).toSet(),
                      )
                    : {
                        ...state.selectedGroups,
                        ...chapter.groups.map((group) => group.id),
                      },
              ),
              child: Text(all ? '取消全选' : '全选'),
            ),
            onTap: () => setState(
              () => open
                  ? expanded.remove(chapter.id)
                  : expanded.add(chapter.id),
            ),
          ),
          if (open)
            ...chapter.groups.map(
              (group) => CheckboxListTile(
                title: Text(group.title),
                subtitle: Text('${group.words.length} 个词语'),
                value: state.selectedGroups.contains(group.id),
                onChanged: (_) => state.toggleGroup(group.id),
              ),
            ),
        ],
      ),
    );
  }
}

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
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (index + 1) / widget.questions.length,
              ),
            ),
            const SizedBox(width: 12),
            Text('${index + 1}/${widget.questions.length}'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.state.favorites.contains(q.word.name)
                  ? Icons.star
                  : Icons.star_border,
            ),
            onPressed: () => widget.state.toggleFavorite(q.word.name),
          ),
          PopupMenuButton<bool>(
            icon: const Icon(Icons.tune),
            onSelected: (value) => setState(
              () => showImmediately = value,
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: true,
                child: Text('答完立刻看解析'),
              ),
              PopupMenuItem(
                value: false,
                child: Text('全部做完再看解析'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sticky_note_2_outlined),
            onPressed: _note,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                q.prompt,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(q.options.length, _option),
          if (submitted && showImmediately) _analysis(),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: selected < 0
                ? null
                : submitted
                    ? _next
                    : _submit,
            child: Text(
              submitted
                  ? (index == widget.questions.length - 1
                      ? '查看练习报告'
                      : '下一题')
                  : '提交答案',
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(int optionIndex) {
    final active = selected == optionIndex;
    final right = submitted && optionIndex == q.correctIndex;
    final wrong = submitted && active && !right;

    return Card(
      surfaceTintColor: right
          ? successGreen.withOpacity(.12)
          : wrong
              ? dangerRed.withOpacity(.12)
              : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: submitted ? null : () => setState(() => selected = optionIndex),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: active
                    ? primaryBlue
                    : const Color(0xFFE5E6EB),
                child: Text(
                  String.fromCharCode(65 + optionIndex),
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.options[optionIndex],
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              if (right)
                const Icon(
                  Icons.check_circle,
                  color: successGreen,
                ),
              if (wrong)
                const Icon(
                  Icons.cancel,
                  color: dangerRed,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analysis() {
    return Card(
      surfaceTintColor: const Color(0xFFFFF7E8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  q.word.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                tag(q.word.colorTag),
              ],
            ),
            const SizedBox(height: 10),
            emphasis(q.word.emphasis),
            const SizedBox(height: 8),
            Text(
              '释义：${q.word.explain}',
              style: const TextStyle(height: 1.6),
            ),
            Text(
              '例句：${q.word.sentence}',
              style: const TextStyle(height: 1.6),
            ),
            if (q.word.examSentence.isNotEmpty)
              Text(
                '真题例句：${q.word.examSentence}',
                style: const TextStyle(height: 1.6),
              ),
            TextButton(
              onPressed: () => _details(q.word),
              child: const Text('查看词语详情'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final correctAnswer = selected == q.correctIndex;
    if (correctAnswer) {
      correct++;
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
      builder: (_) => WordDetail(
        word: word,
        state: widget.state,
      ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('练习报告')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            surfaceTintColor: primaryBlue,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metric('${results.length}', '总题数', Colors.white),
                  _metric('$right', '答对', Colors.white),
                  _metric(
                    '${results.isEmpty ? 0 : (right * 100 ~/ results.length)}%',
                    '正确率',
                    Colors.white,
                  ),
                ],
              ),
            ),
          ),
          Text(
            '用时：${duration.inMinutes.toString().padLeft(2, '0')} 分 '
            '${(duration.inSeconds % 60).toString().padLeft(2, '0')} 秒',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
            return Card(
              surfaceTintColor: const Color(0xFFFFF0D9),
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber,
                  color: accentOrange,
                ),
                title: Text(
                  '${group.title} 正确率 '
                  '${entry.value[1] * 100 ~/ entry.value[0]}%',
                ),
                trailing: FilledButton(
                  onPressed: () {
                    state.setGroups([group.id]);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('一键选中'),
                ),
              ),
            );
          }),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '做错词语（${wrong.length}个）',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...wrong.map(
                    (word) => ListTile(
                      title: Text(word.name),
                      subtitle: Text(word.groupTitle),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => WordDetail(
                          word: word,
                          state: state,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: wrong.isEmpty
                ? null
                : () {
                    final questions = ExerciseMaker.make(
                      groups: state.allGroups,
                      selectedGroupIds: wrong
                          .map((word) => word.groupId)
                          .toSet()
                          .toList(),
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
            child: const Text('重做错题'),
          ),
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
            fontSize: 30,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color),
        ),
      ],
    );
  }
}

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
  final open = <int>{1};

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
      appBar: AppBar(title: const Text('词库词典')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: search,
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索成语、词语……',
              filled: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (query.isNotEmpty)
            ...words.map(_wordTile)
          else
            ...state.chapters.map(
              (chapter) => Card(
                child: ExpansionTile(
                  title: Text(
                    chapter.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: chapter.groups
                      .map(
                        (group) => ExpansionTile(
                          title: Text(group.title),
                          children: group.words.map(_wordTile).toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wordTile(WordEntry word) {
    return ListTile(
      title: Row(
        children: [
          Text(
            word.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          tag(word.colorTag),
        ],
      ),
      subtitle: Text(
        word.emphasis,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => WordDetail(
          word: word,
          state: widget.state,
        ),
      ),
    );
  }
}

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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  word.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            tag(word.colorTag),
            const SizedBox(height: 14),
            emphasis(word.emphasis),
            const SizedBox(height: 12),
            Text(
              '释义：${word.explain}',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            Text(
              '普通例句：${word.sentence}',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            if (word.examSentence.isNotEmpty)
              Text(
                '真题例句：${word.examSentence}',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            Text(
              '同组易混：${word.compareWords.join(' VS ')}',
              style: const TextStyle(
                color: primaryBlue,
                height: 1.6,
              ),
            ),
            if ((state.notes[word.name] ?? '').isNotEmpty)
              Text(
                '我的笔记：${state.notes[word.name]}',
                style: const TextStyle(
                  height: 1.6,
                  color: neutralGray,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editNote(context),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('添加笔记'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => state.toggleFavorite(word.name),
                    icon: Icon(
                      state.favorites.contains(word.name)
                          ? Icons.star
                          : Icons.star_border,
                    ),
                    label: Text(
                      state.favorites.contains(word.name) ? '已收藏' : '收藏词语',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final names = tab == 0
        ? state.wrongCounts.keys.toList()
        : state.favorites.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('错题 & 收藏')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('错题本'),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('我的收藏'),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (value) => setState(
                () => tab = value.first,
              ),
            ),
          ),
          if (names.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            final questions = ExerciseMaker.make(
                              groups: state.allGroups,
                              selectedGroupIds: names
                                  .where(selected.contains)
                                  .map(
                                    (name) => state.wordByName(name)!.groupId,
                                  )
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
                    child: const Text('生成专项刷题'),
                  ),
                ],
              ),
            ),
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
                      if (word == null) {
                        return const SizedBox();
                      }
                      return Card(
                        child: InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => WordDetail(
                              word: word,
                              state: state,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: selected.contains(word.name),
                            onChanged: (value) => setState(
                              () => value!
                                  ? selected.add(word.name)
                                  : selected.remove(word.name),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  word.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                tag(word.colorTag),
                              ],
                            ),
                            subtitle: Text(
                              '${word.groupTitle}'
                              '${tab == 0 ? ' · 错误 ${state.wrongCounts[word.name]} 次' : ''}',
                            ),
                            secondary: Icon(
                              tab == 0 ? Icons.close : Icons.star,
                              color: tab == 0 ? dangerRed : accentOrange,
                            ),
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

  Widget _empty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: neutralGray,
          ),
          const SizedBox(height: 12),
          Text(text),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            child: const Text('去专项练习'),
          ),
        ],
      ),
    );
  }
}

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
    final groups = Map<String, dynamic>.from(data['groups'] as Map? ?? {});

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('$total', '总刷题量'),
                  _stat(
                    '${total == 0 ? 0 : correct * 100 ~/ total}%',
                    '总正确率',
                  ),
                  _stat('${data['minutes']} 分', '学习时长'),
                ],
              ),
            ),
          ),
          Text(
            '各章节、组别正确率',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...state.chapters.map(
            (chapter) => Card(
              child: ExpansionTile(
                title: Text(chapter.title),
                children: chapter.groups.map((group) {
                  final data = Map<String, dynamic>.from(
                    groups['${group.id}'] as Map? ?? {
                      'total': 0,
                      'correct': 0,
                    },
                  );
                  final total = data['total'] as int;
                  final rate = total == 0
                      ? 0
                      : (data['correct'] as int) * 100 ~/ total;

                  return ListTile(
                    title: Text(group.title),
                    subtitle: LinearProgressIndicator(
                      value: rate / 100,
                      color: rate < 60 ? accentOrange : primaryBlue,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total == 0 ? '暂无数据' : '$rate%',
                          style: TextStyle(
                            color: rate < 60 ? accentOrange : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            state.setGroups([group.id]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '已选中该组，请切换到专项练习开始刷题',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: neutralGray),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                const ListTile(title: Text('字体大小')),
                Slider(
                  value: state.fontScale,
                  min: .9,
                  max: 1.3,
                  divisions: 4,
                  label: '${(state.fontScale * 100).round()}%',
                  onChanged: state.setScale,
                ),
              ],
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('护眼米黄背景'),
              subtitle: const Text('#FFF9E8'),
              value: state.eyeCare,
              onChanged: state.setEye,
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('清空本地学习记录'),
              subtitle: const Text('将删除错题、收藏与统计数据'),
              trailing: TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('确认清空？'),
                      content: const Text('此操作不可恢复。'),
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
                        const SnackBar(
                          content: Text('本地学习记录已清空'),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  '清空',
                  style: TextStyle(color: dangerRed),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

