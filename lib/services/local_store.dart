import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this.prefs); final SharedPreferences prefs;
  List<int> get selectedGroups => (prefs.getStringList('selected_groups') ?? []).map(int.parse).toList();
  Future<void> saveSelectedGroups(List<int> ids) => prefs.setStringList('selected_groups', ids.map((e) => '$e').toList());
  Set<String> get favorites => (prefs.getStringList('favorites') ?? []).toSet();
  Future<void> setFavorite(String word, bool value) async { final v = favorites; value ? v.add(word) : v.remove(word); await prefs.setStringList('favorites', v.toList()); }
  Map<String, String> get notes => Map<String, String>.from(jsonDecode(prefs.getString('notes') ?? '{}').map((k, v) => MapEntry(k, v.toString())));
  Future<void> setNote(String word, String note) async { final v = notes; v[word] = note; await prefs.setString('notes', jsonEncode(v)); }
  Map<String, int> get wrongCounts => Map<String, int>.from((jsonDecode(prefs.getString('wrong_counts') ?? '{}') as Map).map((k, v) => MapEntry(k, v as int)));
  Future<void> addWrong(String word) async { final v = wrongCounts; v[word] = (v[word] ?? 0) + 1; await prefs.setString('wrong_counts', jsonEncode(v)); }
  bool get eyeCare => prefs.getBool('eye_care') ?? false;
  double get fontScale => prefs.getDouble('font_scale') ?? 1;
  Future<void> setEyeCare(bool v) => prefs.setBool('eye_care', v);
  Future<void> setFontScale(double v) => prefs.setDouble('font_scale', v);
  Map<String, dynamic> get stats => jsonDecode(prefs.getString('stats') ?? '{"total":0,"correct":0,"minutes":0,"groups":{}}');
  Future<void> record({required int total, required int correct, required int minutes, required Map<int, List<int>> groupScore}) async {
    final old = stats; old['total'] = (old['total'] as int) + total; old['correct'] = (old['correct'] as int) + correct; old['minutes'] = (old['minutes'] as int) + minutes;
    final groups = Map<String, dynamic>.from(old['groups'] as Map? ?? {});
    groupScore.forEach((id, score) { final item = Map<String, dynamic>.from(groups['$id'] as Map? ?? {'total': 0, 'correct': 0}); item['total'] = (item['total'] as int) + score[0]; item['correct'] = (item['correct'] as int) + score[1]; groups['$id'] = item; });
    old['groups'] = groups; await prefs.setString('stats', jsonEncode(old));
  }
  Future<void> clearLearning() async { await prefs.remove('wrong_counts'); await prefs.remove('stats'); await prefs.remove('favorites'); await prefs.remove('notes'); }
}
