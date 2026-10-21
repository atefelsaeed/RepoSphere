import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;
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
