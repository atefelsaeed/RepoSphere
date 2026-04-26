import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceCodeResponse {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;

  const DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });
}

class GitHubDeviceAuth {
  final String clientId;
  static const _scopes = 'repo read:user notifications gist';

  const GitHubDeviceAuth({required this.clientId});

  Future<DeviceCodeResponse> requestDeviceCode() async {
    final response = await http.post(
      Uri.parse('https://github.com/login/device/code'),
      headers: {'Accept': 'application/json'},
      body: {'client_id': clientId, 'scope': _scopes},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to request device code (${response.statusCode})');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['error'] != null) {
      throw Exception(json['error_description'] ?? json['error']);
    }
    return DeviceCodeResponse(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUri: json['verification_uri'] as String,
      expiresIn: json['expires_in'] as int,
      interval: json['interval'] as int,
    );
  }

  /// Polls until the user authorises or the device code expires.
  /// Yields `null` while waiting, yields the token on success,
  /// throws on hard errors (expired, denied, etc.).
  Stream<String?> pollForToken(
    String deviceCode, {
    required int interval,
  }) async* {
    var delay = interval;
    final deadline = DateTime.now().add(const Duration(minutes: 15));

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(Duration(seconds: delay));

      final response = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': clientId,
          'device_code': deviceCode,
          'grant_type':
              'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['access_token'] != null) {
        yield json['access_token'] as String;
        return;
      }

      final error = json['error'] as String?;
      switch (error) {
        case 'authorization_pending':
          yield null;
        case 'slow_down':
          delay += 5;
          yield null;
        case 'expired_token':
          throw Exception(
              'The device code expired. Please try signing in again.');
        case 'access_denied':
          throw Exception(
              'Access was denied. Please try signing in again.');
        default:
          throw Exception(
              json['error_description'] ?? error ?? 'Unknown error');
      }
    }
    throw Exception('Timed out waiting for GitHub authorisation.');
  }
}
