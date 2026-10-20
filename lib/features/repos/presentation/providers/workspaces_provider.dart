import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/workspace_entity.dart';

/// User-defined workspaces (one per client), persisted locally.
class WorkspacesNotifier extends StateNotifier<List<Workspace>> {
  static const _key = 'workspaces_v1';

  WorkspacesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      state = (jsonDecode(raw) as List)
          .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      // Corrupt data: start empty rather than crash.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((w) => w.toJson()).toList()));
    } on Object {
      // ignore
    }
  }

  /// Adds [w] or replaces the workspace with the same id.
  void upsert(Workspace w) {
    final exists = state.any((x) => x.id == w.id);
    state = exists
        ? [for (final x in state) x.id == w.id ? w : x]
        : [...state, w];
    _save();
  }

  void remove(String id) {
    state = state.where((w) => w.id != id).toList();
    _save();
  }

  /// Drops rules pointing at accounts that no longer exist.
  void pruneConnections(Set<String> liveIds) {
    final next = [
      for (final w in state)
        w.copyWith(
            rules: w.rules.where((r) => liveIds.contains(r.connectionId)).toList())
    ];
    final changed = [
      for (var i = 0; i < next.length; i++)
        next[i].rules.length != state[i].rules.length
    ].any((c) => c);
    if (changed) {
      state = next;
      _save();
    }
  }
}

final workspacesProvider =
    StateNotifierProvider<WorkspacesNotifier, List<Workspace>>(
        (ref) => WorkspacesNotifier());

/// Sentinel for the "no workspace" filter.
const kUnassignedWorkspace = '__none__';

/// Selected workspace id, [kUnassignedWorkspace], or null for everything.
final inboxWorkspaceFilterProvider = StateProvider<String?>((ref) => null);

/// Workspace for an inbox item, or null when unassigned.
final workspaceForItemProvider =
    Provider.family<Workspace?, InboxItem>((ref, item) =>
        Workspace.resolve(ref.watch(workspacesProvider), item));
