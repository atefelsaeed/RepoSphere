import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinnedReposNotifier extends StateNotifier<Set<int>> {
  static const _key = 'pinned_repo_ids';

  PinnedReposNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.map(int.parse).toSet();
  }

  Future<void> toggle(int repoId) async {
    final next = Set<int>.from(state);
    if (!next.remove(repoId)) next.add(repoId);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.map((e) => '$e').toList());
  }

  bool isPinned(int repoId) => state.contains(repoId);
}

final pinnedReposProvider =
    StateNotifierProvider<PinnedReposNotifier, Set<int>>(
  (ref) => PinnedReposNotifier(),
);
