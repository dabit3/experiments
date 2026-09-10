import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Experience browser: thumbnails, live player counts, join by code.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) return;
    AppScope.read(context).client.roomJoin(code);
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final party = client.party;
    final listings = client.places.isEmpty
        ? [for (final pl in places) PlaceListing(pl, 0, const [])]
        : client.places;

    return RefreshIndicator(
      onRefresh: () async => client.refreshPlaces(),
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.lg,
            Space.xxl,
          ),
          children: [
            if (party != null && party.members.length > 1) ...[
              Entrance(child: _PartyBanner(party)),
              const SizedBox(height: Space.lg),
            ],
            SectionHeader(
              'Experiences',
              subtitle: 'Pick a place. Up to eight players per room — bots fill the empty seats.',
              action: SizedBox(
                width: 200,
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _join(),
                  decoration: InputDecoration(
                    hintText: 'Join code',
                    isDense: true,
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                    suffixIcon: IconButton(
                      tooltip: 'Join room',
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      onPressed: _join,
                    ),
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 900
                    ? 3
                    : (c.maxWidth >= 560 ? 2 : 1);
                const gap = Space.lg;
                // Cards in a row share the tallest card's height so their
                // Play buttons line up whatever their description length.
                return Column(
                  children: [
                    for (var r = 0; r < listings.length; r += cols) ...[
                      if (r > 0) const SizedBox(height: gap),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = r; i < r + cols; i++) ...[
                              if (i > r) const SizedBox(width: gap),
                              Expanded(
                                child: i < listings.length
                                    ? Entrance(
                                        delay: Duration(milliseconds: 60 * i),
                                        child: PlaceCard(
                                          listings[i],
                                          party: party,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: Space.xl),
            Panel(
              color: p.surface1,
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: p.textTertiary),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      party == null
                          ? 'Tip: create a party from the Friends tab so your whole crew lands in the same room.'
                          : party.leaderId == client.myId
                          ? 'You lead a party of ${party.members.length}. Launching an experience brings everyone along.'
                          : 'You are in ${party.members.firstWhere((m) => m.id == party.leaderId, orElse: () => party.members.first).name}\'s party. Only the leader can launch.',
                      style: context.text.bodySmall?.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyBanner extends StatelessWidget {
  const _PartyBanner(this.party);

  final PartyState party;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Panel(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderColor: BrickColors.sky.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: BrickColors.sky),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'Party of ${party.members.length} · ${party.members.map((m) => m.name).join(', ')}',
              style: context.text.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CodeBadge(party.code, label: 'Party'),
          if (party.roomCode != null) ...[
            const SizedBox(width: Space.sm),
            FilledButton(
              onPressed: () => client.roomJoin(party.roomCode!),
              child: const Text('Rejoin room'),
            ),
          ],
        ],
      ),
    );
  }
}

class PlaceCard extends StatefulWidget {
  const PlaceCard(this.listing, {super.key, this.party});

  final PlaceListing listing;
  final PartyState? party;

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.listing.info;
    final client = ClientScope.of(context);
    final p = context.palette;
    final accent = Color(info.accent);
    final party = widget.party;
    final leader = party == null || party.leaderId == client.myId;
    final canLaunch = client.connected && leader;

    void play() {
      if (party != null && party.members.length > 1) {
        client.partyLaunch(
          info.kind,
          bots: math.max(0, 8 - party.members.length).clamp(0, 3),
        );
      } else {
        client.roomCreate(info.kind, bots: 3);
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.012 : 1,
        duration: Motion.fast,
        child: Panel(
          padding: EdgeInsets.zero,
          elevated: _hover,
          onTap: canLaunch ? play : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Radii.lg),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlaceThumbnail(info.kind),
                      Positioned(
                        left: Space.md,
                        top: Space.md,
                        child: Tag(
                          '${widget.listing.playing} playing',
                          icon: Icons.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          onColor: widget.listing.playing > 0
                              ? BrickColors.mint
                              : Colors.white70,
                        ),
                      ),
                      Positioned(
                        right: Space.md,
                        top: Space.md,
                        child: Tag(
                          '${info.matchSeconds ~/ 60}:${(info.matchSeconds % 60).toString().padLeft(2, '0')}',
                          icon: Icons.timer_outlined,
                          color: Colors.black.withValues(alpha: 0.45),
                          onColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            experienceIcon(info.kind),
                            size: 18,
                            color: accent,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(
                              info.name,
                              style: context.text.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        info.tagline,
                        style: context.text.bodyMedium?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      Text(
                        info.description,
                        style: context.text.bodySmall?.copyWith(
                          color: p.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: Space.lg),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                              ),
                              onPressed: canLaunch ? play : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                party != null && party.members.length > 1
                                    ? 'Launch for party'
                                    : 'Play',
                              ),
                            ),
                          ),
                          if (widget.listing.rooms.isNotEmpty) ...[
                            const SizedBox(width: Space.sm),
                            _RoomsMenu(widget.listing.rooms),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomsMenu extends StatelessWidget {
  const _RoomsMenu(this.rooms);

  final List<RoomSummary> rooms;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    return MenuAnchor(
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.meeting_room_outlined, size: 18),
        label: Text('${rooms.length}'),
      ),
      menuChildren: [
        for (final r in rooms)
          MenuItemButton(
            onPressed: r.phase == 'lobby' && r.players < maxRoomPlayers
                ? () => client.roomJoin(r.code)
                : null,
            leadingIcon: const Icon(Icons.login_rounded, size: 18),
            trailingIcon: Text(r.phase, style: context.text.labelSmall),
            child: Text('${r.code} · ${r.players}/$maxRoomPlayers'),
          ),
      ],
    );
  }
}

/// Procedurally painted thumbnail per experience (no external assets).
class PlaceThumbnail extends StatelessWidget {
  const PlaceThumbnail(this.kind, {super.key});

  final ExperienceKind kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ThumbPainter(kind));
  }
}

class _ThumbPainter extends CustomPainter {
  const _ThumbPainter(this.kind);

  final ExperienceKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (kind) {
      case ExperienceKind.obby:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6FA3FF), Color(0xFF3E7BFA), Color(0xFF2B4FA8)],
            ).createShader(Offset.zero & size),
        );
        // Clouds
        final cloud = Paint()..color = Colors.white.withValues(alpha: 0.35);
        for (final (x, y, r) in [
          (0.15, 0.3, 0.07),
          (0.22, 0.28, 0.09),
          (0.3, 0.32, 0.06),
          (0.7, 0.2, 0.05),
          (0.76, 0.18, 0.07),
          (0.83, 0.22, 0.05),
        ]) {
          canvas.drawCircle(Offset(w * x, h * y), h * r, cloud);
        }
        // Platforms in perspective steps
        final ys = [0.85, 0.72, 0.6, 0.48, 0.38];
        for (var i = 0; i < ys.length; i++) {
          final px = w * (0.05 + i * 0.19);
          final py = h * ys[i];
          final pw = w * 0.16;
          final ph = h * 0.08;
          final color = i == 2
              ? const Color(0xFFE5484D)
              : (i == 4 ? BrickColors.sun : const Color(0xFFF6F7FB));
          _brick(canvas, Rect.fromLTWH(px, py, pw, ph), color);
        }
        // Flag
        canvas.drawRect(
          Rect.fromLTWH(w * 0.87, h * 0.2, w * 0.008, h * 0.18),
          Paint()..color = Colors.white,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.878, h * 0.2)
            ..lineTo(w * 0.94, h * 0.24)
            ..lineTo(w * 0.878, h * 0.28)
            ..close(),
          Paint()..color = BrickColors.mint,
        );
        _figure(
          canvas,
          Offset(w * 0.13, h * 0.85),
          h * 0.16,
          const Color(0xFFF5C04A),
          BrickColors.mint,
        );
      case ExperienceKind.tycoon:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFB07A), Color(0xFFFF8A4C), Color(0xFFB8552A)],
            ).createShader(Offset.zero & size),
        );
        // Isometric plot grid
        final cx = w * 0.5;
        final cy = h * 0.55;
        final tile = w * 0.075;
        for (var r = 0; r < 5; r++) {
          for (var c = 0; c < 5; c++) {
            final x = cx + (c - r) * tile;
            final y = cy + (c + r) * tile * 0.5 - tile * 1.5;
            final path = Path()
              ..moveTo(x, y)
              ..lineTo(x + tile, y + tile * 0.5)
              ..lineTo(x, y + tile)
              ..lineTo(x - tile, y + tile * 0.5)
              ..close();
            canvas.drawPath(
              path,
              Paint()
                ..color = ((r + c) % 2 == 0
                    ? const Color(0xFF7AD08F)
                    : const Color(0xFF63BD78)),
            );
            if ((r * 3 + c * 5) % 7 < 3) {
              final height = tile * (0.6 + ((r + c) % 3) * 0.35);
              final color = [
                const Color(0xFF3E7BFA),
                const Color(0xFFF5C04A),
                const Color(0xFF8E5CF7),
                const Color(0xFFE5484D),
              ][(r + c) % 4];
              _isoBox(canvas, Offset(x, y), tile, height, color);
            }
          }
        }
        // Coins
        for (final (x, y) in [(0.15, 0.25), (0.82, 0.3), (0.2, 0.7)]) {
          canvas.drawCircle(
            Offset(w * x, h * y),
            h * 0.05,
            Paint()..color = const Color(0xFFCB9A1C),
          );
          canvas.drawCircle(
            Offset(w * x, h * (y - 0.008)),
            h * 0.045,
            Paint()..color = BrickColors.sun,
          );
        }
      case ExperienceKind.tag:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7FE0F2), Color(0xFF35B8D6), Color(0xFF1F6E86)],
            ).createShader(Offset.zero & size),
        );
        // Arena floor tiles
        final floor = Paint()..color = Colors.white.withValues(alpha: 0.08);
        for (var i = 0; i < 12; i++) {
          canvas.drawRect(Rect.fromLTWH(w * (i / 12), 0, w / 24, h), floor);
        }
        for (var i = 0; i < 6; i++) {
          canvas.drawRect(Rect.fromLTWH(0, h * (i / 6), w, h / 12), floor);
        }
        // Walls
        for (final r in [
          Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.15, h * 0.08),
          Rect.fromLTWH(w * 0.65, h * 0.7, w * 0.15, h * 0.08),
          Rect.fromLTWH(w * 0.47, h * 0.4, w * 0.06, h * 0.25),
        ]) {
          _brick(canvas, r, const Color(0xFFDCEAF5));
        }
        // Snowflakes
        final flake = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (final (x, y) in [
          (0.1, 0.8),
          (0.85, 0.2),
          (0.6, 0.15),
          (0.3, 0.55),
        ]) {
          final c = Offset(w * x, h * y);
          for (var a = 0; a < 3; a++) {
            final ang = a * math.pi / 3;
            canvas.drawLine(
              c - Offset(math.cos(ang), math.sin(ang)) * h * 0.05,
              c + Offset(math.cos(ang), math.sin(ang)) * h * 0.05,
              flake,
            );
          }
        }
        _figure(
          canvas,
          Offset(w * 0.3, h * 0.78),
          h * 0.16,
          const Color(0xFFF06BB7),
          const Color(0xFF3E7BFA),
        );
        _figure(
          canvas,
          Offset(w * 0.72, h * 0.5),
          h * 0.16,
          const Color(0xFFBFEFFF),
          const Color(0xFFBFEFFF),
        );
        _figure(
          canvas,
          Offset(w * 0.55, h * 0.85),
          h * 0.16,
          const Color(0xFFF5C04A),
          const Color(0xFFE5484D),
        );
    }
    // Subtle vignette for legibility of overlaid tags.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.12),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _brick(Canvas canvas, Rect r, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.25)),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          r.left,
          r.bottom - r.height * 0.3,
          r.width,
          r.height * 0.3,
        ),
        Radius.circular(r.height * 0.25),
      ),
      Paint()..color = Color.lerp(color, Colors.black, 0.25)!,
    );
    final studs = (r.width / (r.height * 0.9)).floor().clamp(1, 8);
    for (var i = 0; i < studs; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left + r.width * (i + 0.25) / studs,
            r.top - r.height * 0.22,
            r.width * 0.5 / studs,
            r.height * 0.25,
          ),
          Radius.circular(r.height * 0.08),
        ),
        Paint()..color = Color.lerp(color, Colors.white, 0.2)!,
      );
    }
  }

  void _isoBox(
    Canvas canvas,
    Offset top,
    double tile,
    double height,
    Color color,
  ) {
    final left = Path()
      ..moveTo(top.dx - tile, top.dy + tile * 0.5)
      ..lineTo(top.dx, top.dy + tile)
      ..lineTo(top.dx, top.dy + tile - height)
      ..lineTo(top.dx - tile, top.dy + tile * 0.5 - height)
      ..close();
    final right = Path()
      ..moveTo(top.dx + tile, top.dy + tile * 0.5)
      ..lineTo(top.dx, top.dy + tile)
      ..lineTo(top.dx, top.dy + tile - height)
      ..lineTo(top.dx + tile, top.dy + tile * 0.5 - height)
      ..close();
    final topFace = Path()
      ..moveTo(top.dx, top.dy - height)
      ..lineTo(top.dx + tile, top.dy + tile * 0.5 - height)
      ..lineTo(top.dx, top.dy + tile - height)
      ..lineTo(top.dx - tile, top.dy + tile * 0.5 - height)
      ..close();
    canvas.drawPath(
      left,
      Paint()..color = Color.lerp(color, Colors.black, 0.3)!,
    );
    canvas.drawPath(
      right,
      Paint()..color = Color.lerp(color, Colors.black, 0.15)!,
    );
    canvas.drawPath(
      topFace,
      Paint()..color = Color.lerp(color, Colors.white, 0.15)!,
    );
  }

  void _figure(
    Canvas canvas,
    Offset feet,
    double height,
    Color head,
    Color torso,
  ) {
    final u = height / 10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(feet.dx - u * 2, feet.dy - u * 3, u * 4, u * 3),
        Radius.circular(u * 0.3),
      ),
      Paint()..color = const Color(0xFF3A3F4B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(feet.dx - u * 2, feet.dy - u * 7, u * 4, u * 4),
        Radius.circular(u * 0.3),
      ),
      Paint()..color = torso,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(feet.dx - u * 1.5, feet.dy - u * 10, u * 3, u * 3),
        Radius.circular(u * 0.5),
      ),
      Paint()..color = head,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.kind != kind;
}
