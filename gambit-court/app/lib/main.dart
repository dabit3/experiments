import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/config.dart';
import 'net/connection.dart';
import 'screens/game_screen.dart';
import 'screens/lobby_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/brand.dart';
import 'widgets/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.load();
  final prefs = await SharedPreferences.getInstance();
  final controller = AppController(config, prefs);
  runApp(GambitCourtApp(controller: controller));
}

class GambitCourtApp extends StatelessWidget {
  const GambitCourtApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final dark = controller.themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
        return MaterialApp(
          title: 'Gambit Court',
          debugShowCheckedModeBanner: false,
          theme: buildGcTheme(Brightness.light),
          darkTheme: buildGcTheme(Brightness.dark),
          themeMode: controller.themeMode,
          themeAnimationDuration: GcMotion.medium,
          themeAnimationCurve: GcMotion.standard,
          home: AppShell(controller: controller),
          builder: controller.config.safeBottom <= 0
              ? null
              : (context, child) {
                  final media = MediaQuery.of(context);
                  return MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(
                        bottom: controller.config.safeBottom,
                      ),
                      viewPadding: media.viewPadding.copyWith(
                        bottom: controller.config.safeBottom,
                      ),
                    ),
                    child: child!,
                  );
                },
        );
      },
    );
  }
}

/// Root: picks the screen, layers toasts, handles the first-connection state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final Widget body = switch (controller.screen) {
      Screen.lobby => LobbyScreen(
        key: const ValueKey('lobby'),
        controller: controller,
      ),
      Screen.game => GameScreen(
        key: const ValueKey('game'),
        controller: controller,
      ),
      Screen.review => GameScreen(
        key: const ValueKey('review'),
        controller: controller,
      ),
    };
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: GcMotion.medium,
                switchInCurve: GcMotion.enter,
                switchOutCurve: GcMotion.exit,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: body,
              ),
            ),
            if (!controller.ready && controller.screen == Screen.lobby)
              Positioned.fill(child: _Splash(controller: controller)),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + GcSpace.lg,
              child: _Toasts(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown until the server's welcome arrives; fades away once online.
class _Splash extends StatelessWidget {
  const _Splash({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return ValueListenableBuilder(
      valueListenable: controller.connection.phase,
      builder: (context, phase, _) {
        final struggling = phase == ConnectionPhase.offline;
        return Container(
          color: c.bg,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GcMark(size: 64),
              const SizedBox(height: GcSpace.lg),
              const GcWordmark(size: 26),
              const SizedBox(height: GcSpace.xl),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: struggling ? c.danger : c.brass,
                  backgroundColor: c.border,
                ),
              ),
              const SizedBox(height: GcSpace.md),
              Text(
                struggling
                    ? 'Cannot reach ${controller.config.serverUrl}'
                    : 'Connecting to the court…',
                style: GcType.body(
                  struggling ? c.danger : c.textMuted,
                  size: 13,
                ),
              ),
              if (struggling) ...[
                const SizedBox(height: GcSpace.md),
                GcButton(
                  label: 'Retry',
                  onPressed: controller.connection.reconnectNow,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Toasts extends StatelessWidget {
  const _Toasts({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return IgnorePointer(
      ignoring: controller.notices.isEmpty,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final notice in controller.notices)
            Padding(
              padding: const EdgeInsets.only(top: GcSpace.sm),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(notice.id),
                tween: Tween(begin: 0, end: 1),
                duration: GcMotion.medium,
                curve: GcMotion.enter,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 12),
                    child: child,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: notice.isError ? c.dangerSoft : c.surfaceRaised,
                    borderRadius: GcRadius.mdAll,
                    elevation: 8,
                    shadowColor: c.shadow,
                    child: InkWell(
                      onTap: () => controller.dismissNotice(notice),
                      borderRadius: GcRadius.mdAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GcSpace.lg,
                          vertical: GcSpace.md,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              notice.isError
                                  ? Icons.error_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: notice.isError ? c.danger : c.brass,
                            ),
                            const SizedBox(width: GcSpace.sm),
                            Flexible(
                              child: Text(
                                notice.text,
                                style: GcType.body(
                                  c.text,
                                  size: 13.5,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
