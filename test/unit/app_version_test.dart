import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/constants/app_version.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final pubspecVersion = line.split(':')[1].trim().split('+').first;
    expect(appVersion, pubspecVersion);
  });

  test('latest released CHANGELOG section matches appVersion', () {
    final changelog = File('CHANGELOG.md').readAsStringSync();
    final first = RegExp(r'^## \[(\d+\.\d+\.\d+)\]', multiLine: true)
        .firstMatch(changelog)!
        .group(1);
    expect(first, appVersion);
  });
}
