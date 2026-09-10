import 'dart:async';
import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _busy = false;
  StreamSubscription<ServerError>? _errSub;
  late final BrickfolkClient _client;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  static const _previewAvatars = [
    Avatar(
      headColor: 0xFFF5C04A,
      torsoColor: 0xFF3E7BFA,
      armColor: 0xFFF5C04A,
      legColor: 0xFF2F9E5B,
      face: 'face_smile',
      hat: 'hat_cap',
      accessory: 'acc_none',
    ),
    Avatar(
      headColor: 0xFFF4E6D2,
      torsoColor: 0xFFE5484D,
      armColor: 0xFFF4E6D2,
      legColor: 0xFF3A3F4B,
      face: 'face_grin',
      hat: 'hat_wizard',
      accessory: 'acc_cape',
    ),
    Avatar(
      headColor: 0xFF8C5A3C,
      torsoColor: 0xFF2F9E5B,
      armColor: 0xFF8C5A3C,
      legColor: 0xFF9AA3AF,
      face: 'face_shades',
      hat: 'hat_helmet',
      accessory: 'acc_backpack',
    ),
    Avatar(
      headColor: 0xFFF06BB7,
      torsoColor: 0xFF8E5CF7,
      armColor: 0xFFF06BB7,
      legColor: 0xFF3E7BFA,
      face: 'face_wink',
      hat: 'hat_crown',
      accessory: 'acc_wings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _client = app.client;
    _name.text = app.savedName ?? '';
    _errSub = app.client.errors.listen((e) {
      if (!mounted) return;
      if (e.inReplyTo == MsgType.hello ||
          e.code == ErrorCode.invalidName ||
          e.code == ErrorCode.nameTaken) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    });
    _client.addListener(_onClient);
  }

  void _onClient() {
    final c = _client;
    if (!mounted) return;
    if (c.status == ConnectionStatus.disconnected && _busy && c.me == null) {
      setState(() {
        _busy = false;
        _error = 'Could not reach the server at ${c.serverUrl}.';
      });
    }
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _client.removeListener(_onClient);
    _float.dispose();
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (!playerNamePattern.hasMatch(name)) {
      setState(
        () => _error =
            '3–16 letters, numbers or underscores, starting with a letter.',
      );
      return;
    }
    _focus.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    _client.signIn(name: name);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final client = ClientScope.of(context);
    final app = AppScope.read(context);
    final resuming =
        client.token != null &&
        client.status != ConnectionStatus.disconnected &&
        !_busy;
    // The test driver signs in by itself; a focused field would be torn down
    // mid-edit when the hub replaces this screen.
    final autofocus = !resuming && !app.config.testMode;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    final form = Panel(
      elevated: true,
      padding: const EdgeInsets.all(Space.xl),
      radius: Radii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pick a name', style: context.text.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(
            'No account needed. Your name and avatar are saved on this device.',
            style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _name,
            focusNode: _focus,
            autofocus: autofocus,
            enabled: !_busy && !resuming,
            maxLength: 16,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'e.g. SkyRunner_42',
              counterText: '',
              prefixIcon: const Icon(Icons.badge_outlined),
              errorText: _error,
            ),
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy || resuming ? null : _submit,
              child: AnimatedSwitcher(
                duration: Motion.fast,
                child: _busy || resuming
                    ? Row(
                        key: const ValueKey('busy'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: Space.md),
                          Text(resuming ? 'Reconnecting…' : 'Joining…'),
                        ],
                      )
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Enter Brickfolk'),
                          SizedBox(width: Space.sm),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
          if (resuming) ...[
            const SizedBox(height: Space.sm),
            Center(
              child: TextButton(
                onPressed: () => AppScope.of(context).signOut(),
                child: const Text('Use a different name'),
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 14, color: p.textTertiary),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  client.serverUrl,
                  style: context.text.bodySmall?.copyWith(
                    color: p.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ThemeToggle(),
            ],
          ),
        ],
      ),
    );

    final hero = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Wordmark(size: 40),
        const SizedBox(height: Space.md),
        Text(
          'Build, run, freeze and\nclimb with your friends.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: (wide
              ? context.text.displayMedium
              : context.text.displaySmall),
        ),
        const SizedBox(height: Space.md),
        Text(
          'Three experiences, one blocky avatar, cross-platform parties on web, iOS, Android and macOS.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: context.text.bodyLarge?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Space.xl),
        SizedBox(
          height: 120,
          child: AnimatedBuilder(
            animation: _float,
            builder: (_, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: wide ? Alignment.centerLeft : Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _previewAvatars.length; i++)
                    Transform.translate(
                      offset: Offset(
                        0,
                        math.sin((_float.value + i * 0.22) * math.pi * 2) * 5,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: Space.lg),
                        child: AvatarView(
                          _previewAvatars[i],
                          size: 96,
                          background: p.surface1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Entrance(child: hero)),
                            const SizedBox(width: Space.xxxl),
                            SizedBox(
                              width: 420,
                              child: Entrance(
                                delay: const Duration(milliseconds: 120),
                                child: form,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Entrance(child: hero),
                            const SizedBox(height: Space.xl),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Entrance(
                                delay: const Duration(milliseconds: 120),
                                child: form,
                              ),
                            ),
                          ],
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

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Light theme' : 'Dark theme',
      onPressed: () => app.setTheme(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 18,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Brickfolk wordmark: three studs and the name.
class _Wordmark extends StatelessWidget {
  const _Wordmark({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrickLogo(size: size),
        SizedBox(width: size * 0.35),
        Text(
          'Brickfolk',
          style: context.text.displaySmall?.copyWith(fontSize: size * 0.9),
        ),
      ],
    );
  }
}

/// The Brickfolk logo: a 2x2 brick with studs (original art).
class BrickLogo extends StatelessWidget {
  const BrickLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _LogoPainter());
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, s * 0.28, s, s * 0.72),
      Radius.circular(s * 0.16),
    );
    canvas.drawRRect(body, Paint()..color = BrickColors.brickDark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, s * 0.28, s, s * 0.58),
        Radius.circular(s * 0.16),
      ),
      Paint()..color = BrickColors.brick,
    );
    for (final x in [s * 0.12, s * 0.56]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, s * 0.08, s * 0.32, s * 0.3),
          Radius.circular(s * 0.08),
        ),
        Paint()..color = const Color(0xFFFF8F73),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, s * 0.08, s * 0.32, s * 0.12),
          Radius.circular(s * 0.06),
        ),
        Paint()..color = const Color(0xFFFFB39F),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft gradient blobs behind the sign-in card.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF151A24), Color(0xFF111420), Color(0xFF1A1622)]
              : const [Color(0xFFEEF3FF), Color(0xFFF6F7FB), Color(0xFFFFF0EA)],
        ),
      ),
      child: CustomPaint(painter: _BlobPainter(dark)),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.dark);

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final a = dark ? 0.18 : 0.28;
    void blob(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }

    blob(
      Offset(size.width * 0.15, size.height * 0.2),
      size.shortestSide * 0.35,
      BrickColors.sky,
    );
    blob(
      Offset(size.width * 0.85, size.height * 0.8),
      size.shortestSide * 0.4,
      BrickColors.brick,
    );
    blob(
      Offset(size.width * 0.7, size.height * 0.15),
      size.shortestSide * 0.22,
      BrickColors.sun,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.dark != dark;
}
