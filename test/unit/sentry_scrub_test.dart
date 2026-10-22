import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/utils/sentry_scrub.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('URLs in exception text and messages are removed', () {
    final event = SentryEvent(
      message: SentryMessage('failed https://api.github.com/repos/me/secret-repo'),
      exceptions: [
        SentryException(
          type: 'ClientException',
          value: 'Connection closed, uri=https://git.example.com/api/v4/projects/acme%2Fprivate',
        ),
      ],
    );

    final out = scrubSentryEvent(event, Hint())!;

    expect(out.message!.formatted, 'failed [url]');
    expect(out.exceptions!.single.value, 'Connection closed, uri=[url]');
    expect(out.exceptions!.single.type, 'ClientException');
  });

  test('events without text pass through', () {
    final out = scrubSentryEvent(SentryEvent(), Hint())!;
    expect(out.message, isNull);
    expect(out.exceptions, isNull);
  });
}
