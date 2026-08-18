# 填空策｜Flutter 离线刷题 APP

这是一个纯离线 Flutter 项目：词库从 `assets/json/word_bank.json` 读取，错题、收藏、勾选状态、统计和设置均由 `shared_preferences` 保存。

## 运行

```bash
flutter pub get
flutter run
```

当前工作区未安装 Flutter SDK，因此本项目在此处无法执行 `flutter analyze` 或模拟器运行验证；在安装 Flutter 3.19+ 后可直接运行上述命令。

## 目录

- `lib/main.dart`：四个 Tab、刷题、报告、词典、错题收藏、统计、设置页面
- `lib/utils/exercise_maker.dart`：严格按选中 groupId 生成题目，易混干扰项同组优先
- `lib/models/`：词库和题目模型
- `lib/data/word_bank_repository.dart`：离线 JSON 加载
- `lib/services/local_store.dart`：本地学习数据存储
- `assets/json/word_bank.json`：样例词库，含第一章第 1、2 组及其他章节示例组

项目不包含 dio、http 或任何网络请求代码。
