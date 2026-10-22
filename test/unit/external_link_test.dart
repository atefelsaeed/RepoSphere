import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/utils/external_link.dart';
import 'package:repo_sphere/features/auth/presentation/widgets/account_connect_form.dart';

void main() {
  group('safeExternalUri', () {
    test('allows web links and mailto', () {
      expect(safeExternalUri('https://example.com/a?b=1')?.host, 'example.com');
      expect(safeExternalUri(' http://example.com ')?.scheme, 'http');
      expect(safeExternalUri('mailto:a@b.co')?.scheme, 'mailto');
    });

    test('rejects other schemes and junk', () {
      for (final bad in [
        'tel:+123',
        'intent://scan/#Intent;scheme=zxing;end',
        'file:///etc/passwd',
        'javascript:alert(1)',
        'myapp://do/thing',
        'https://',
        'http://[bad',
        '',
        '/relative/path',
      ]) {
        expect(safeExternalUri(bad), isNull, reason: bad);
      }
      expect(safeExternalUri(null), isNull);
    });
  });

  group('isInsecureInstanceUrl', () {
    test('https is fine', () {
      expect(isInsecureInstanceUrl('https://git.example.org'), isFalse);
    });

    test('http to a public host is insecure', () {
      expect(isInsecureInstanceUrl('http://git.example.org'), isTrue);
      expect(isInsecureInstanceUrl('http://8.8.8.8:3000'), isTrue);
      expect(isInsecureInstanceUrl('http://172.32.0.1'), isTrue);
    });

    test('http on this machine or a private network is allowed', () {
      for (final ok in [
        'http://localhost:3000',
        'http://127.0.0.1',
        'http://10.0.0.5:8080',
        'http://192.168.1.20',
        'http://172.16.4.1',
        'http://gitea.local',
      ]) {
        expect(isInsecureInstanceUrl(ok), isFalse, reason: ok);
      }
    });
  });
}
