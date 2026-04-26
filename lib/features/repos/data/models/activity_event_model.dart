import '../../domain/entities/activity_event_entity.dart';

class ActivityEventModel {
  final String id;
  final String type;
  final String actorLogin;
  final String? actorAvatarUrl;
  final String repoName;
  final DateTime createdAt;
  final String summary;

  const ActivityEventModel({
    required this.id,
    required this.type,
    required this.actorLogin,
    this.actorAvatarUrl,
    required this.repoName,
    required this.createdAt,
    required this.summary,
  });

  factory ActivityEventModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'Event';
    final actor = json['actor'] as Map<String, dynamic>? ?? {};
    final repo = json['repo'] as Map<String, dynamic>? ?? {};
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    return ActivityEventModel(
      id: json['id'] as String? ?? '',
      type: type,
      actorLogin: actor['login'] as String? ?? '',
      actorAvatarUrl: actor['avatar_url'] as String?,
      repoName: repo['name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      summary: _buildSummary(type, payload),
    );
  }

  static String _buildSummary(
      String type, Map<String, dynamic> payload) {
    return switch (type) {
      'PushEvent' => 'Pushed ${(payload['commits'] as List?)?.length ?? 0} commit(s) to ${(payload['ref'] as String?)?.replaceAll('refs/heads/', '') ?? 'branch'}',
      'PullRequestEvent' => '${_cap(payload['action']?.toString() ?? '')} pull request #${(payload['pull_request'] as Map?)?['number'] ?? ''}',
      'IssuesEvent' => '${_cap(payload['action']?.toString() ?? '')} issue #${(payload['issue'] as Map?)?['number'] ?? ''}',
      'CreateEvent' => 'Created ${payload['ref_type']} ${payload['ref'] ?? ''}',
      'DeleteEvent' => 'Deleted ${payload['ref_type']} ${payload['ref'] ?? ''}',
      'ForkEvent' => 'Forked repository',
      'WatchEvent' => 'Starred repository',
      'ReleaseEvent' => 'Published release ${(payload['release'] as Map?)?['tag_name'] ?? ''}',
      'IssueCommentEvent' => 'Commented on issue #${(payload['issue'] as Map?)?['number'] ?? ''}',
      'PullRequestReviewEvent' => 'Reviewed pull request #${(payload['pull_request'] as Map?)?['number'] ?? ''}',
      'PullRequestReviewCommentEvent' => 'Commented on PR #${(payload['pull_request'] as Map?)?['number'] ?? ''}',
      'CommitCommentEvent' => 'Commented on a commit',
      'GollumEvent' => 'Updated wiki',
      'MemberEvent' => '${_cap(payload['action']?.toString() ?? '')} member to repository',
      'PublicEvent' => 'Made repository public',
      _ => type
          .replaceAll('Event', '')
          .replaceAllMapped(
            RegExp(r'([A-Z])'),
            (m) => ' ${m.group(1)}',
          )
          .trim(),
    };
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  ActivityEventEntity toEntity() => ActivityEventEntity(
        id: id,
        type: type,
        actorLogin: actorLogin,
        actorAvatarUrl: actorAvatarUrl,
        repoName: repoName,
        createdAt: createdAt,
        summary: summary,
      );
}
