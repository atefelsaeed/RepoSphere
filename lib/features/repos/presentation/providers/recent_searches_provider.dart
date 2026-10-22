import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../auth/presentation/providers/connections_provider.dart';

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _load();
  }

  static const _key = PrefKeys.recentSearches;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final updated = [
      query,
      ...state.where((s) => s != query),
    ].take(10).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_key, updated);
  }

  Future<void> remove(String query) async {
    final updated = state.where((s) => s != query).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_key, updated);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_key);
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) {
    ref.watch(hasConnectionsProvider);
    return RecentSearchesNotifier();
  },
);
