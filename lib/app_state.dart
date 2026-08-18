import 'package:flutter/foundation.dart';

import 'data/word_bank_repository.dart';
import 'models/word.dart';
import 'services/local_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.store);

  final LocalStore store;
  final repository = WordBankRepository();

  List<Chapter> chapters = [];
  Set<int> selectedGroups = {};
  Set<String> favorites = {};
  Map<String, int> wrongCounts = {};
  Map<String, String> notes = {};
  bool eyeCare = false;
  double fontScale = 1;
  bool loading = true;

  Future<void> load() async {
    chapters = await repository.load();
    selectedGroups = store.selectedGroups.toSet();
    favorites = store.favorites;
    wrongCounts = store.wrongCounts;
    notes = store.notes;
    eyeCare = store.eyeCare;
    fontScale = store.fontScale;
    loading = false;
    notifyListeners();
  }

  Future<void> toggleGroup(int id) async {
    if (selectedGroups.contains(id)) {
      selectedGroups.remove(id);
    } else {
      selectedGroups.add(id);
    }
    await store.saveSelectedGroups(selectedGroups.toList());
    notifyListeners();
  }

  Future<void> setGroups(Iterable<int> ids) async {
    selectedGroups = ids.toSet();
    await store.saveSelectedGroups(selectedGroups.toList());
    notifyListeners();
  }

  Future<void> toggleFavorite(String name) async {
    final value = !favorites.contains(name);
    await store.setFavorite(name, value);
    favorites = store.favorites;
    notifyListeners();
  }

  Future<void> wrong(String name) async {
    await store.addWrong(name);
    wrongCounts = store.wrongCounts;
    notifyListeners();
  }

  Future<void> setNote(String name, String note) async {
    await store.setNote(name, note);
    notes = store.notes;
    notifyListeners();
  }

  Future<void> setEye(bool value) async {
    await store.setEyeCare(value);
    eyeCare = value;
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    await store.setFontScale(value);
    fontScale = value;
    notifyListeners();
  }

  Future<void> clearLearning() async {
    await store.clearLearning();
    favorites = {};
    wrongCounts = {};
    notes = {};
    notifyListeners();
  }

  List<WordGroup> get allGroups =>
      chapters.expand((chapter) => chapter.groups).toList();

  List<WordEntry> get allWords =>
      allGroups.expand((group) => group.words).toList();

  WordEntry? wordByName(String name) {
    for (final word in allWords) {
      if (word.name == name) {
        return word;
      }
    }
    return null;
  }
}

