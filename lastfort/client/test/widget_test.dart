import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lastfort/app/config.dart';
import 'package:lastfort/app/theme.dart';

void main() {
  test('platform name is one of the four supported targets', () {
    expect([
      'web',
      'ios',
      'android',
      'macos',
    ], contains(AppConfig.instance.platformName));
  });

  test('themes build for both brightnesses', () {
    expect(buildTheme(Brightness.dark).brightness, Brightness.dark);
    expect(buildTheme(Brightness.light).brightness, Brightness.light);
  });
}
