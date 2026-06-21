import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/exceptions.dart';
import '../../domain/entities/commit_detail_entity.dart';
import '../../domain/entities/repo_content_entity.dart';
import '../models/activity_event_model.dart';
import '../models/branch_model.dart';
import '../models/gist_model.dart';
import '../models/issue_comment_model.dart';
import '../models/notification_model.dart';
import '../models/release_model.dart';
import '../models/commit_detail_model.dart';
import '../models/commit_model.dart';
import '../models/contributor_model.dart';
import '../models/issue_model.dart';
import '../models/pull_request_model.dart';
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

  Future<List<RepoModel>> getRepos({int page = 1, int perPage = 30}) async {
    final uri = Uri.parse('${AppConstants.githubApiBase}/user/repos')
        .replace(queryParameters: {
      'per_page': '$perPage',
      'page': '$page',
      'sort': 'updated',
      'affiliation': 'owner,collaborator,organization_member',
    });
    final response = await _client.get(uri, headers: _headers);
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

  Future<List<BranchModel>> getBranches(String owner, String repo) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/branches?per_page=100'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommitModel>> getCommits(
    String owner,
    String repo, {
    String? branch,
    int page = 1,
    int perPage = 30,
  }) async {
    final uri = Uri.parse(
            '${AppConstants.githubApiBase}/repos/$owner/$repo/commits')
        .replace(queryParameters: {
      'per_page': '$perPage',
      'page': '$page',
      if (branch != null && branch.isNotEmpty) 'sha': branch,
    });
    final response = await _client.get(uri, headers: _headers);
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CommitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PullRequestModel>> getPullRequests(
    String owner,
    String repo, {
    String state = 'open',
    int page = 1,
    int perPage = 30,
  }) async {
    final uri =
        Uri.parse('${AppConstants.githubApiBase}/repos/$owner/$repo/pulls')
            .replace(queryParameters: {
      'state': state,
      'per_page': '$perPage',
      'page': '$page',
      'sort': 'updated',
    });
    final response = await _client.get(uri, headers: _headers);
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PullRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<IssueModel>> getIssues(
    String owner,
    String repo, {
    String state = 'open',
    int page = 1,
    int perPage = 30,
  }) async {
    final uri =
        Uri.parse('${AppConstants.githubApiBase}/repos/$owner/$repo/issues')
            .replace(queryParameters: {
      'state': state,
      'per_page': '$perPage',
      'page': '$page',
      'sort': 'updated',
    });
    final response = await _client.get(uri, headers: _headers);
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    // GitHub issues endpoint returns PRs too — filter them out
    return list
        .where((e) => (e as Map<String, dynamic>)['pull_request'] == null)
        .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RepoModel>> searchRepos(String query,
      {int page = 1, int perPage = 30}) async {
    final uri =
        Uri.parse('${AppConstants.githubApiBase}/search/repositories').replace(
      queryParameters: {
        'q': query,
        'sort': 'stars',
        'order': 'desc',
        'per_page': '$perPage',
        'page': '$page',
      },
    );
    final response = await _client.get(uri, headers: _headers);
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>;
    return items
        .map((e) => RepoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommitDetailEntity> getCommitDetail(
      String owner, String repo, String sha) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/commits/$sha'),
      headers: _headers,
    );
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CommitDetailModel.fromJson(json).entity;
  }

  Future<String?> getReadme(String owner, String repo) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.githubApiBase}/repos/$owner/$repo/readme'),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (json['content'] as String? ?? '').replaceAll('\n', '');
    return utf8.decode(base64.decode(raw));
  }

  Future<List<RepoContentItem>> getContents(
      String owner, String repo, String path, {String? ref}) async {
    final uri = Uri.parse(
            '${AppConstants.githubApiBase}/repos/$owner/$repo/contents/$path')
        .replace(queryParameters: ref != null ? {'ref': ref} : null);
    final response = await _client.get(uri, headers: _headers);
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

  Future<Map<String, int>> getLanguages(String owner, String repo) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/languages'),
      headers: _headers,
    );
    if (response.statusCode == 404) return {};
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, v as int));
  }

  Future<List<ContributorModel>> getContributors(
      String owner, String repo, {int perPage = 8}) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/contributors?per_page=$perPage&anon=false'),
      headers: _headers,
    );
    if (response.statusCode == 204) return [];
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .where((e) => (e as Map)['type'] == 'User')
        .map((e) => ContributorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isStarred(String owner, String repo) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/user/starred/$owner/$repo'),
      headers: _headers,
    );
    return response.statusCode == 204;
  }

  Future<void> starRepo(String owner, String repo) async {
    await _client.put(
      Uri.parse(
          '${AppConstants.githubApiBase}/user/starred/$owner/$repo'),
      headers: {..._headers, 'Content-Length': '0'},
    );
  }

  Future<void> unstarRepo(String owner, String repo) async {
    await _client.delete(
      Uri.parse(
          '${AppConstants.githubApiBase}/user/starred/$owner/$repo'),
      headers: _headers,
    );
  }

  Future<List<NotificationModel>> getNotifications(
      {bool unreadOnly = false}) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/notifications?all=${!unreadOnly}&per_page=50'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String threadId) async {
    await _client.patch(
      Uri.parse(
          '${AppConstants.githubApiBase}/notifications/threads/$threadId'),
      headers: _headers,
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _client.put(
      Uri.parse('${AppConstants.githubApiBase}/notifications'),
      headers: {..._headers, 'Content-Length': '0'},
    );
  }

  Future<List<ReleaseModel>> getReleases(String owner, String repo,
      {int perPage = 10}) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/releases?per_page=$perPage'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReleaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<IssueCommentModel>> getIssueComments(
      String owner, String repo, int number) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/issues/$number/comments?per_page=100'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            IssueCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GistModel>> getGists({int perPage = 30}) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/gists?per_page=$perPage'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => GistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityEventModel>> getUserEvents(String username,
      {int perPage = 30}) async {
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.githubApiBase}/users/$username/events?per_page=$perPage'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            ActivityEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  ContentType _parseType(String type) => switch (type) {
        'dir' => ContentType.dir,
        'symlink' => ContentType.symlink,
        'submodule' => ContentType.submodule,
        _ => ContentType.file,
      };

  Future<IssueModel> createIssue(
    String owner,
    String repo, {
    required String title,
    String? body,
    List<String> labels = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.githubApiBase}/repos/$owner/$repo/issues'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        if (body != null && body.isNotEmpty) 'body': body,
        if (labels.isNotEmpty) 'labels': labels,
      }),
    );
    if (response.statusCode != 201) {
      _checkResponse(response);
    }
    return IssueModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<IssueCommentModel> addIssueComment(
      String owner, String repo, int number, String body) async {
    final response = await _client.post(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/issues/$number/comments'),
      headers: _headers,
      body: jsonEncode({'body': body}),
    );
    if (response.statusCode != 201) _checkResponse(response);
    return IssueCommentModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> mergePullRequest(String owner, String repo, int number) async {
    final response = await _client.put(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/pulls/$number/merge'),
      headers: _headers,
      body: jsonEncode({'merge_method': 'merge'}),
    );
    _checkResponse(response);
  }

  /// state: 'open' or 'closed'.
  Future<void> setIssueState(
      String owner, String repo, int number, String state) async {
    final response = await _client.patch(
      Uri.parse(
          '${AppConstants.githubApiBase}/repos/$owner/$repo/issues/$number'),
      headers: _headers,
      body: jsonEncode({'state': state}),
    );
    _checkResponse(response);
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    switch (response.statusCode) {
      case 401:
        throw const GitHubAuthException(
            'Invalid or expired token. Please reconnect.');
      case 403:
        final remaining = response.headers['x-ratelimit-remaining'];
        if (remaining == '0') {
          final resetTs =
              int.tryParse(response.headers['x-ratelimit-reset'] ?? '');
          final resetIn =
              resetTs != null ? _resetTimeString(resetTs) : 'a moment';
          throw GitHubRateLimitException(
              'Rate limit exceeded. Resets in $resetIn.');
        }
        throw const GitHubApiException(
            'Access forbidden. Check your token scopes.');
      case 404:
        throw const GitHubApiException('Resource not found.');
      case 422:
        throw const GitHubApiException(
            'Invalid request. Check the data and try again.');
      case 429:
        throw const GitHubRateLimitException(
            'Too many requests. Try again in a moment.');
      default:
        if (response.statusCode >= 500) {
          throw const GitHubApiException(
              'GitHub is having issues. Try again later.');
        }
        throw GitHubApiException(
            'Unexpected error (${response.statusCode}).');
    }
  }

  String _resetTimeString(int unixTimestamp) {
    final resetAt =
        DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    final diff = resetAt.difference(DateTime.now());
    if (diff.inSeconds < 60) return 'less than a minute';
    if (diff.inMinutes == 1) return '1 minute';
    return '${diff.inMinutes} minutes';
  }
}
