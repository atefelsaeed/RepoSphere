/// Minimal key/value surface of the secure store, so the migration can be
/// tested with a fake.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// One-time move of the saved connections to keychain accessibility
/// `first_unlock`, so background tasks can read tokens while the phone is
/// locked.
///
/// Rewriting a keychain item with a different accessibility is a
/// delete-then-add inside the plugin, so a crash or error in between would
/// lose the user's tokens. This therefore:
///  1. copies the value to a backup key and verifies the copy,
///  2. rewrites the real key and verifies it reads back identical,
///  3. only then drops the backup and records completion.
/// Any failure leaves the backup in place and is retried on the next launch;
/// nothing here ever throws. [readWithBackup] lets readers recover from the
/// brief window where only the backup exists.
class KeychainMigration {
  static const doneKey = 'keychain_first_unlock_v1';
  static const backupKey = 'git_connections_backup_v1';

  final SecretStore store;
  final String connectionsKey;
  const KeychainMigration(this.store, this.connectionsKey);

  /// The connections value, falling back to the backup copy if the main key
  /// is momentarily (or after a failed migration) missing. Read-only.
  Future<String?> readWithBackup() async {
    final main = await store.read(connectionsKey);
    if (main != null && main.isNotEmpty) return main;
    return store.read(backupKey);
  }

  /// Returns true when the store is (now) migrated.
  Future<bool> run() async {
    try {
      if (await store.read(doneKey) == '1') return true;

      final main = await store.read(connectionsKey);
      final hasMain = main != null && main.isNotEmpty;

      if (!hasMain) {
        // A previous run may have died between delete and add: restore.
        final backup = await store.read(backupKey);
        if (backup != null && backup.isNotEmpty) {
          if (!await _writeVerified(connectionsKey, backup)) return false;
          await store.delete(backupKey);
        }
        await store.write(doneKey, '1'); // nothing (more) to migrate
        return true;
      }

      // 1. safety copy
      if (!await _writeVerified(backupKey, main)) return false;
      // 2. rewrite under the new accessibility
      if (!await _writeVerified(connectionsKey, main)) {
        // Make sure the value is back before the next attempt, if possible.
        await _writeVerified(connectionsKey, main);
        return false; // backup stays
      }
      // 3. commit
      await store.delete(backupKey);
      await store.write(doneKey, '1');
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _writeVerified(String key, String value) async {
    try {
      await store.write(key, value);
      return await store.read(key) == value;
    } on Object {
      return false;
    }
  }
}
