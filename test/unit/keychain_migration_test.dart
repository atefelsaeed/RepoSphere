import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/features/auth/data/keychain_migration.dart';

const _main = 'git_connections';

/// In-memory store with switchable faults, mimicking the plugin's
/// delete-then-add behaviour when rewriting an existing key.
class _FakeStore implements SecretStore {
  final data = <String, String>{};
  final writes = <String>[];

  /// Called on every write; can throw or drop the value to simulate faults.
  /// Returns true when the write should be applied.
  bool Function(String key, int nth)? onWrite;
  int _n = 0;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    writes.add(key);
    final apply = onWrite?.call(key, ++_n) ?? true;
    // The plugin deletes the old entry before adding the new one.
    data.remove(key);
    if (apply) data[key] = value;
  }

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  const tokens = '[{"id":"1","token":"secret"}]';

  late _FakeStore store;
  late KeychainMigration migration;
  setUp(() {
    store = _FakeStore();
    migration = KeychainMigration(store, _main);
  });

  test('migrates: value intact, backup removed, completion recorded', () async {
    store.data[_main] = tokens;

    expect(await migration.run(), isTrue);

    expect(store.data[_main], tokens);
    expect(store.data.containsKey(KeychainMigration.backupKey), isFalse);
    expect(store.data[KeychainMigration.doneKey], '1');
  });

  test('is a no-op once done (does not rewrite tokens again)', () async {
    store.data[_main] = tokens;
    await migration.run();
    store.writes.clear();

    expect(await migration.run(), isTrue);
    expect(store.writes, isEmpty);
  });

  test('nothing saved: just records completion', () async {
    expect(await migration.run(), isTrue);
    expect(store.data.keys, [KeychainMigration.doneKey]);
  });

  test('backup write fails: main key is never touched, will retry', () async {
    store.data[_main] = tokens;
    store.onWrite = (key, _) {
      if (key == KeychainMigration.backupKey) throw StateError('disk');
      return true;
    };

    expect(await migration.run(), isFalse);

    expect(store.data[_main], tokens);
    expect(store.writes, [KeychainMigration.backupKey]);
    expect(store.data.containsKey(KeychainMigration.doneKey), isFalse);
  });

  test('rewrite loses the value: backup keeps it and readers recover',
      () async {
    store.data[_main] = tokens;
    // Backup (1st write) OK, both main rewrites silently drop the value.
    store.onWrite = (key, _) => key != _main;

    expect(await migration.run(), isFalse);

    expect(store.data.containsKey(_main), isFalse);
    expect(store.data[KeychainMigration.backupKey], tokens);
    expect(store.data.containsKey(KeychainMigration.doneKey), isFalse);
    // Readers fall back to the backup, so the user stays logged in.
    expect(await migration.readWithBackup(), tokens);
  });

  test('rewrite throws on first try, second attempt restores the value',
      () async {
    store.data[_main] = tokens;
    var mainWrites = 0;
    store.onWrite = (key, _) {
      if (key == _main && ++mainWrites == 1) throw StateError('interrupted');
      return true;
    };

    expect(await migration.run(), isFalse); // not committed...
    expect(store.data[_main], tokens); // ...but the value was put back
    expect(store.data[KeychainMigration.backupKey], tokens);

    // Next launch finishes the job.
    store.onWrite = null;
    expect(await migration.run(), isTrue);
    expect(store.data[_main], tokens);
    expect(store.data.containsKey(KeychainMigration.backupKey), isFalse);
    expect(store.data[KeychainMigration.doneKey], '1');
  });

  test('crashed run (only backup left) is restored on next launch', () async {
    store.data[KeychainMigration.backupKey] = tokens; // main lost mid-flight

    expect(await migration.readWithBackup(), tokens);
    expect(await migration.run(), isTrue);

    expect(store.data[_main], tokens);
    expect(store.data.containsKey(KeychainMigration.backupKey), isFalse);
    expect(store.data[KeychainMigration.doneKey], '1');
  });

  test('readWithBackup prefers the main value', () async {
    store.data[_main] = tokens;
    store.data[KeychainMigration.backupKey] = 'stale';
    expect(await migration.readWithBackup(), tokens);
  });

  test('never throws, even if the store is unusable', () async {
    final broken = KeychainMigration(_ThrowingStore(), _main);
    expect(await broken.run(), isFalse);
  });
}

class _ThrowingStore implements SecretStore {
  @override
  Future<String?> read(String key) async => throw StateError('keychain');
  @override
  Future<void> write(String key, String value) async =>
      throw StateError('keychain');
  @override
  Future<void> delete(String key) async => throw StateError('keychain');
}
