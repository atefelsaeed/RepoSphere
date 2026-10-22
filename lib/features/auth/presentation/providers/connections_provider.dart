import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/secure_token_storage.dart';
import '../../domain/git_connection.dart';
import '../../../../core/utils/account_data_cleaner.dart';
import '../../../notifications/background_inbox_check.dart';

/// Source of truth for all connected accounts. Persists to secure storage and
/// migrates legacy single-account tokens on first load.
final connectionsProvider =
    AsyncNotifierProvider<ConnectionsNotifier, List<GitConnection>>(
        ConnectionsNotifier.new);

class ConnectionsNotifier extends AsyncNotifier<List<GitConnection>> {
  @override
  Future<List<GitConnection>> build() => SecureTokenStorage.readConnections();

  List<GitConnection> get _current => state.valueOrNull ?? const [];

  Future<void> add(GitConnection connection) async {
    final next = [..._current, connection];
    await SecureTokenStorage.writeConnections(next);
    state = AsyncData(next);
  }

  Future<void> remove(String id) async {
    final next = _current.where((c) => c.id != id).toList();
    await SecureTokenStorage.writeConnections(next);
    if (next.isEmpty) await _wipe();
    state = AsyncData(next);
  }

  Future<void> removeAll() async {
    await _wipe();
    state = const AsyncData([]);
  }

  /// Last account gone: clear every credential (including stale legacy keys),
  /// the cached inbox/search/workspace data derived from those accounts, and
  /// the background check.
  Future<void> _wipe() async {
    await SecureTokenStorage.clear();
    await clearAccountScopedPrefs();
    await cancelInboxChecks();
  }

  Future<void> updateConnection(GitConnection connection) async {
    final next =
        _current.map((c) => c.id == connection.id ? connection : c).toList();
    await SecureTokenStorage.writeConnections(next);
    state = AsyncData(next);
  }
}

/// True once at least one account is connected.
final hasConnectionsProvider = Provider<bool>((ref) {
  final conns = ref.watch(connectionsProvider).valueOrNull ?? const [];
  return conns.isNotEmpty;
});
