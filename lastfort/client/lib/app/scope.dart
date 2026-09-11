import 'package:flutter/widgets.dart';

import '../net/session.dart';
import 'config.dart';
import 'profile.dart';

/// Exposes the app singletons to the widget tree.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.profile,
    required this.session,
    required super.child,
  });

  final AppConfig config;
  final Profile profile;
  final Session session;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  /// Non-dependent lookup for use in `initState` and callbacks.
  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      old.profile != profile || old.session != session || old.config != config;
}
