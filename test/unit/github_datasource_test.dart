import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/features/repos/data/datasources/github_remote_datasource.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';

const _repoJson = {
  'id': 1,
  'name': 'repo',
  'full_name': 'alice/repo',
  'description': null,
  'html_url': 'https://github.com/alice/repo',
  'language': 'Dart',
  'stargazers_count': 0,
  'forks_count': 0,
  'watchers_count': 0,
  'open_issues_count': 0,
  'private': false,
  'fork': false,
  'updated_at': '2024-01-01T00:00:00Z',
  'created_at': '2024-01-01T00:00:00Z',
  'default_branch': 'main',
  'topics': <dynamic>[],
  'owner': {
    'login': 'alice',
    'avatar_url': 'https://avatars.githubusercontent.com/u/1',
  },
};

GitHubRemoteDatasource _ds(http.Client client) =>
    GitHubRemoteDatasource(client: client, token: 'test-token');

void main() {
  group('GitHubRemoteDatasource.getRepos', () {
    test('sends correct Authorization header', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode([_repoJson]), 200);
      });

      await _ds(client).getRepos();

      expect(captured?.headers['Authorization'], 'token test-token');
    });

    test('parses list of repos', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode([_repoJson, _repoJson]), 200));

      final repos = await _ds(client).getRepos();
      expect(repos.length, 2);
      expect(repos.first.name, 'repo');
    });

    test('sends page and perPage query params', () async {
      Uri? capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(jsonEncode([_repoJson]), 200);
      });

      await _ds(client).getRepos(page: 3, perPage: 15);

      expect(capturedUri?.queryParameters['page'], '3');
      expect(capturedUri?.queryParameters['per_page'], '15');
    });

    test('throws GitHubAuthException on 401', () async {
      final client = MockClient((_) async =>
          http.Response('{"message":"Bad credentials"}', 401));

      expect(() => _ds(client).getRepos(), throwsA(isA<GitHubAuthException>()));
    });

    test('throws GitHubRateLimitException on 429', () async {
      final client = MockClient((_) async =>
          http.Response('{"message":"rate limited"}', 429));

      expect(
        () => _ds(client).getRepos(),
        throwsA(isA<GitHubRateLimitException>()),
      );
    });

    test('throws GitHubApiException on 404', () async {
      final client = MockClient((_) async =>
          http.Response('{"message":"Not Found"}', 404));

      expect(() => _ds(client).getRepos(), throwsA(isA<GitHubApiException>()));
    });
  });

  group('GitHubRemoteDatasource.getContents', () {
    test('passes ref query param when branch given', () async {
      Uri? capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(jsonEncode(<dynamic>[]), 200);
      });

      await _ds(client).getContents('alice', 'repo', '', ref: 'feature-x');

      expect(capturedUri?.queryParameters['ref'], 'feature-x');
    });

    test('omits ref param when branch is null', () async {
      Uri? capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(jsonEncode(<dynamic>[]), 200);
      });

      await _ds(client).getContents('alice', 'repo', '');

      expect(capturedUri?.queryParameters.containsKey('ref'), false);
    });
  });
}
