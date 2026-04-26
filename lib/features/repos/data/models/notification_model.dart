import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  final String title;
  final String subjectType;
  final String subjectApiUrl;
  final String repoFullName;
  final String reason;
  final bool unread;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.subjectType,
    required this.subjectApiUrl,
    required this.repoFullName,
    required this.reason,
    required this.unread,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>? ?? {};
    final repo = json['repository'] as Map<String, dynamic>? ?? {};
    final apiUrl = subject['url'] as String? ?? '';
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: subject['title'] as String? ?? '',
      subjectType: subject['type'] as String? ?? '',
      subjectApiUrl: apiUrl,
      repoFullName: repo['full_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      unread: json['unread'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        title: title,
        subjectType: subjectType,
        repoFullName: repoFullName,
        reason: reason,
        unread: unread,
        updatedAt: updatedAt,
        htmlUrl: _toHtmlUrl(subjectApiUrl, subjectType),
      );

  static String _toHtmlUrl(String apiUrl, String type) {
    if (apiUrl.isEmpty) return '';
    var url = apiUrl
        .replaceFirst('https://api.github.com/repos/', 'https://github.com/')
        .replaceFirst('/pulls/', '/pull/');
    if (type == 'Release') {
      url = url.replaceFirst('/releases/', '/releases/tag/');
    }
    return url;
  }
}
