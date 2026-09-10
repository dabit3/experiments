import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../net/game_client.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/piece_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.client,
    required this.initialName,
    required this.initialServer,
    required this.onConnect,
    required this.onToggleTheme,
  });

  final GameClient client;
  final String initialName;
  final String initialServer;
  final Future<void> Function(String name, String server) onConnect;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _server = TextEditingController(text: widget.initialServer);
  final _code = TextEditingController();
  bool _advanced = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _server.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<bool> _ensureConnected() async {
    final client = widget.client;
    if (client.isOnline &&
        client.serverUrl == _server.text.trim() &&
        client.name == _name.text.trim()) {
      return true;
    }
    setState(() => _busy = true);
    await widget.onConnect(_name.text.trim(), _server.text.trim());
    // Wait (bounded) for the welcome.
    for (
      var i = 0;
      i < 60 && !client.isOnline && client.lastError == null;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (mounted) setState(() => _busy = false);
    return client.isOnline;
  }

  Future<void> _create({bool bots = false}) async {
    if (!await _ensureConnected()) return;
    widget.client.createRoom(fillBots: bots);
  }

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-letter room code')),
      );
      return;
    }
    if (!await _ensureConnected()) return;
    widget.client.joinRoom(code);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final client = widget.client;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final err = client.lastError;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _BackdropPainter(c))),
            Positioned(
              top: Space.md,
              right: Space.md,
              child: Row(
                children: [
                  StatusPill(client),
                  const SizedBox(width: Space.sm),
                  IconButton(
                    tooltip: c.isDark ? 'Light theme' : 'Dark theme',
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      c.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.xl,
                  vertical: Space.xxxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 920 : 440),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _hero(context)),
                            const SizedBox(width: Space.xxxl),
                            SizedBox(width: 400, child: _form(context, err)),
                          ],
                        )
                      : Column(
                          children: [
                            _hero(context, center: true),
                            const SizedBox(height: Space.xxl),
                            _form(context, err),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, {bool center = false}) {
    final c = context.colors;
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        const SwapmateMark(size: 72),
        const SizedBox(height: Space.xl),
        Text(
          'Swapmate',
          style: context.type.displayLarge,
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: Space.sm),
        Text(
          'Team-up chess on two boards. Capture a piece, hand it to your partner, drop it where it hurts.',
          style: context.type.bodyLarge?.copyWith(color: c.textMuted),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          alignment: center ? WrapAlignment.center : WrapAlignment.start,
          children: const [
            Chip2('2 v 2', icon: Icons.groups_2_outlined),
            Chip2('Two boards', icon: Icons.grid_on),
            Chip2('Cross-platform', icon: Icons.devices),
            Chip2('Real-time', icon: Icons.bolt_outlined),
          ],
        ),
        const SizedBox(height: Space.xl),
        Row(
          mainAxisAlignment: center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            for (final t in [
              PieceType.king,
              PieceType.queen,
              PieceType.rook,
              PieceType.bishop,
              PieceType.knight,
              PieceType.pawn,
            ])
              Padding(
                padding: const EdgeInsets.only(right: Space.xs),
                child: PieceGlyph(
                  Piece(
                    t.index.isEven ? PieceColor.white : PieceColor.black,
                    t,
                  ),
                  size: 40,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _form(BuildContext context, ClientError? err) {
    final c = context.colors;
    final busy = _busy || widget.client.status == ConnectionStatus.connecting;
    return Panel(
      raised: true,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Play', style: context.type.headlineSmall),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _name,
            maxLength: 24,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Your name',
              counterText: '',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            key: const Key('home-create'),
            onPressed: busy ? null : () => _create(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create a room'),
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            key: const Key('home-bots'),
            onPressed: busy ? null : () => _create(bots: true),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Play with bots'),
          ),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(child: Divider(color: c.outline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                child: Text('or join a friend', style: context.type.labelSmall),
              ),
              Expanded(child: Divider(color: c.outline)),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('home-code'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                    LengthLimitingTextInputFormatter(4),
                    _UpperCaseFormatter(),
                  ],
                  onSubmitted: (_) => _join(),
                  style: context.type.headlineSmall?.copyWith(letterSpacing: 6),
                  decoration: const InputDecoration(hintText: 'CODE'),
                ),
              ),
              const SizedBox(width: Space.sm),
              FilledButton(
                key: const Key('home-join'),
                onPressed: busy ? null : _join,
                style: FilledButton.styleFrom(
                  backgroundColor: c.surfaceRaised,
                  foregroundColor: c.text,
                  minimumSize: const Size(96, 52),
                ),
                child: const Text('Join'),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          InkWell(
            borderRadius: BorderRadius.circular(Radii.sm),
            onTap: () => setState(() => _advanced = !_advanced),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  Icon(
                    _advanced ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: c.textMuted,
                  ),
                  const SizedBox(width: Space.xs),
                  Text(
                    'Server',
                    style: context.type.labelMedium?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (!_advanced)
                    Flexible(
                      child: Text(
                        _server.text,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodySmall?.copyWith(
                          color: c.textFaint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: _advanced
                ? Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: TextField(
                      controller: _server,
                      decoration: const InputDecoration(
                        hintText: 'ws://host:8787/ws',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: Space.lg),
                    child: _ErrorBanner(
                      err,
                      onDismiss: widget.client.clearError,
                    ),
                  ),
          ),
          if (busy) ...[
            const SizedBox(height: Space.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.accent,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text('Connecting to server…', style: context.type.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.error, {required this.onDismiss});
  final ClientError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.xs,
        Space.sm,
      ),
      decoration: BoxDecoration(
        color: c.dangerSoft,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.danger, size: 18),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              error.message,
              style: context.type.bodySmall?.copyWith(color: c.text),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Soft radial glows behind the home screen.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.c);
  final SwapColors c;

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double r, Color color) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: c.isDark ? 0.22 : 0.16),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    glow(
      Offset(size.width * 0.15, size.height * 0.2),
      size.shortestSide * 0.7,
      c.teamOne,
    );
    glow(
      Offset(size.width * 0.85, size.height * 0.85),
      size.shortestSide * 0.7,
      c.teamTwo,
    );
    glow(
      Offset(size.width * 0.6, size.height * 0.1),
      size.shortestSide * 0.4,
      c.accent,
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.c != c;
}
