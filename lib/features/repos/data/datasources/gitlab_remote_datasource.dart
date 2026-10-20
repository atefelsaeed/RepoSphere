import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/exceptions.dart';
import '../models/gitlab_project_model.dart';

/// Thin REST client for the GitLab v4 API. New endpoints return decoded JSON;
/// mapping to domain entities lives in `GitLabRepoRepositoryImpl`.
class GitLabRemoteDatasource {
  final http.Client client;
  final String token;
  final String base;

  GitLabRemoteDatasource({
    required this.client,
    required this.token,
    String? baseUrl,
  }) : base = _normaliseBase(baseUrl);

  static String _normaliseBase(String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) return 'https://gitlab.com/api/v4';
    final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api/v4') ? trimmed : '$trimmed/api/v4';
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    switch (r.statusCode) {
      case 401:
        throw const GitHubAuthException(
            'Invalid or expired GitLab token. Please reconnect.');
      case 403:
        throw const GitHubApiException(
            'Access forbidden. Check your GitLab token scopes.');
      case 404:
        throw const GitHubApiException('Resource not found.');
      case 429:
        throw const GitHubRateLimitException(
            'Too many requests. Try again in a moment.');
      default:
        if (r.statusCode >= 500) {
          throw const GitHubApiException(
              'GitLab is having issues. Try again later.');
        }
        throw GitHubApiException('Unexpected error (${r.statusCode}).');
    }
  }

  Future<dynamic> _get(String path) async {
    final r = await client.get(Uri.parse('$base$path'), headers: _headers);
    _check(r);
    return jsonDecode(r.body);
  }

  // ─── Account ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUserJson() async =>
      await _get('/user') as Map<String, dynamic>;

  /// Verify token by hitting /user — returns the user's username.
  Future<String> verifyToken() async {
    final json = await getUserJson();
    return json['username'] as String;
  }

  // ─── Projects ───────────────────────────────────────────────────────────────
  Future<List<GitLabProjectModel>> getProjects({int perPage = 100}) async {
    final list = await _get(
            '/projects?membership=true&per_page=$perPage&order_by=last_activity_at&archived=false')
        as List<dynamic>;
    return list
        .map((j) => GitLabProjectModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<GitLabProjectModel>> getStarredProjects(
      {int perPage = 100}) async {
    final list = await _get(
            '/projects?starred=true&per_page=$perPage&order_by=last_activity_at')
        as List<dynamic>;
    return list
        .map((j) => GitLabProjectModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<GitLabProjectModel>> searchProjects(String query,
      {int perPage = 30}) async {
    final list = await _get(
            '/projects?search=${Uri.encodeQueryComponent(query)}&per_page=$perPage&order_by=star_count')
        as List<dynamic>;
    return list
        .map((j) => GitLabProjectModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ─── Code ───────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getBranches(int projectId) async =>
      await _get('/projects/$projectId/repository/branches?per_page=100')
          as List<dynamic>;

  Future<List<dynamic>> getCommits(int projectId,
      {String? branch, int page = 1, int perPage = 30}) async {
    final ref = (branch != null && branch.isNotEmpty)
        ? '&ref_name=${Uri.encodeQueryComponent(branch)}'
        : '';
    return await _get(
            '/projects/$projectId/repository/commits?per_page=$perPage&page=$page$ref')
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> getCommit(int projectId, String sha) async =>
      await _get('/projects/$projectId/repository/commits/$sha')
          as Map<String, dynamic>;

  Future<List<dynamic>> getCommitDiff(int projectId, String sha) async =>
      await _get('/projects/$projectId/repository/commits/$sha/diff')
          as List<dynamic>;

  Future<List<dynamic>> getTree(int projectId, String path,
      {String? ref}) async {
    final refQ = (ref != null && ref.isNotEmpty)
        ? '&ref=${Uri.encodeQueryComponent(ref)}'
        : '';
    final pathQ =
        path.isNotEmpty ? '&path=${Uri.encodeQueryComponent(path)}' : '';
    return await _get(
            '/projects/$projectId/repository/tree?per_page=100$pathQ$refQ')
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> getFile(int projectId, String path,
      {String? ref}) async {
    final refQ = ref != null && ref.isNotEmpty
        ? Uri.encodeQueryComponent(ref)
        : 'HEAD';
    final encoded = Uri.encodeComponent(path);
    return await _get(
            '/projects/$projectId/repository/files/$encoded?ref=$refQ')
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLanguages(int projectId) async =>
      await _get('/projects/$projectId/languages') as Map<String, dynamic>;

  Future<List<dynamic>> getContributors(int projectId) async =>
      await _get('/projects/$projectId/repository/contributors?per_page=8')
          as List<dynamic>;

  // ─── Collaboration ──────────────────────────────────────────────────────────
  Future<List<dynamic>> getMergeRequests(int projectId,
          {String state = 'opened', int page = 1, int perPage = 30}) async =>
      await _get(
              '/projects/$projectId/merge_requests?state=$state&per_page=$perPage&page=$page&order_by=updated_at')
          as List<dynamic>;

  Future<List<dynamic>> getIssues(int projectId,
          {String state = 'opened', int page = 1, int perPage = 30}) async =>
      await _get(
              '/projects/$projectId/issues?state=$state&per_page=$perPage&page=$page&order_by=updated_at')
          as List<dynamic>;

  Future<List<dynamic>> getIssueNotes(int projectId, int iid) async =>
      await _get('/projects/$projectId/issues/$iid/notes?per_page=100&sort=asc')
          as List<dynamic>;

  Future<List<dynamic>> getReleases(int projectId) async =>
      await _get('/projects/$projectId/releases?per_page=10') as List<dynamic>;

  // ─── Inbox (account-wide) ───────────────────────────────────────────────────
  /// Account-wide MR/issue lists, e.g. `merge_requests?scope=assigned_to_me`.
  Future<List<dynamic>> getAccountList(String path) async =>
      await _get(path) as List<dynamic>;

  // ─── Account feeds ──────────────────────────────────────────────────────────
  Future<List<dynamic>> getTodos() async =>
      await _get('/todos?per_page=50') as List<dynamic>;

  Future<List<dynamic>> getEvents() async =>
      await _get('/events?per_page=30') as List<dynamic>;

  Future<void> markTodoDone(String id) async {
    final r = await client.post(Uri.parse('$base/todos/$id/mark_as_done'),
        headers: _headers);
    _check(r);
  }

  Future<void> markAllTodosDone() async {
    final r =
        await client.post(Uri.parse('$base/todos/mark_as_done'), headers: _headers);
    _check(r);
  }
}
