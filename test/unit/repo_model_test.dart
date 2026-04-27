import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/features/repos/data/models/repo_model.dart';
import 'package:repo_sphere/features/repos/domain/entities/repo_entity.dart';

const _fixture = {
  'id': 1,
  'name': 'my-repo',
  'full_name': 'alice/my-repo',
  'description': 'A test repository',
  'html_url': 'https://github.com/alice/my-repo',
  'language': 'Dart',
  'stargazers_count': 42,
  'forks_count': 5,
  'watchers_count': 10,
  'open_issues_count': 3,
  'private': false,
  'fork': false,
  'updated_at': '2024-01-15T10:00:00Z',
  'created_at': '2023-06-01T08:00:00Z',
  'default_branch': 'main',
  'topics': ['flutter', 'dart'],
  'owner': {
    'login': 'alice',
    'avatar_url': 'https://avatars.githubusercontent.com/u/1',
  },
};

void main() {
  group('RepoModel.fromJson', () {
    test('parses all fields correctly', () {
      final model = RepoModel.fromJson(_fixture);

      expect(model.id, 1);
      expect(model.name, 'my-repo');
      expect(model.fullName, 'alice/my-repo');
      expect(model.description, 'A test repository');
      expect(model.language, 'Dart');
      expect(model.stargazersCount, 42);
      expect(model.forksCount, 5);
      expect(model.isPrivate, false);
      expect(model.isFork, false);
      expect(model.ownerLogin, 'alice');
      expect(model.defaultBranch, 'main');
      expect(model.topics, ['flutter', 'dart']);
    });

    test('toEntity sets provider to github', () {
      final entity = RepoModel.fromJson(_fixture).toEntity();
      expect(entity.provider, RepoProvider.github);
    });

    test('handles null optional fields', () {
      final json = Map<String, dynamic>.from(_fixture)
        ..['description'] = null
        ..['language'] = null
        ..['default_branch'] = null
        ..['topics'] = <dynamic>[];

      final model = RepoModel.fromJson(json);
      expect(model.description, isNull);
      expect(model.language, isNull);
      expect(model.defaultBranch, isNull);
      expect(model.topics, isEmpty);
    });

    test('defaults missing counts to 0', () {
      final json = Map<String, dynamic>.from(_fixture)
        ..remove('stargazers_count')
        ..remove('forks_count')
        ..remove('open_issues_count');

      final model = RepoModel.fromJson(json);
      expect(model.stargazersCount, 0);
      expect(model.forksCount, 0);
      expect(model.openIssuesCount, 0);
    });
  });
}
