import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';

void main() {
  group('GitConnection', () {
    const conn = GitConnection(
      id: 'abc',
      type: GitProviderType.azureDevOps,
      accountLogin: 'octo',
      token: 'pat-123',
      baseUrl: 'https://dev.azure.com/myorg',
    );

    test('JSON round-trips all fields', () {
      final restored = GitConnection.fromJson(conn.toJson());
      expect(restored.id, conn.id);
      expect(restored.type, GitProviderType.azureDevOps);
      expect(restored.accountLogin, 'octo');
      expect(restored.token, 'pat-123');
      expect(restored.baseUrl, 'https://dev.azure.com/myorg');
    });

    test('displayName combines provider label and login', () {
      expect(conn.displayName, 'Azure DevOps · octo');
    });

    test('encodeList / decodeList preserve the list', () {
      const a = GitConnection(
          id: '1', type: GitProviderType.github, accountLogin: 'a', token: 't1');
      const b = GitConnection(
          id: '2', type: GitProviderType.gitlab, accountLogin: 'b', token: 't2');
      final decoded = GitConnection.decodeList(GitConnection.encodeList([a, b]));
      expect(decoded.length, 2);
      expect(decoded[0].type, GitProviderType.github);
      expect(decoded[1].type, GitProviderType.gitlab);
    });

    test('decodeList handles null/empty', () {
      expect(GitConnection.decodeList(null), isEmpty);
      expect(GitConnection.decodeList(''), isEmpty);
    });

    test('GitProviderType.fromSlug round-trips and falls back', () {
      for (final t in GitProviderType.values) {
        expect(GitProviderType.fromSlug(t.slug), t);
      }
      expect(GitProviderType.fromSlug('nope'), GitProviderType.github);
    });
  });
}
