import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/exceptions.dart';
import '../../domain/entities/repo_content_entity.dart';
import '../models/repo_model.dart';
import '../models/user_model.dart';

class GitHubRemoteDatasource {
  final http.Client _client;
  final String _token;

  const GitHubRemoteDatasource({
    required http.Client client,
    required String token,
  })  : _client = client,
        _token = token;

  Map<String, String> get _headers => {
        'Authorization': 'token $_token',
        'Accept': 'application/vnd.github.v3+json',
      };

  Future<UserModel> getUser() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.githubApiBase}/user'),
      headers: _headers,
    );
    _checkResponse(response);
    return UserModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<RepoModel>> getRepos() async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/user/repos?per_page=${AppConstants.reposPerPage}&sort=updated&affiliation=owner,collaborator,organization_member'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => RepoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RepoModel>> getStarredRepos() async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/user/starred?per_page=${AppConstants.reposPerPage}&sort=updated'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => RepoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RepoContentItem>> getContents(
      String owner, String repo, String path) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/contents/$path'),
      headers: _headers,
    );
    _checkResponse(response);
    final body = jsonDecode(response.body);
    final list = body as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return RepoContentItem(
        name: m['name'] as String,
        path: m['path'] as String,
        type: _parseType(m['type'] as String),
        size: m['size'] as int?,
        downloadUrl: m['download_url'] as String?,
        sha: m['sha'] as String,
      );
    }).toList()
      ..sort((a, b) {
        if (a.isDir && !b.isDir) return -1;
        if (!a.isDir && b.isDir) return 1;
        return a.name.compareTo(b.name);
      });
  }

  Future<FileContent> getFileContent(
      String owner, String repo, String path) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/contents/$path'),
      headers: _headers,
    );
    _checkResponse(response);
    final m = jsonDecode(response.body) as Map<String, dynamic>;
    final rawContent = (m['content'] as String? ?? '').replaceAll('\n', '');
    final decoded = utf8.decode(base64.decode(rawContent));
    return FileContent(
      path: m['path'] as String,
      content: decoded,
      encoding: m['encoding'] as String? ?? 'base64',
    );
  }

  ContentType _parseType(String type) => switch (type) {
        'dir' => ContentType.dir,
        'symlink' => ContentType.symlink,
        'submodule' => ContentType.submodule,
        _ => ContentType.file,
      };

  void _checkResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return;
      case 401:
        throw const GitHubAuthException(
            'Invalid or expired token. Please reconnect.');
      case 403:
        throw const GitHubRateLimitException(
            'API rate limit exceeded. Try again later.');
      default:
        throw GitHubApiException(
            'Request failed with status ${response.statusCode}.');
    }
  }
}
