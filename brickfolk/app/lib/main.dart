import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app_state.dart';
import 'src/config.dart';
import 'src/env/frame_throttle.dart';
import 'src/env/launch_env.dart';
import 'src/net/client.dart';
import 'src/screens/home_shell.dart';
import 'src/screens/room_screen.dart';
import 'src/screens/sign_in_screen.dart';
import 'src/test_driver.dart';
import 'src/theme/theme.dart';
import 'src/theme/tokens.dart';
import 'src/widgets/common.dart';
import 'src/widgets/phase_marker.dart';

Future<void> main() async {
  final overrides = launchOverrides();
  final frameInterval = AppConfig.frameInterval(overrides);
  if (frameInterval > 0) {
    ThrottledFrameBinding(Duration(milliseconds: frameInterval));
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  final config = AppConfig.load(overrides);
  final state = await AppState.create(config);
  runApp(BrickfolkApp(state: state));
}

class BrickfolkApp extends StatefulWidget {
  const BrickfolkApp({super.key, required this.state});

  final AppState state;

  @override
  State<BrickfolkApp> createState() => _BrickfolkAppState();
}

class _BrickfolkAppState extends State<BrickfolkApp> {
  TestDriver? _driver;

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    if (s.config.testMode) {
      _driver = TestDriver(s)..start();
    } else if (s.savedToken != null) {
      s.client.signIn(savedToken: s.savedToken);
    }
  }

  @override
  void dispose() {
    _driver?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: ClientScope(
        client: widget.state.client,
        child: AnimatedBuilder(
          animation: widget.state,
          builder: (context, _) {
            final marker = widget.state.config.phaseMarker;
            return MaterialApp(
              title: 'Brickfolk',
              debugShowCheckedModeBanner: false,
              theme: brickTheme(Brightness.light),
              darkTheme: brickTheme(Brightness.dark),
              themeMode: widget.state.themeMode,
              builder: (context, child) {
                final page = _ConnectionOverlay(child: child!);
                return marker ? PhaseMarker(child: page) : page;
              },
              home: const _Root(),
            );
          },
        ),
      ),
    );
  }
}

/// Chooses between sign-in, hub and room based on client state. Entering a
/// room also dismisses whatever the hub had pushed on top (place details,
/// sheets, dialogs) so the room is what the player sees.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  String? _roomCode;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final Widget page;
    if (client.me == null) {
      page = const SignInScreen(key: ValueKey('signin'));
    } else if (client.room != null) {
      page = RoomScreen(key: ValueKey('room-${client.room!.code}'));
    } else {
      page = const HomeShell(key: ValueKey('home'));
    }
    final code = client.me == null ? null : client.room?.code;
    if (code != _roomCode) {
      _roomCode = code;
      if (code != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    }
    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.985, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: page,
    );
  }
}

/// Shows a reconnect banner above everything while the socket is down.
class _ConnectionOverlay extends StatelessWidget {
  const _ConnectionOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final show =
        client.me != null &&
        (client.status == ConnectionStatus.reconnecting ||
            client.status == ConnectionStatus.disconnected);
    return Column(
      children: [
        AnimatedSize(
          duration: Motion.normal,
          curve: Motion.standard,
          child: show
              ? StatusBanner(
                  icon: Icons.wifi_off_rounded,
                  color: BrickColors.brickDark,
                  text: 'Connection lost — reconnecting…',
                  trailing: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(child: child),
      ],
    );
  }
}
