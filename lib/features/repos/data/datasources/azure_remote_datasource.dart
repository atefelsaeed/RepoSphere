import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/exceptions.dart';

/// Thin REST client for Azure DevOps. [orgUrl] is the organisation base
/// (e.g. `https://dev.azure.com/myorg`). Auth uses Basic with an empty user and
/// the PAT as password. New endpoints return decoded JSON; mapping lives in
/// `AzureRepoRepositoryImpl`.
class AzureRemoteDatasource {
  final http.Client client;
  final String pat;
  final String orgUrl;

  static const _apiVersion = '7.1';

  AzureRemoteDatasource({
    required this.client,
    required this.pat,
    required String orgUrl,
  }) : orgUrl = orgUrl.replaceAll(RegExp(r'/+$'), '');

  Map<String, String> get _headers => {
        'Authorization':
            'Basic ${base64.encode(utf8.encode(':$pat'))}',
        'Content-Type': 'application/json',
      };

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    switch (r.statusCode) {
      case 401:
      case 203: // Azure returns 203 (sign-in page) for bad PATs
        throw const GitHubAuthException(
            'Invalid or expired Azure DevOps token. Please reconnect.');
      case 403:
        throw const GitHubApiException(
            'Access forbidden. Check your Azure DevOps token scopes.');
      case 404:
        throw const GitHubApiException('Resource not found.');
      default:
        if (r.statusCode >= 500) {
          throw const GitHubApiException(
              'Azure DevOps is having issues. Try again later.');
        }
        throw GitHubApiException('Unexpected error (${r.statusCode}).');
    }
  }

  String _sep(String url) => url.contains('?') ? '&' : '?';

  Future<dynamic> _get(String url) async {
    final full = '$url${_sep(url)}api-version=$_apiVersion';
    final r = await client.get(Uri.parse(full), headers: _headers);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<dynamic> _post(String url, Map<String, dynamic> body) async {
    final full = '$url${_sep(url)}api-version=$_apiVersion';
    final r = await client.post(Uri.parse(full),
        headers: _headers, body: jsonEncode(body));
    _check(r);
    return jsonDecode(r.body);
  }

  // ─── Account ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getConnectionData() async => await _get(
          '$orgUrl/_apis/connectionData?connectOptions=none&lastChangeId=-1&lastChangeId64=-1')
      as Map<String, dynamic>;

  // ─── Repositories ────────────────────────────────────────────────────────────
  /// All Git repositories across the organisation's projects.
  Future<List<dynamic>> getRepositories() async {
    final json = await _get('$orgUrl/_apis/git/repositories') as Map<String, dynamic>;
    return json['value'] as List<dynamic>? ?? const [];
  }

  // ─── Code ────────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getBranches(String repoId) async {
    final json = await _get(
            '$orgUrl/_apis/git/repositories/$repoId/refs?filter=heads/')
        as Map<String, dynamic>;
    return json['value'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> getCommits(String repoId,
      {String? branch, int top = 30}) async {
    final branchQ = (branch != null && branch.isNotEmpty)
        ? '&searchCriteria.itemVersion.version=${Uri.encodeQueryComponent(branch)}'
        : '';
    final json = await _get(
            '$orgUrl/_apis/git/repositories/$repoId/commits?searchCriteria.\$top=$top$branchQ')
        as Map<String, dynamic>;
    return json['value'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> getCommit(String repoId, String commitId) async =>
      await _get(
              '$orgUrl/_apis/git/repositories/$repoId/commits/$commitId?changeCount=100')
          as Map<String, dynamic>;

  Future<List<dynamic>> getCommitChanges(
      String repoId, String commitId) async {
    final json = await _get(
            '$orgUrl/_apis/git/repositories/$repoId/commits/$commitId/changes')
        as Map<String, dynamic>;
    return json['changes'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> getItems(String repoId, String path,
      {String? branch}) async {
    final versionQ = (branch != null && branch.isNotEmpty)
        ? '&versionDescriptor.version=${Uri.encodeQueryComponent(branch)}&versionDescriptor.versionType=branch'
        : '';
    final json = await _get(
            '$orgUrl/_apis/git/repositories/$repoId/items?scopePath=${Uri.encodeQueryComponent(path.isEmpty ? '/' : path)}&recursionLevel=OneLevel$versionQ')
        as Map<String, dynamic>;
    return json['value'] as List<dynamic>? ?? const [];
  }

  /// Raw file content as text.
  Future<String> getFileContent(String repoId, String path,
      {String? branch}) async {
    final versionQ = (branch != null && branch.isNotEmpty)
        ? '&versionDescriptor.version=${Uri.encodeQueryComponent(branch)}&versionDescriptor.versionType=branch'
        : '';
    final url =
        '$orgUrl/_apis/git/repositories/$repoId/items?path=${Uri.encodeQueryComponent(path)}&includeContent=true$versionQ&\$format=json&api-version=$_apiVersion';
    final r = await client.get(Uri.parse(url), headers: _headers);
    _check(r);
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    return json['content'] as String? ?? '';
  }

  // ─── Pull requests ────────────────────────────────────────────────────────────
  /// [status] is one of: active, completed, abandoned, all.
  Future<List<dynamic>> getPullRequests(String repoId,
      {String status = 'active', int top = 30}) async {
    final json = await _get(
            '$orgUrl/_apis/git/repositories/$repoId/pullrequests?searchCriteria.status=$status&\$top=$top')
        as Map<String, dynamic>;
    return json['value'] as List<dynamic>? ?? const [];
  }

  // ─── Work items (via WIQL) ────────────────────────────────────────────────────
  Future<List<dynamic>> queryWorkItems(String project, String wiql) async {
    final json = await _post(
        '$orgUrl/${Uri.encodeComponent(project)}/_apis/wit/wiql',
        {'query': wiql}) as Map<String, dynamic>;
    return json['workItems'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> getWorkItems(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final json = await _get(
            '$orgUrl/_apis/wit/workitems?ids=${ids.join(',')}&\$expand=fields')
        as Map<String, dynamic>;
    return json['value'] as List<dynamic>? ?? const [];
  }
}
