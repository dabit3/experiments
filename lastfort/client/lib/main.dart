import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/config.dart';
import 'app/profile.dart';
import 'app/scope.dart';
import 'app/theme.dart';
import 'app/widgets.dart';
import 'net/session.dart';
import 'screens/hub_screen.dart';
import 'screens/match_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.instance;
  final profile = await Profile.load(forcedName: config.playerName);
  if (config.themeMode != 'system') {
    await profile.setThemeMode(config.themeMode);
  }
  final session = Session(profile: profile, config: config);
  runApp(LastfortApp(config: config, profile: profile, session: session));
  await session.start();
}

class LastfortApp extends StatelessWidget {
  const LastfortApp({
    super.key,
    required this.config,
    required this.profile,
    required this.session,
  });

  final AppConfig config;
  final Profile profile;
  final Session session;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      config: config,
      profile: profile,
      session: session,
      child: ListenableBuilder(
        listenable: profile,
        builder: (context, _) {
          final mode = switch (profile.themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          return MaterialApp(
            title: 'Lastfort',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: mode,
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              SystemChrome.setSystemUIOverlayStyle(
                dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              );
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context).textScaler
                      .clamp(maxScaleFactor: 1.3),
                ),
                child: child!,
              );
            },
            home: const RootShell(),
          );
        },
      ),
    );
  }
}

/// Switches between the hub (lobby/locker/pass/settings) and a live match.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final inMatch =
            session.match != null && session.phase == SessionPhase.match;
        return AnimatedSwitcher(
          duration: LfTokens.slow,
          switchInCurve: LfTokens.ease,
          switchOutCurve: LfTokens.ease,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 1.03, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: inMatch
              ? MatchScreen(
                  key: ValueKey(
                    'match-${session.match!.code}-${session.match.hashCode}',
                  ),
                  match: session.match!,
                )
              : const HubScreen(key: ValueKey('hub')),
        );
      },
    );
  }
}

/// Full-screen state used while the profile loads or the server is unreachable.
class SplashState extends StatelessWidget {
  const SplashState({super.key, required this.title, this.detail, this.action});
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const StormBackdrop(intensity: 0.6),
        Center(
          child: LfPanel(
            strong: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LastfortWordmark(size: 36),
                const SizedBox(height: LfTokens.s4),
                Text(title, style: context.text.titleLarge),
                if (detail != null) ...[
                  const SizedBox(height: LfTokens.s2),
                  Text(
                    detail!,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.lf.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: LfTokens.s4),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
