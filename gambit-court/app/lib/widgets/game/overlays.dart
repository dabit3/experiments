import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../board/piece_glyph.dart';
import '../ui.dart';

/// Frosted card floating over the board.
class BoardOverlay extends StatelessWidget {
  const BoardOverlay({super.key, required this.child, this.maxWidth = 380});
  final Widget child;
  final double maxWidth;

  /// Below this height the card tightens its padding to fit a phone board.
  static const tightHeight = 420.0;

  static bool isTight(BuildContext context) =>
      (context.findAncestorWidgetOfExactType<_OverlayTightness>()?.tight) ??
      false;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return LayoutBuilder(
      builder: (context, box) {
        final tight = box.maxHeight < tightHeight;
        return _OverlayTightness(
          tight: tight,
          child: Container(
            color: c.bg.withValues(alpha: 0.55),
            alignment: Alignment.center,
            padding: EdgeInsets.all(tight ? GcSpace.sm : GcSpace.lg),
            child: _animated(
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  child: GcCard(
                    raised: true,
                    padding: EdgeInsets.all(tight ? GcSpace.lg : GcSpace.xl),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _animated(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GcMotion.medium,
      curve: GcMotion.enter,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        ),
      ),
      child: child,
    );
  }
}

class _OverlayTightness extends InheritedWidget {
  const _OverlayTightness({required this.tight, required super.child});
  final bool tight;

  @override
  bool updateShouldNotify(_OverlayTightness old) => old.tight != tight;
}

/// Shown while a room waits for its second player.
class WaitingOverlay extends StatelessWidget {
  const WaitingOverlay({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final room = controller.room!;
    final isHost = room.hostClientId == controller.clientId;
    return BoardOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHost ? 'Your table is ready' : 'Waiting for the host',
            style: GcType.heading(c.text, size: 20),
          ),
          const SizedBox(height: GcSpace.xs),
          Text(
            room.isPublic
                ? 'Listed publicly. Share the code or wait for a challenger.'
                : 'Private table. Share this code with your opponent.',
            textAlign: TextAlign.center,
            style: GcType.body(c.textMuted, size: 13, height: 1.5),
          ),
          const SizedBox(height: GcSpace.lg),
          InviteCode(code: room.code),
          const SizedBox(height: GcSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GcPill(
                label:
                    '${room.timeControl.category} · ${room.timeControl.label}',
                icon: Icons.timer_outlined,
              ),
              const SizedBox(width: GcSpace.sm),
              GcPill(
                label: controller.mySide == null
                    ? 'Spectating'
                    : 'You play ${controller.mySide!.label}',
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: GcSpace.xl),
          Wrap(
            spacing: GcSpace.sm,
            runSpacing: GcSpace.sm,
            alignment: WrapAlignment.center,
            children: [
              if (isHost)
                GcButton(
                  label: 'Seat a court bot',
                  icon: Icons.smart_toy_outlined,
                  kind: GcButtonKind.primary,
                  onPressed: controller.addBot,
                ),
              GcButton(
                label: 'Leave table',
                kind: GcButtonKind.ghost,
                onPressed: () => controller.leaveRoom().ignore(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InviteCode extends StatefulWidget {
  const InviteCode({super.key, required this.code});
  final String code;

  @override
  State<InviteCode> createState() => _InviteCodeState();
}

class _InviteCodeState extends State<InviteCode> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Tooltip(
      message: 'Copy code',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copy,
          borderRadius: GcRadius.mdAll,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GcSpace.lg,
              vertical: GcSpace.md,
            ),
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: GcRadius.mdAll,
              border: Border.all(color: c.brass.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.code,
                  style: GcType.mono(
                    c.brass,
                    size: 30,
                    weight: FontWeight.w600,
                  ).copyWith(letterSpacing: 8),
                ),
                const SizedBox(width: GcSpace.md),
                AnimatedSwitcher(
                  duration: GcMotion.fast,
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(_copied),
                    size: 20,
                    color: _copied ? c.verdigris : c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// End-of-game card with rematch flow.
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final room = controller.room!;
    final result = room.result!;
    final me = controller.mySide;
    final winner = result.winner;
    final iWon = me != null && winner == me;
    final iLost = me != null && winner != null && winner != me;
    final title = switch (result.reason) {
      GameEndReason.checkmate => 'Checkmate',
      GameEndReason.stalemate => 'Stalemate',
      GameEndReason.resignation => 'Resignation',
      GameEndReason.timeout => 'Flag fell',
      GameEndReason.agreement => 'Draw agreed',
      GameEndReason.threefoldRepetition => 'Threefold repetition',
      GameEndReason.fiftyMoveRule => 'Fifty-move rule',
      GameEndReason.insufficientMaterial => 'Insufficient material',
      GameEndReason.abandonment => 'Abandoned',
    };
    final winnerName = winner == null
        ? null
        : (winner == PieceColor.white ? room.white?.name : room.black?.name);
    final subtitle = winner == null
        ? 'Draw ${result.reasonLabel}'
        : '${winnerName ?? winner.label} wins ${result.reasonLabel}';
    final accent = iWon
        ? c.verdigris
        : iLost
        ? c.danger
        : c.brass;
    final verdict = iWon
        ? 'Victory'
        : iLost
        ? 'Defeat'
        : me == null
        ? result.headline
        : 'Draw';
    final myRematch = me != null && room.offers.rematch == me;
    final theirRematch = me != null && room.offers.rematch == me.opposite;
    final opponentGone =
        me != null &&
        ((me == PieceColor.white ? room.black : room.white)?.connected ==
            false);
    final vsBot = (room.white?.isBot ?? false) || (room.black?.isBot ?? false);

    return BoardOverlay(
      maxWidth: 400,
      child: Builder(
        builder: (context) {
          final tight = BoardOverlay.isTight(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                verdict.toUpperCase(),
                style: GcType.label(accent, size: 12),
              ),
              const SizedBox(height: GcSpace.xs),
              Text(
                title,
                style: GcType.display(c.text, size: tight ? 28 : 34),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GcSpace.xs),
              Text(
                subtitle,
                style: GcType.body(c.textMuted, size: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tight ? GcSpace.md : GcSpace.lg),
              _ScoreLine(room: room, result: result),
              SizedBox(height: tight ? GcSpace.md : GcSpace.xl),
              if (me != null) ...[
                if (theirRematch)
                  Column(
                    children: [
                      Text(
                        'Your opponent wants a rematch.',
                        style: GcType.body(
                          c.text,
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: GcSpace.sm),
                      Row(
                        children: [
                          Expanded(
                            child: GcButton(
                              label: 'Accept',
                              kind: GcButtonKind.primary,
                              expand: true,
                              icon: Icons.replay_rounded,
                              onPressed: controller.acceptRematch,
                            ),
                          ),
                          const SizedBox(width: GcSpace.sm),
                          Expanded(
                            child: GcButton(
                              label: 'Decline',
                              expand: true,
                              onPressed: controller.declineRematch,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  GcButton(
                    label: myRematch
                        ? 'Rematch offered · waiting'
                        : vsBot
                        ? 'Rematch'
                        : 'Offer rematch',
                    kind: GcButtonKind.primary,
                    icon: Icons.replay_rounded,
                    expand: true,
                    onPressed: myRematch || opponentGone
                        ? null
                        : controller.offerRematch,
                  ),
                if (opponentGone && !theirRematch)
                  Padding(
                    padding: const EdgeInsets.only(top: GcSpace.sm),
                    child: Text(
                      'Your opponent has left the table.',
                      style: GcType.body(c.textFaint, size: 12),
                    ),
                  ),
                const SizedBox(height: GcSpace.sm),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final review = GcButton(
                    label: 'Review',
                    expand: true,
                    icon: Icons.grid_view_rounded,
                    onPressed: controller.dismissResults,
                  );
                  final copy = GcButton(
                    label: 'Copy PGN',
                    expand: true,
                    icon: Icons.copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: controller.exportPgn()),
                      );
                      controller.showNotice('PGN copied to clipboard.');
                    },
                  );
                  if (constraints.maxWidth < 320) {
                    return Column(
                      children: [
                        review,
                        const SizedBox(height: GcSpace.sm),
                        copy,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: review),
                      const SizedBox(width: GcSpace.sm),
                      Expanded(child: copy),
                    ],
                  );
                },
              ),
              const SizedBox(height: GcSpace.sm),
              GcButton(
                label: 'Back to lobby',
                kind: GcButtonKind.ghost,
                expand: true,
                onPressed: () => controller.leaveRoom().ignore(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.room, required this.result});
  final RoomSnapshot room;
  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    Widget side(PieceColor color, Participant? p) {
      final won = result.winner == color;
      return Expanded(
        child: Column(
          children: [
            PieceGlyph(
              Piece(color, PieceType.king),
              size: 40,
              opacity: result.winner == null || won ? 1 : 0.45,
            ),
            const SizedBox(height: 4),
            Text(
              p?.name ?? color.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GcType.body(
                won ? c.text : c.textMuted,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        side(PieceColor.white, room.white),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.surfaceSunken,
            borderRadius: GcRadius.smAll,
            border: Border.all(color: c.border),
          ),
          child: Text(
            result.score,
            style: GcType.mono(c.text, size: 22, weight: FontWeight.w600),
          ),
        ),
        side(PieceColor.black, room.black),
      ],
    );
  }
}

/// Promotion piece picker.
Future<PieceType?> showPromotionPicker(BuildContext context, PieceColor color) {
  final c = context.gc;
  return showDialog<PieceType>(
    context: context,
    barrierColor: c.bg.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: c.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: GcRadius.lgAll,
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GcSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Promote to', style: GcType.heading(c.text, size: 16)),
            const SizedBox(height: GcSpace.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final type in PieceType.promotionTargets)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PromotionOption(
                      piece: Piece(color, type),
                      onTap: () => Navigator.of(context).pop(type),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PromotionOption extends StatefulWidget {
  const _PromotionOption({required this.piece, required this.onTap});
  final Piece piece;
  final VoidCallback onTap;

  @override
  State<_PromotionOption> createState() => _PromotionOptionState();
}

class _PromotionOptionState extends State<_PromotionOption> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: GcMotion.micro,
          width: 72,
          height: 84,
          decoration: BoxDecoration(
            color: _hover ? c.brassSoft : c.surfaceSunken,
            borderRadius: GcRadius.mdAll,
            border: Border.all(color: _hover ? c.brass : c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PieceGlyph(widget.piece, size: 48),
              const SizedBox(height: 4),
              Text(
                widget.piece.type.sanLetter,
                style: GcType.mono(c.textMuted, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner for incoming/outgoing draw & takeback offers.
class OfferBanner extends StatelessWidget {
  const OfferBanner({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final room = controller.room;
    final me = controller.mySide;
    if (room == null || me == null || room.status != RoomStatus.playing) {
      return const SizedBox.shrink();
    }
    final offers = room.offers;
    Widget? content;
    if (offers.draw == me.opposite) {
      content = _offer(
        context,
        'Your opponent offers a draw.',
        controller.acceptDraw,
        controller.declineDraw,
      );
    } else if (offers.takeback == me.opposite) {
      content = _offer(
        context,
        'Your opponent asks to take back their last move.',
        controller.acceptTakeback,
        controller.declineTakeback,
      );
    } else if (offers.draw == me) {
      content = _pending(context, 'Draw offered · waiting for a reply');
    } else if (offers.takeback == me) {
      content = _pending(context, 'Takeback requested · waiting for a reply');
    }
    return AnimatedSize(
      duration: GcMotion.fast,
      curve: GcMotion.enter,
      alignment: Alignment.topCenter,
      child: content == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.only(bottom: GcSpace.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: GcSpace.md,
                vertical: GcSpace.sm,
              ),
              decoration: BoxDecoration(
                color: c.brassSoft,
                borderRadius: GcRadius.mdAll,
                border: Border.all(color: c.brass.withValues(alpha: 0.5)),
              ),
              child: content,
            ),
    );
  }

  Widget _offer(
    BuildContext context,
    String text,
    VoidCallback accept,
    VoidCallback decline,
  ) {
    final c = context.gc;
    return Row(
      children: [
        Icon(Icons.handshake_outlined, size: 18, color: c.brass),
        const SizedBox(width: GcSpace.sm),
        Expanded(
          child: Text(
            text,
            style: GcType.body(c.text, size: 13, weight: FontWeight.w600),
          ),
        ),
        GcButton(
          label: 'Accept',
          compact: true,
          kind: GcButtonKind.primary,
          onPressed: accept,
        ),
        const SizedBox(width: 6),
        GcButton(
          label: 'Decline',
          compact: true,
          kind: GcButtonKind.ghost,
          onPressed: decline,
        ),
      ],
    );
  }

  Widget _pending(BuildContext context, String text) {
    final c = context.gc;
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.brass),
        ),
        const SizedBox(width: GcSpace.sm),
        Expanded(child: Text(text, style: GcType.body(c.textMuted, size: 13))),
      ],
    );
  }
}
