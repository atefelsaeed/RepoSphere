import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/exceptions.dart';

/// Thin REST client for Gitea / Forgejo / Codeberg (`/api/v1`).
class GiteaRemoteDatasource {
  final http.Client client;
  final String token;
  final String base;

  GiteaRemoteDatasource({
    required this.client,
    required this.token,
    required String baseUrl,
  }) : base = _normalise(baseUrl);

  static String _normalise(String baseUrl) {
    final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api/v1') ? trimmed : '$trimmed/api/v1';
  }

  Map<String, String> get _headers => {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    switch (r.statusCode) {
      case 401:
        throw const GitHubAuthException(
            'Invalid or expired token. Please reconnect.');
      case 403:
        throw const GitHubApiException(
            'Access forbidden. Check your token scopes.');
      case 404:
        throw const GitHubApiException('Resource not found.');
      case 409:
      case 422:
        throw GitHubApiException(_message(r) ?? 'The request was rejected.');
      case 429:
        throw const GitHubRateLimitException(
            'Too many requests. Try again in a moment.');
      default:
        if (r.statusCode >= 500) {
          throw const GitHubApiException(
              'The server is having issues. Try again later.');
        }
        throw GitHubApiException('Unexpected error (${r.statusCode}).');
    }
  }

  static String? _message(http.Response r) {
    try {
      return (jsonDecode(r.body) as Map)['message'] as String?;
    } on Object {
      return null;
    }
  }

  /// JSON call. [path] starts with `/`, e.g. `/user`.
  Future<dynamic> send(String method, String path,
      {Map<String, dynamic>? body}) async {
    final req = http.Request(method, Uri.parse('$base$path'))
      ..headers.addAll(_headers);
    if (body != null) req.body = jsonEncode(body);
    final r = await http.Response.fromStream(await client.send(req));
    _check(r);
    return r.body.isEmpty ? null : jsonDecode(r.body);
  }

  /// Plain-text call (e.g. a PR's `.diff`).
  Future<String> getText(String path) async {
    final r = await client.get(Uri.parse('$base$path'),
        headers: {..._headers, 'Accept': 'text/plain'});
    _check(r);
    return r.body;
  }

  Future<Map<String, dynamic>> getUserJson() async =>
      await send('GET', '/user') as Map<String, dynamic>;

  /// Verifies the token and returns the login.
  Future<String> verifyToken() async =>
      (await getUserJson())['login'] as String;
}
