import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/utils/exceptions.dart';
import '../features/repos/domain/entities/inbox_item_entity.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Registers the extra languages `timeago` needs. Call once at startup.
void registerTimeagoLocales() {
  timeago.setLocaleMessages('ar', timeago.ArMessages());
}

/// "3 hours ago" in the current app language.
String ago(BuildContext context, DateTime time) =>
    timeago.format(time, locale: Localizations.localeOf(context).languageCode);

extension InboxReasonL10n on InboxReason {
  String localized(AppLocalizations l) => switch (this) {
        InboxReason.ciFailed => l.reasonCiFailed,
        InboxReason.changesRequested => l.reasonChangesRequested,
        InboxReason.conflicts => l.reasonConflicts,
        InboxReason.reviewRequested => l.reasonReviewRequested,
        InboxReason.assigned => l.reasonAssigned,
        InboxReason.mentioned => l.reasonMentioned,
      };
}

/// Translates the app's known error messages (which the data layer raises in
/// English). Unknown messages are returned as they are, and unknown exception
/// types fall back to a generic network error.
String localizedError(AppLocalizations l, Object e) {
  final String raw;
  if (e is GitHubAuthException) {
    raw = e.message;
  } else if (e is GitHubRateLimitException) {
    raw = e.message;
  } else if (e is GitHubApiException) {
    raw = e.message;
  } else {
    return l.errNetwork;
  }
  return translateErrorMessage(l, raw);
}

/// Maps a known English error [message] to the current language.
String translateErrorMessage(AppLocalizations l, String message) {
  if (RegExp(r'^Invalid or expired .*token').hasMatch(message)) {
    return l.errInvalidToken;
  }
  if (message.startsWith('Access forbidden')) return l.errForbidden;
  if (message.startsWith('Resource not found')) return l.errNotFound;
  if (message.startsWith('Too many requests')) return l.errTooMany;
  if (message.startsWith('Invalid request')) return l.errInvalidRequest;
  if (message.contains('having issues')) return l.errServer;
  if (message.startsWith('A comment is required')) return l.errCommentRequired;
  final unexpected = RegExp(r'^Unexpected error \((\d+)\)').firstMatch(message);
  if (unexpected != null) return l.errUnexpected(unexpected.group(1)!);
  final wait = RegExp(r'rate limiting requests\. Try again in (\d+)s').firstMatch(message);
  if (wait != null) return l.errRateLimitedIn(wait.group(1)!);
  if (message.contains('rate limiting requests')) return l.errRateLimited;
  return message;
}
