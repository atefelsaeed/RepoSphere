import 'dart:convert';
import '../../../core/git/git_provider_type.dart';

/// A single connected account on a Git provider.
///
/// Multiple connections can coexist (e.g. two GitHub accounts + one GitLab +
/// one Azure DevOps org). Persisted as JSON inside secure storage.
class GitConnection {
  final String id;
  final GitProviderType type;

  /// e.g. "octocat" — the login on the provider.
  final String accountLogin;

  /// Optional avatar for the connection chip.
  final String? avatarUrl;

  /// Base URL for self-hosted instances, or the Azure DevOps organisation URL
  /// (e.g. `https://dev.azure.com/myorg`). Null → provider's public default.
  final String? baseUrl;

  /// Personal access token used to authenticate this connection.
  final String token;

  const GitConnection({
    required this.id,
    required this.type,
    required this.accountLogin,
    required this.token,
    this.avatarUrl,
    this.baseUrl,
  });

  /// "GitHub · octocat" — for connection list rows.
  String get displayName => '${type.label} · $accountLogin';

  GitConnection copyWith({
    String? accountLogin,
    String? avatarUrl,
    String? baseUrl,
    String? token,
  }) =>
      GitConnection(
        id: id,
        type: type,
        accountLogin: accountLogin ?? this.accountLogin,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        baseUrl: baseUrl ?? this.baseUrl,
        token: token ?? this.token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.slug,
        'accountLogin': accountLogin,
        'avatarUrl': avatarUrl,
        'baseUrl': baseUrl,
        'token': token,
      };

  factory GitConnection.fromJson(Map<String, dynamic> json) => GitConnection(
        id: json['id'] as String,
        type: GitProviderType.fromSlug(json['type'] as String),
        accountLogin: json['accountLogin'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        baseUrl: json['baseUrl'] as String?,
        token: json['token'] as String,
      );

  static String encodeList(List<GitConnection> connections) =>
      jsonEncode(connections.map((c) => c.toJson()).toList());

  static List<GitConnection> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GitConnection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is GitConnection && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
