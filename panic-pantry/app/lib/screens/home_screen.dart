import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
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

    final hero = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Enter(child: Wordmark(size: wide ? 64 : 44)),
        const SizedBox(height: PPSpace.x4),
        Enter(
          index: 1,
          child: Text(
            'A co-op kitchen for 2–4 chefs.\nChop, cook, plate, serve — before the tickets expire.',
            style: PPType.body(s.text2),
            textAlign: wide ? TextAlign.left : TextAlign.center,
          ),
        ),
        const SizedBox(height: PPSpace.x4),
        Enter(
          index: 2,
          child: Wrap(
            spacing: PPSpace.x2,
            runSpacing: PPSpace.x2,
            alignment: wide ? WrapAlignment.start : WrapAlignment.center,
            children: const [
              PPChip(label: 'Cross-platform co-op', icon: Icons.devices_rounded, color: PPColor.blueberry),
              PPChip(label: '5 kitchens', icon: Icons.map_rounded, color: PPColor.basil),
              PPChip(label: 'Bots fill seats', icon: Icons.smart_toy_rounded, color: PPColor.plum),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(PPSpace.x6),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 980 : 440),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: hero),
                            const SizedBox(width: PPSpace.x12),
                            SizedBox(width: 420, child: PPCard(child: form)),
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
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + PPSpace.x3,
            left: 0,
            right: 0,
            child: Center(child: Text('Panic Pantry · co-op kitchen chaos', style: PPType.caption(s.text3))),
          ),
        ],
      ),
    );
  }
}

/// Soft radial blobs behind the title screen.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [s.bg, s.bg2]),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: _Blob(color: PPColor.butter.withValues(alpha: s.isDark ? 0.10 : 0.35), size: 380),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: _Blob(color: PPColor.paprika.withValues(alpha: s.isDark ? 0.14 : 0.22), size: 460),
          ),
          Positioned(
            top: 160,
            right: 80,
            child: _Blob(color: PPColor.basil.withValues(alpha: s.isDark ? 0.08 : 0.18), size: 220),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
}
