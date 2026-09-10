import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';

/// Home: greeting, friends rail, experience sorts ("Continue",
/// "Recommended For You", ...), join by code. Tiles open [PlaceDetailsPage].
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key, this.query = '', this.onOpenFriends});

  /// Filters tiles by name / tagline (from the chrome search field).
  final String query;

  /// Opens the Friends tab (from the "Add friends" rail item).
  final VoidCallback? onOpenFriends;

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
    final me = client.me!;
    final party = client.party;
    final phone = context.isPhone;
    final all = client.places.isEmpty
        ? [for (final pl in places) PlaceListing(pl, 0, const [])]
        : client.places;
    final q = widget.query.trim().toLowerCase();
    final listings = q.isEmpty
        ? all
        : [
            for (final l in all)
              if (l.info.name.toLowerCase().contains(q) ||
                  l.info.tagline.toLowerCase().contains(q))
                l,
          ];
    final continueList = [
      for (final l in listings)
        if ((me.stats['matches_${l.info.kind.id}'] ?? 0) > 0) l,
    ];
    final topRated = [
      ...listings,
    ]..sort((a, b) => (b.ratingPercent ?? -1).compareTo(a.ratingPercent ?? -1));
    final mostActive = [...listings]
      ..sort((a, b) {
        final c = b.playing.compareTo(a.playing);
        return c != 0 ? c : b.visits.compareTo(a.visits);
      });
    final pad = phone ? Space.lg : Space.xl;

    final joinField = SizedBox(
      width: phone ? double.infinity : 200,
      height: 36,
      child: TextField(
        controller: _code,
        textCapitalization: TextCapitalization.characters,
        onSubmitted: (_) => _join(),
        style: context.text.labelLarge?.copyWith(letterSpacing: 1),
        decoration: InputDecoration(
          hintText: 'Join code',
          hintStyle: context.text.bodyMedium?.copyWith(color: p.textTertiary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
          prefixIcon: const Icon(Icons.vpn_key_outlined, size: 16),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: IconButton(
            tooltip: 'Join room',
            iconSize: 18,
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _join,
          ),
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async => client.refreshPlaces(),
      child: ContentWidth(
        max: 1180,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, Space.lg, pad, Space.xxl),
          children: [
            Row(
              children: [
                Headshot(me.summary.avatar, size: phone ? 44 : 52),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${me.summary.name}',
                        style: phone
                            ? context.text.titleLarge
                            : context.text.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${client.onlineCount} online now',
                        style: context.text.bodySmall?.copyWith(
                          color: p.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!phone) joinField,
              ],
            ),
            if (phone) ...[const SizedBox(height: Space.md), joinField],
            const SizedBox(height: Space.xl),
            if (party != null && party.members.length > 1) ...[
              Entrance(child: _PartyBanner(party)),
              const SizedBox(height: Space.xl),
            ],
            if (q.isEmpty) ...[
              _SortHeader('Friends (${client.friends.friends.length})'),
              _FriendsRail(client.friends.friends, onAdd: widget.onOpenFriends),
              const SizedBox(height: Space.xl),
            ],
            if (continueList.isNotEmpty) ...[
              const _SortHeader('Continue'),
              _Rail(
                height: phone ? 190 : 210,
                children: [for (final l in continueList) _WideTile(l)],
              ),
              const SizedBox(height: Space.xl),
            ],
            _SortHeader(q.isEmpty ? 'Recommended For You' : 'Results'),
            if (listings.isEmpty)
              EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No experiences match',
                message: 'Try a different search.',
              )
            else
              _Rail(
                height: phone ? 188 : 208,
                children: [for (final l in listings) _SquareTile(l)],
              ),
            if (q.isEmpty && listings.length > 1) ...[
              const SizedBox(height: Space.xl),
              const _SortHeader('Top Rated'),
              _Rail(
                height: phone ? 188 : 208,
                children: [for (final l in topRated) _SquareTile(l)],
              ),
              const SizedBox(height: Space.xl),
              const _SortHeader('Most Active'),
              _Rail(
                height: phone ? 188 : 208,
                children: [for (final l in mostActive) _SquareTile(l)],
              ),
            ],
            const SizedBox(height: Space.xxl),
            Text(
              party == null
                  ? 'Up to eight players per room. Bots fill empty seats. Create a party from Friends so your crew lands in the same room.'
                  : party.leaderId == client.myId
                  ? 'You lead a party of ${party.members.length}. Playing an experience brings everyone along.'
                  : 'You are in ${party.members.firstWhere((m) => m.id == party.leaderId, orElse: () => party.members.first).name}\'s party. Only the leader can launch.',
              style: context.text.bodySmall?.copyWith(color: p.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsRail extends StatelessWidget {
  const _FriendsRail(this.friends, {this.onAdd});

  final List<PlayerSummary> friends;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const size = 64.0;
    Widget bubble({
      required Widget head,
      required String label,
      VoidCallback? onTap,
    }) {
      return SizedBox(
        width: size + Space.lg,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Column(
            children: [
              head,
              const SizedBox(height: Space.xs),
              Text(
                label,
                style: context.text.bodySmall?.copyWith(color: p.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _Rail(
      height: size + 28,
      gap: Space.xs,
      children: [
        bubble(
          head: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: p.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: p.outline),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: p.textSecondary),
          ),
          label: 'Add friends',
          onTap: onAdd,
        ),
        for (final f in friends)
          bubble(
            head: Headshot(f.avatar, size: size, online: f.online),
            label: f.name,
            onTap: onAdd,
          ),
      ],
    );
  }
}

/// Horizontal sort rail.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.height,
    required this.children,
    this.gap = Space.md,
  });

  final double height;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: (_, i) => Entrance(
          delay: Duration(milliseconds: 40 * i),
          child: children[i],
        ),
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleLarge)),
          Icon(
            Icons.chevron_right_rounded,
            color: context.palette.textTertiary,
          ),
        ],
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
    return Panel(
      color: BrickColors.sky.withValues(alpha: 0.12),
      borderColor: BrickColors.sky.withValues(alpha: 0.4),
      radius: Radii.md,
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
              child: const Text('Rejoin'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Starts (or party-launches) a room for [kind].
void playPlace(BuildContext context, ExperienceKind kind) {
  final client = AppScope.read(context).client;
  final party = client.party;
  if (party != null && party.members.length > 1) {
    client.partyLaunch(
      kind,
      bots: math.max(0, 8 - party.members.length).clamp(0, 3),
    );
  } else {
    client.roomCreate(kind, bots: 3);
  }
}

bool _canLaunch(BrickfolkClient client) =>
    client.connected &&
    (client.party == null || client.party!.leaderId == client.myId);

void _openDetails(BuildContext context, PlaceListing listing) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlaceDetailsPage(listing.info.kind),
    ),
  );
}

/// Rating + active player metadata row under a tile.
class _TileMeta extends StatelessWidget {
  const _TileMeta(this.listing);

  final PlaceListing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.text.bodySmall?.copyWith(color: p.textSecondary);
    final rating = listing.ratingPercent;
    return Row(
      children: [
        Icon(Icons.thumb_up_alt_rounded, size: 12, color: p.textTertiary),
        const SizedBox(width: Space.xs),
        Text(rating == null ? '--' : '$rating%', style: style),
        const SizedBox(width: Space.md),
        Icon(Icons.person_rounded, size: 13, color: p.textTertiary),
        const SizedBox(width: Space.xs),
        Text(formatNumber(listing.playing), style: style),
      ],
    );
  }
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.02 : 1,
          duration: Motion.fast,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Square-art tile used in the Recommended grid.
class _SquareTile extends StatelessWidget {
  const _SquareTile(this.listing);

  final PlaceListing listing;

  @override
  Widget build(BuildContext context) {
    final info = listing.info;
    final width = context.isPhone ? 140.0 : 160.0;
    return SizedBox(
      width: width,
      child: _HoverScale(
        onTap: () => _openDetails(context, listing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: SizedBox(
                width: width,
                height: width,
                child: PlaceThumbnail(info.kind),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              info.name,
              style: context.text.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.xxs),
            _TileMeta(listing),
          ],
        ),
      ),
    );
  }
}

/// Wide 16:9 tile used in the Continue rail.
class _WideTile extends StatelessWidget {
  const _WideTile(this.listing);

  final PlaceListing listing;

  @override
  Widget build(BuildContext context) {
    final info = listing.info;
    final p = context.palette;
    final width = context.isPhone ? 232.0 : 264.0;
    return SizedBox(
      width: width,
      child: _HoverScale(
        onTap: () => _openDetails(context, listing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlaceThumbnail(info.kind),
                    if (listing.playing > 0)
                      Positioned(
                        left: Space.sm,
                        bottom: Space.sm,
                        child: Tag(
                          '${listing.playing} playing',
                          icon: Icons.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                          onColor: BrickColors.mint,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              info.name,
              style: context.text.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.xxs),
            Text(
              info.tagline,
              style: context.text.bodySmall?.copyWith(color: p.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Experience details: hero art, Play, votes, about stats, open servers.
class PlaceDetailsPage extends StatelessWidget {
  const PlaceDetailsPage(this.kind, {super.key});

  final ExperienceKind kind;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final listing = client.places.firstWhere(
      (l) => l.info.kind == kind,
      orElse: () => PlaceListing(placeFor(kind), 0, const []),
    );
    final info = listing.info;
    final party = client.party;
    final phone = context.isPhone;
    final pad = phone ? Space.lg : Space.xl;
    final canLaunch = _canLaunch(client);
    final launchLabel = party != null && party.members.length > 1
        ? 'Play with party'
        : 'Play';

    final hero = ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: AspectRatio(aspectRatio: 16 / 9, child: PlaceThumbnail(info.kind)),
    );
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(info.name, style: context.text.headlineMedium),
        const SizedBox(height: Space.xs),
        Text(
          'By Brickfolk Studios',
          style: context.text.bodyMedium?.copyWith(color: BrickColors.sky),
        ),
        const SizedBox(height: Space.lg),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: BrickColors.mint,
              textStyle: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            onPressed: canLaunch ? () => playPlace(context, kind) : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(launchLabel),
          ),
        ),
        const SizedBox(height: Space.md),
        _VoteRow(listing),
      ],
    );

    final stats = <(String, String)>[
      ('Active', formatNumber(listing.playing)),
      ('Visits', formatNumber(listing.visits)),
      ('Server size', '$maxRoomPlayers'),
      ('Round', _mmss(info.matchSeconds)),
      ('Min players', '${info.minPlayers}'),
      ('Genre', _genre(kind)),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: BrickColors.onChrome),
        title: Text(
          info.name,
          style: context.text.titleMedium?.copyWith(
            color: BrickColors.onChrome,
          ),
        ),
        backgroundColor: BrickColors.chrome,
        toolbarHeight: 52,
      ),
      body: ContentWidth(
        max: 1180,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, Space.sm, pad, Space.xxl),
          children: [
            if (phone) ...[
              hero,
              const SizedBox(height: Space.lg),
              side,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: hero),
                  const SizedBox(width: Space.xl),
                  Expanded(flex: 2, child: side),
                ],
              ),
            const SizedBox(height: Space.xl),
            Panel(
              radius: Radii.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: context.text.titleMedium),
                  const SizedBox(height: Space.sm),
                  Text(info.tagline, style: context.text.bodyLarge),
                  const SizedBox(height: Space.xs),
                  Text(
                    info.description,
                    style: context.text.bodyMedium?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const Divider(height: Space.xl),
                  Wrap(
                    spacing: Space.xxl,
                    runSpacing: Space.lg,
                    children: [
                      for (final (label, value) in stats)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: context.text.bodySmall?.copyWith(
                                color: p.textTertiary,
                              ),
                            ),
                            Text(value, style: context.text.titleSmall),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            Text('Servers', style: context.text.titleLarge),
            const SizedBox(height: Space.md),
            if (listing.rooms.isEmpty)
              Panel(
                radius: Radii.md,
                child: Row(
                  children: [
                    Icon(Icons.dns_outlined, color: p.textTertiary),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        'No open servers. Press Play to start one — bots fill the empty seats.',
                        style: context.text.bodyMedium?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final r in listing.rooms) ...[
                _ServerRow(r),
                const SizedBox(height: Space.sm),
              ],
          ],
        ),
      ),
    );
  }
}

String _mmss(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String _genre(ExperienceKind kind) => switch (kind) {
  ExperienceKind.obby => 'Obby',
  ExperienceKind.tycoon => 'Tycoon',
  ExperienceKind.tag => 'Round-based',
};

class _VoteRow extends StatelessWidget {
  const _VoteRow(this.listing);

  final PlaceListing listing;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final kind = listing.info.kind;
    final my = listing.myVote;
    final rating = listing.ratingPercent;
    Widget button(bool up) {
      final active = my == up;
      return Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            backgroundColor: active
                ? BrickColors.sky.withValues(alpha: 0.14)
                : null,
            side: BorderSide(color: active ? BrickColors.sky : p.surface3),
            foregroundColor: active ? BrickColors.sky : p.textPrimary,
          ),
          onPressed: client.connected
              ? () => client.ratePlace(kind, active ? null : up)
              : null,
          icon: Icon(
            up
                ? (active
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined)
                : (active
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_alt_outlined),
            size: 18,
          ),
          label: Text(formatNumber(up ? listing.likes : listing.dislikes)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            button(true),
            const SizedBox(width: Space.sm),
            button(false),
          ],
        ),
        const SizedBox(height: Space.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: rating == null ? 0 : rating / 100,
            backgroundColor: p.surface3,
            color: BrickColors.sky,
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          rating == null
              ? 'No ratings yet'
              : '$rating% of ${formatNumber(listing.votes)} ${listing.votes == 1 ? 'vote' : 'votes'} liked this',
          style: context.text.bodySmall?.copyWith(color: p.textTertiary),
        ),
      ],
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow(this.room);

  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final joinable = room.phase == 'lobby' && room.players < maxRoomPlayers;
    return Panel(
      radius: Radii.md,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.players} of $maxRoomPlayers players',
                  style: context.text.titleSmall,
                ),
                Text(
                  'Room ${room.code} · ${room.phase}',
                  style: context.text.bodySmall?.copyWith(
                    color: p.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BrickColors.mint,
              minimumSize: const Size(0, 40),
            ),
            onPressed: joinable && client.connected
                ? () => client.roomJoin(room.code)
                : null,
            child: const Text('Join'),
          ),
        ],
      ),
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
