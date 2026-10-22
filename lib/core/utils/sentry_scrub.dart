import 'package:sentry_flutter/sentry_flutter.dart';

final _url = RegExp(r'[a-zA-Z][a-zA-Z0-9+.-]*://[^\s"\x27<>]+');

String _scrubText(String text) => text.replaceAll(_url, '[url]');

/// `beforeSend` for crash reports. Exception text can quote request URLs
/// (`ClientException ... uri=https://host/repos/owner/private-repo/...`), which
/// would leak private repo names, so every URL in messages is replaced.
/// Request data and user info are dropped.
SentryEvent? scrubSentryEvent(SentryEvent event, Hint hint) {
  final message = event.message;
  if (message != null) {
    event.message = SentryMessage(
      _scrubText(message.formatted),
      template: message.template == null ? null : _scrubText(message.template!),
    );
  }
  for (final e in event.exceptions ?? const <SentryException>[]) {
    final value = e.value;
    if (value != null) e.value = _scrubText(value);
  }
  event.request = null;
  event.user = null;
  return event;
}
