import '../entities/repo_entity.dart';
import '../entities/user_entity.dart';

enum RepoFilter { all, owned, forked, starred, publicOnly, privateOnly }

abstract class GitProvider {
  Future<UserEntity> getUser();
  Future<List<RepoEntity>> getRepos();
  Future<List<RepoEntity>> getStarredRepos();
}
