import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gitlab_project_model.dart';

class GitLabRemoteDatasource {
  final http.Client client;
  final String token;

  static const _base = 'https://gitlab.com/api/v4';

  const GitLabRemoteDatasource({required this.client, required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<List<GitLabProjectModel>> getProjects({int perPage = 100}) async {
    final uri = Uri.parse(
        '$_base/projects?membership=true&per_page=$perPage&order_by=last_activity_at&archived=false');
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('GitLab API error ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((j) => GitLabProjectModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<GitLabProjectModel>> getStarredProjects(
      {int perPage = 100}) async {
    final uri = Uri.parse(
        '$_base/projects?starred=true&per_page=$perPage&order_by=last_activity_at');
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('GitLab API error ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((j) => GitLabProjectModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Verify token by hitting /user — returns the user's username.
  Future<String> verifyToken() async {
    final uri = Uri.parse('$_base/user');
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode == 401) {
      throw Exception('Invalid GitLab token');
    }
    if (response.statusCode != 200) {
      throw Exception('GitLab API error ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['username'] as String;
  }
}
