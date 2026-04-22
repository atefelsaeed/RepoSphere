import '../../domain/entities/repo_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../datasources/github_remote_datasource.dart';

class GitHubRepoRepositoryImpl implements GitProvider {
  final GitHubRemoteDatasource _datasource;

  const GitHubRepoRepositoryImpl(this._datasource);

  @override
  Future<UserEntity> getUser() async {
    final model = await _datasource.getUser();
    return model.toEntity();
  }

  @override
  Future<List<RepoEntity>> getRepos() async {
    final models = await _datasource.getRepos();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RepoEntity>> getStarredRepos() async {
    final models = await _datasource.getStarredRepos();
    return models.map((m) => m.toEntity()).toList();
  }
}
