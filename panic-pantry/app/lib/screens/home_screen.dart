import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/arcade.dart';
import '../widgets/ui.dart';
import 'how_to_play.dart';

/// Title screen: name, server, host or join.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client, required this.onToggleTheme});
  final GameClient client;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _name = TextEditingController(text: AppConfig.name);
  late final TextEditingController _server = TextEditingController(text: AppConfig.serverUrl);
  final TextEditingController _code = TextEditingController(text: AppConfig.roomCode ?? '');
  bool _showServer = false;
  String? _pendingJoin;
  bool _pendingCreate = false;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onClient);
  }

  @override
  void dispose() {
    widget.client.removeListener(_onClient);
    _name.dispose();
    _server.dispose();
    _code.dispose();
    super.dispose();
  }

  void _onClient() {
    final c = widget.client;
    if (c.conn == ConnState.connected && c.playerId != null) {
      if (_pendingCreate) {
        _pendingCreate = false;
        c.createRoom(level: AppConfig.levelId);
      } else if (_pendingJoin != null) {
        final code = _pendingJoin!;
        _pendingJoin = null;
        c.joinRoom(code);
      }
    }
    if (c.conn == ConnState.failed) {
      _pendingCreate = false;
      _pendingJoin = null;
    }
  }

  Future<void> _go({String? join}) async {
    final c = widget.client;
    final name = _name.text.trim().isEmpty ? 'Chef' : _name.text.trim();
    if (join != null) {
      _pendingJoin = join;
    } else {
      _pendingCreate = true;
    }
    if (c.conn == ConnState.connected) {
      _onClient();
      return;
    }
    await c.connect(_server.text.trim(), withName: name);
  }

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final c = widget.client;
    final busy =
        c.conn == ConnState.connecting || (c.conn == ConnState.connected && (_pendingCreate || _pendingJoin != null));
    final wide = MediaQuery.sizeOf(context).width > 760;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Enter(
          child: ArcadeHeading(
            eyebrow: 'Aprons on. Game on.',
            title: 'Clock in, chef.',
            subtitle: 'Rally your crew. The dinner rush is yours.',
          ),
        ),
        const SizedBox(height: PPSpace.x6),
        Enter(index: 1, child: SectionLabel('Your chef name')),
        Enter(
          index: 1,
          child: TextField(
            controller: _name,
            maxLength: 12,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Chef',
              counterText: '',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            style: PPType.h3(s.text),
          ),
        ),
        const SizedBox(height: PPSpace.x5),
        Enter(
          index: 2,
          child: PPButton(
            label: busy && _pendingCreate ? 'Opening kitchen…' : 'Host a kitchen',
            icon: Icons.add_home_rounded,
            expand: true,
            onPressed: busy ? null : () => _go(),
          ),
        ),
        const SizedBox(height: PPSpace.x6),
        Enter(index: 3, child: SectionLabel('Join with a code')),
        Enter(
          index: 3,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')), UpperCaseTextFormatter()],
                  onSubmitted: (_) => _code.text.length == 4 ? _go(join: _code.text) : null,
                  decoration: const InputDecoration(
                    hintText: 'ABCD',
                    counterText: '',
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                  ),
                  style: PPType.mono(s.text).copyWith(fontSize: 20, letterSpacing: 6),
                ),
              ),
              const SizedBox(width: PPSpace.x2),
              ValueListenableBuilder(
                valueListenable: _code,
                builder: (context, v, _) => PPButton(
                  label: 'Join',
                  kind: PPButtonKind.secondary,
                  onPressed: busy || v.text.length != 4 ? null : () => _go(join: v.text),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PPSpace.x5),
        Enter(
          index: 4,
          child: Row(
            children: [
              PPButton(
                label: 'How to play',
                icon: Icons.menu_book_rounded,
                kind: PPButtonKind.ghost,
                compact: true,
                onPressed: () => showHowToPlay(context),
              ),
              const Spacer(),
              PPButton(
                label: _showServer ? 'Hide server' : 'Server',
                icon: Icons.dns_rounded,
                kind: PPButtonKind.ghost,
                compact: true,
                onPressed: () => setState(() => _showServer = !_showServer),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: PPMotion.base,
          curve: PPMotion.emphasized,
          child: _showServer
              ? Padding(
                  padding: const EdgeInsets.only(top: PPSpace.x2),
                  child: TextField(
                    controller: _server,
                    decoration: const InputDecoration(
                      hintText: 'ws://host:8787/ws',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    style: PPType.mono(s.text).copyWith(fontSize: 13),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (c.conn == ConnState.failed && c.lastError != null) ...[
          const SizedBox(height: PPSpace.x4),
          Enter(
            child: Container(
              padding: const EdgeInsets.all(PPSpace.x3),
              decoration: BoxDecoration(color: PPColor.paprika.withValues(alpha: 0.1), borderRadius: PPRadius.button),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: PPColor.paprikaDark, size: 20),
                  const SizedBox(width: PPSpace.x2),
                  Expanded(child: Text(c.lastError!, style: PPType.small(PPColor.paprikaDark))),
                  TextButton(onPressed: () => setState(() => _showServer = true), child: const Text('Change server')),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    final hero = Enter(
      child: Container(
        height: wide ? 594 : 400,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: PPColor.ink,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: PPColor.ink, width: 2),
          boxShadow: PPElevation.high(s.brightness),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/arcade-kitchen.png', fit: BoxFit.cover, excludeFromSemantics: true),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.4, 0.7, 1],
                    colors: [Color(0xDD102F35), Color(0x00102F35), Color(0x00102F35), Color(0xFF102F35)],
                  ),
                ),
              ),
            ),
            Positioned(top: 26, left: 26, child: Wordmark(size: wide ? 68 : 50)),
            Positioned(
              left: 26,
              right: 22,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GOOD FOOD. GREAT CHAOS.', style: PPType.h2(PPColor.cream).copyWith(fontSize: wide ? 23 : 19)),
                  const SizedBox(height: 6),
                  Text('2–4 chefs  /  5 kitchens  /  One wild dinner rush', style: PPType.small(PPColor.cream)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.devices_rounded, size: 16, color: PPColor.butter),
                      SizedBox(width: 8),
                      Text(
                        'WEB  ·  iOS  ·  ANDROID  ·  macOS',
                        style: TextStyle(
                          fontFamily: PPType.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PPColor.butter,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          const ArcadeBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 48),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1180 : 480),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: hero),
                            const SizedBox(width: PPSpace.x8),
                            SizedBox(
                              width: 360,
                              child: PPCard(padding: const EdgeInsets.all(22), child: form),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            hero,
                            const SizedBox(height: PPSpace.x8),
                            PPCard(child: form),
                          ],
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + PPSpace.x2,
            right: PPSpace.x3,
            child: IconButton(
              tooltip: 'Toggle theme',
              onPressed: widget.onToggleTheme,
              icon: Icon(s.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: s.text2),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
}
