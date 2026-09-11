import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../net/connection.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/board/chess_board.dart';
import '../widgets/game/move_list.dart';
import '../widgets/game/overlays.dart';
import '../widgets/game/player_card.dart';
import '../widgets/top_bar.dart';
import '../widgets/ui.dart';

/// Live game and PGN review share one screen: board, two player cards,
/// notation and actions. Layout adapts from phone to desktop.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  AppController get c => widget.controller;
  final _focus = FocusNode(debugLabel: 'game');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- input

  void _onTap(int square) {
    final sel = c.selectedSquare;
    if (sel != null &&
        c.isMyTurn &&
        sel != square &&
        c.needsPromotion(sel, square)) {
      _promote(sel, square, premove: false);
      return;
    }
    c.tapSquare(square);
  }

  bool _onDrop(int from, int to) {
    if (c.isMyTurn) {
      if (c.needsPromotion(from, to)) {
        _promote(from, to, premove: false);
        return true;
      }
      final ok = c.requestMove(from, to);
      if (!ok) c.clearSelection();
      return ok;
    }
    if (c.isPlaying && !c.isBrowsingHistory) {
      final piece = c.displayedPosition.pieceAt(from);
      if (piece?.color == c.mySide) {
        final promo =
            piece!.type == PieceType.pawn &&
            (Square.rankOf(to) == 7 || Square.rankOf(to) == 0);
        if (promo) {
          _promote(from, to, premove: true);
        } else {
          c.setPremove(from, to);
        }
        return true;
      }
    }
    return false;
  }

  Future<void> _promote(int from, int to, {required bool premove}) async {
    final side = c.mySide ?? PieceColor.white;
    final type = await showPromotionPicker(context, side);
    if (!mounted) return;
    if (type == null) {
      c.clearSelection();
      return;
    }
    if (premove) {
      c.setPremove(from, to, promotion: type);
    } else {
      c.requestMove(from, to, promotion: type);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      c.stepHistory(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      c.stepHistory(1);
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.home) {
      c.viewPlyAt(0);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.end) {
      c.viewPlyAt(null);
    } else if (key == LogicalKeyboardKey.keyF) {
      c.flipBoard();
    } else if (key == LogicalKeyboardKey.escape) {
      if (c.premove != null) {
        c.clearPremove();
      } else if (c.selectedSquare != null) {
        c.clearSelection();
      } else if (c.showResults) {
        c.dismissResults();
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------- layout

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide =
        size.width >= GcBreakpoints.desktop ||
        (size.width >= GcBreakpoints.tablet && size.width > size.height);
    final compact = size.width < GcBreakpoints.tablet;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focus.requestFocus(),
        child: Column(
          children: [
            TopBar(
              controller: c,
              compact: compact,
              leading: GcIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: c.review != null ? 'Close review' : 'Leave table',
                onPressed: () => _leave(context),
              ),
              trailing: [if (compact) _RoomBadge(controller: c, compact: true)],
            ),
            _ConnectionBanner(controller: c),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.5, -0.3),
                    radius: 1.2,
                    colors: [context.gc.surfaceRaised, context.gc.bg],
                  ),
                ),
                child: wide
                    ? _WideLayout(controller: c, onTap: _onTap, onDrop: _onDrop)
                    : _StackedLayout(
                        controller: c,
                        onTap: _onTap,
                        onDrop: _onDrop,
                        compact: compact,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context) async {
    if (c.review != null) {
      c.closeReview();
      return;
    }
    if (c.isPlaying) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          final t = context.gc;
          return AlertDialog(
            title: Text(
              'Leave the game?',
              style: GcType.heading(t.text, size: 18),
            ),
            content: Text(
              'Leaving a live game counts as a resignation.',
              style: GcType.body(t.textMuted, size: 14),
            ),
            actions: [
              GcButton(
                label: 'Stay',
                kind: GcButtonKind.ghost,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              GcButton(
                label: 'Resign & leave',
                kind: GcButtonKind.danger,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      if (confirm != true) return;
    }
    c.leaveRoom().ignore();
  }
}

/// Board plus stacked player cards; sized to the available box.
class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.controller,
    required this.onTap,
    required this.onDrop,
    required this.compact,
    this.showCards = true,
  });
  final AppController controller;
  final void Function(int) onTap;
  final bool Function(int, int) onDrop;
  final bool compact;

  /// When false the seat cards are rendered elsewhere (the side panel) and
  /// the board takes the full height.
  final bool showCards;

  static double cardHeight(bool compact) => compact ? 56.0 : 68.0;
  static double _gap(bool compact) => compact ? GcSpace.sm : GcSpace.md;

  static double _boardSize(
    BoxConstraints box, {
    required bool compact,
    bool showCards = true,
  }) {
    final cards = showCards ? 2 * (cardHeight(compact) + _gap(compact)) : 0;
    final maxBoard = math.min(box.maxWidth, box.maxHeight - cards);
    return maxBoard.clamp(200.0, 860.0).floorToDouble();
  }

  /// Total height the column occupies inside [box] (board + both cards).
  static double heightFor(BoxConstraints box, {required bool compact}) =>
      _boardSize(box, compact: compact) +
      2 * (cardHeight(compact) + _gap(compact));

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final t = context.gc;
    return LayoutBuilder(
      builder: (context, box) {
        final cardH = cardHeight(compact);
        final gap = _gap(compact);
        final boardSize = _boardSize(
          box,
          compact: compact,
          showCards: showCards,
        );
        final top = c.orientation.opposite;
        final bottom = c.orientation;
        final room = c.room;
        final movable = c.isPlaying && !c.isBrowsingHistory ? c.mySide : null;
        final position = c.displayedPosition;

        Widget card(PieceColor color) => SizedBox(
          width: boardSize,
          height: cardH,
          child: _SeatCard(controller: c, color: color, compact: compact),
        );

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCards) ...[card(top), SizedBox(height: gap)],
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(t.boardFrame, GcArcade.porcelain, 0.2)!,
                          t.boardFrame,
                          GcArcade.midnight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(compact ? 10 : 14),
                      boxShadow: [
                        BoxShadow(
                          color: t.surfaceSunken,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: t.shadow.withValues(
                            alpha: context.isDark ? 0.55 : 0.18,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ChessBoard(
                      position: position,
                      orientation: c.orientation,
                      size: boardSize - 12,
                      lastMove: c.displayedLastMove,
                      selected: c.selectedSquare,
                      premove: c.premove,
                      transition: c.transition,
                      movableColor: movable,
                      onTap: onTap,
                      onDrop: onDrop,
                      showCoordinates: !compact || boardSize > 340,
                      dimmed: room?.status == RoomStatus.waiting,
                    ),
                  ),
                  if (room?.status == RoomStatus.waiting)
                    Positioned.fill(child: WaitingOverlay(controller: c)),
                  if (c.showResults)
                    Positioned.fill(child: ResultsOverlay(controller: c)),
                ],
              ),
              if (showCards) ...[SizedBox(height: gap), card(bottom)],
            ],
          ),
        );
      },
    );
  }
}

/// A player's seat: name, platform, clock, captured material.
class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.controller,
    required this.color,
    required this.compact,
  });
  final AppController controller;
  final PieceColor color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final room = c.room;
    final review = c.review;
    final gameOver = room?.status == RoomStatus.finished || review != null;
    final position = c.displayedPosition;
    final startFen = review != null
        ? Position.initial.fen
        : (room?.startFen ?? Position.initial.fen);
    final start = Position.fromFen(startFen) ?? Position.initial;
    final participant = review != null
        ? Participant(
            clientId: '',
            name:
                c.reviewTags[color == PieceColor.white ? 'White' : 'Black'] ??
                color.label,
            platform: 'pgn',
            connected: true,
            isBot: false,
            botLevel: null,
          )
        : room?.player(color);
    return PlayerCard(
      color: color,
      participant: participant,
      clocks: room?.clocks,
      receivedLocalMs: c.roomReceivedLocalMs,
      active:
          room?.status == RoomStatus.playing &&
          position.turn == color &&
          !c.isBrowsingHistory,
      captured: capturedPieces(start, position, takenFrom: color.opposite),
      materialLead: materialLead(position, color) ~/ 100,
      timeControl: room?.timeControl ?? TimeControl.unlimited,
      gameOver: gameOver,
      isMe: c.mySide == color,
      compact: compact,
      inCheck: position.turn == color && position.isInCheck,
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.controller,
    required this.onTap,
    required this.onDrop,
  });
  final AppController controller;
  final void Function(int) onTap;
  final bool Function(int, int) onDrop;

  /// Below this content height the seat cards move into the side panel so
  /// the board can use the full height of a shallow desktop window.
  static const _shallow = 720.0;

  @override
  Widget build(BuildContext context) {
    final t = context.gc;
    return Padding(
      padding: const EdgeInsets.all(GcSpace.xl),
      child: LayoutBuilder(
        builder: (context, box) {
          final sideCards = box.maxHeight < _shallow;
          return Row(
            children: [
              Expanded(
                child: _BoardColumn(
                  controller: controller,
                  onTap: onTap,
                  onDrop: onDrop,
                  compact: false,
                  showCards: !sideCards,
                ),
              ),
              const SizedBox(width: GcSpace.xl),
              SizedBox(
                width: 340,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: GcRadius.lgAll,
                    border: Border.all(color: t.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _SidePanel(
                    controller: controller,
                    seatCards: sideCards,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StackedLayout extends StatelessWidget {
  const _StackedLayout({
    required this.controller,
    required this.onTap,
    required this.onDrop,
    required this.compact,
  });
  final AppController controller;
  final void Function(int) onTap;
  final bool Function(int, int) onDrop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? GcSpace.sm : GcSpace.lg;
    final gap = compact ? GcSpace.sm : GcSpace.md;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final t = context.gc;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
      child: Column(
        children: [
          OfferBanner(controller: controller),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final needed = _BoardColumn.heightFor(box, compact: compact);
                final spare = box.maxHeight - needed;
                // Tall phones/tablets get a proper move table under the
                // board; short viewports fall back to a one-line ribbon.
                final table = spare >= 150;
                return Column(
                  children: [
                    if (table)
                      SizedBox(
                        height: needed,
                        child: _BoardColumn(
                          controller: controller,
                          onTap: onTap,
                          onDrop: onDrop,
                          compact: compact,
                        ),
                      )
                    else
                      Expanded(
                        child: _BoardColumn(
                          controller: controller,
                          onTap: onTap,
                          onDrop: onDrop,
                          compact: compact,
                        ),
                      ),
                    SizedBox(height: gap),
                    if (table)
                      Expanded(
                        child: Container(
                          width: math.min(box.maxWidth, 860),
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: GcRadius.mdAll,
                            border: Border.all(color: t.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MoveList(
                            moves: controller.displayedMoves,
                            viewPly: controller.viewPly ?? controller.livePly,
                            onSelectPly: controller.viewPlyAt,
                            result: controller.room?.result,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 36,
                        child: MoveList(
                          moves: controller.displayedMoves,
                          viewPly: controller.viewPly ?? controller.livePly,
                          onSelectPly: controller.viewPlyAt,
                          horizontal: true,
                          result: controller.room?.result,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: compact ? GcSpace.xs : GcSpace.sm),
          _ActionBar(controller: controller, compact: true),
          SizedBox(height: bottomInset > 0 ? bottomInset : GcSpace.sm),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.controller, this.seatCards = false});
  final AppController controller;

  /// Render the two seat cards at the top and bottom of the panel (used when
  /// the board column has no room for them).
  final bool seatCards;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final t = context.gc;
    Widget seat(PieceColor color) => Padding(
      padding: const EdgeInsets.fromLTRB(GcSpace.md, GcSpace.md, GcSpace.md, 0),
      child: SizedBox(
        height: _BoardColumn.cardHeight(false),
        child: _SeatCard(controller: c, color: color, compact: false),
      ),
    );
    return Column(
      children: [
        if (seatCards) seat(c.orientation.opposite),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GcSpace.lg,
            GcSpace.lg,
            GcSpace.lg,
            GcSpace.md,
          ),
          child: _RoomBadge(controller: c),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GcSpace.lg),
          child: OfferBanner(controller: c),
        ),
        const GcDivider(),
        Expanded(
          child: MoveList(
            moves: c.displayedMoves,
            viewPly: c.viewPly ?? c.livePly,
            onSelectPly: c.viewPlyAt,
            result: c.room?.result,
          ),
        ),
        const GcDivider(),
        if (seatCards)
          // Shallow windows: one row of history + game actions keeps the
          // move list readable.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GcSpace.md,
              vertical: GcSpace.sm,
            ),
            child: _ActionBar(controller: c, compact: true),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GcSpace.md,
              GcSpace.sm,
              GcSpace.md,
              GcSpace.sm,
            ),
            child: HistoryControls(
              viewPly: c.viewPly ?? c.livePly,
              total: c.livePly,
              onSelect: c.viewPlyAt,
            ),
          ),
          const GcDivider(),
          Padding(
            padding: const EdgeInsets.all(GcSpace.md),
            child: _ActionBar(controller: c, compact: false),
          ),
        ],
        if (!seatCards && c.room != null && c.room!.spectators.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GcSpace.lg,
              0,
              GcSpace.lg,
              GcSpace.md,
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: t.textFaint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.room!.spectators.map((s) => s.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GcType.body(t.textFaint, size: 12),
                  ),
                ),
              ],
            ),
          ),
        if (seatCards) ...[
          const GcDivider(),
          Padding(
            padding: const EdgeInsets.only(bottom: GcSpace.md),
            child: seat(c.orientation),
          ),
        ],
      ],
    );
  }
}

class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.controller, this.compact = false});
  final AppController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.gc;
    final room = controller.room;
    final review = controller.review;
    if (review != null) {
      final event = controller.reviewTags['Event'];
      return Row(
        children: [
          GcPill(label: 'Review', icon: Icons.article_outlined, color: t.brass),
          if (!compact && event != null && event.isNotEmpty) ...[
            const SizedBox(width: GcSpace.sm),
            Expanded(
              child: Text(
                event,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GcType.body(t.textMuted, size: 13),
              ),
            ),
          ],
        ],
      );
    }
    if (room == null) return const SizedBox.shrink();
    final status = switch (room.status) {
      RoomStatus.waiting => ('Waiting', t.brass),
      RoomStatus.playing => ('Live', t.verdigris),
      RoomStatus.finished => ('Finished', t.textMuted),
    };
    final code = Tooltip(
      message: 'Copy table code',
      child: InkWell(
        borderRadius: GcRadius.smAll,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: room.code));
          controller.showNotice('Code ${room.code} copied.');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            room.code,
            style: GcType.mono(
              t.brass,
              size: compact ? 13 : 15,
              weight: FontWeight.w600,
            ).copyWith(letterSpacing: 2),
          ),
        ),
      ),
    );
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          code,
          const SizedBox(width: 4),
          GcPill(
            label: status.$1,
            color: status.$2,
            pulse: room.status == RoomStatus.playing,
          ),
        ],
      );
    }
    return Wrap(
      spacing: GcSpace.sm,
      runSpacing: GcSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        code,
        GcPill(
          label: status.$1,
          color: status.$2,
          pulse: room.status == RoomStatus.playing,
        ),
        if (controller.isSpectator)
          const GcPill(label: 'Watching', icon: Icons.visibility_outlined),
        Text(
          room.timeControl.isUnlimited
              ? 'No clock'
              : '${room.timeControl.category} · ${room.timeControl.label}',
          style: GcType.mono(t.textMuted, size: 12.5),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller, required this.compact});
  final AppController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final room = c.room;
    final playing = c.isPlaying;
    final offers = room?.offers;
    final me = c.mySide;
    final myDrawPending = me != null && offers?.draw == me;
    final myTakebackPending = me != null && offers?.takeback == me;
    final canTakeback = playing && c.livePly > 0 && !myTakebackPending;

    final actions = <Widget>[
      GcIconButton(
        icon: Icons.swap_vert_rounded,
        tooltip: 'Flip board (F)',
        onPressed: c.flipBoard,
      ),
      if (compact) ...[
        GcIconButton(
          icon: Icons.first_page_rounded,
          tooltip: 'First move',
          onPressed: c.livePly == 0 ? null : () => c.viewPlyAt(0),
        ),
        GcIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous move',
          onPressed: c.livePly == 0 ? null : () => c.stepHistory(-1),
        ),
        GcIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next move',
          onPressed: c.isBrowsingHistory ? () => c.stepHistory(1) : null,
        ),
        GcIconButton(
          icon: Icons.last_page_rounded,
          tooltip: 'Live position',
          onPressed: c.isBrowsingHistory ? () => c.viewPlyAt(null) : null,
        ),
      ],
      GcIconButton(
        icon: Icons.ios_share_rounded,
        tooltip: 'Copy PGN',
        onPressed: c.displayedMoves.isEmpty
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: c.exportPgn()));
                c.showNotice('PGN copied to clipboard.');
              },
      ),
    ];

    final gameActions = <Widget>[
      if (playing) ...[
        GcButton(
          label: myDrawPending ? 'Draw offered' : 'Draw',
          icon: Icons.handshake_outlined,
          compact: true,
          onPressed: myDrawPending ? null : c.offerDraw,
          tooltip: 'Offer a draw',
        ),
        GcButton(
          label: myTakebackPending ? 'Asked' : 'Takeback',
          icon: Icons.undo_rounded,
          compact: true,
          onPressed: canTakeback ? c.offerTakeback : null,
          tooltip: 'Ask to take back the last move',
        ),
        GcButton(
          label: 'Resign',
          icon: Icons.flag_outlined,
          compact: true,
          kind: GcButtonKind.danger,
          onPressed: () => _confirmResign(context),
        ),
      ],
      if (room?.status == RoomStatus.finished && !c.showResults)
        GcButton(
          label: 'Result',
          icon: Icons.emoji_events_outlined,
          compact: true,
          kind: GcButtonKind.primary,
          onPressed: c.restoreResults,
        ),
      if (c.premove != null)
        GcButton(
          label: 'Cancel premove',
          icon: Icons.close_rounded,
          compact: true,
          kind: GcButtonKind.ghost,
          onPressed: c.clearPremove,
        ),
    ];

    if (compact) {
      return LayoutBuilder(
        builder: (context, box) {
          // Phone widths: icon-only game actions and a two-button history
          // stepper so everything fits on one row.
          if (box.maxWidth < 560) {
            return Row(
              children: [
                actions.first,
                GcIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous move',
                  onPressed: c.livePly == 0 ? null : () => c.stepHistory(-1),
                ),
                GcIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next move',
                  onPressed: c.isBrowsingHistory
                      ? () => c.stepHistory(1)
                      : null,
                ),
                actions.last,
                const Spacer(),
                if (playing) ...[
                  GcIconButton(
                    icon: Icons.handshake_outlined,
                    tooltip: myDrawPending ? 'Draw offered' : 'Offer a draw',
                    active: myDrawPending,
                    onPressed: myDrawPending ? null : c.offerDraw,
                  ),
                  GcIconButton(
                    icon: Icons.undo_rounded,
                    tooltip: myTakebackPending
                        ? 'Takeback requested'
                        : 'Ask to take back the last move',
                    active: myTakebackPending,
                    onPressed: canTakeback ? c.offerTakeback : null,
                  ),
                  GcIconButton(
                    icon: Icons.flag_outlined,
                    tooltip: 'Resign',
                    danger: true,
                    onPressed: () => _confirmResign(context),
                  ),
                ],
                if (room?.status == RoomStatus.finished && !c.showResults)
                  GcIconButton(
                    icon: Icons.emoji_events_outlined,
                    tooltip: 'Show result',
                    active: true,
                    onPressed: c.restoreResults,
                  ),
                if (c.premove != null)
                  GcIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cancel premove',
                    onPressed: c.clearPremove,
                  ),
              ],
            );
          }
          return Row(
            children: [
              ...actions,
              const Spacer(),
              ...gameActions.expand((w) => [w, const SizedBox(width: 6)]),
            ],
          );
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [...actions, const Spacer()]),
        if (gameActions.isNotEmpty) ...[
          const SizedBox(height: GcSpace.sm),
          Wrap(spacing: 6, runSpacing: 6, children: gameActions),
        ],
      ],
    );
  }

  Future<void> _confirmResign(BuildContext context) async {
    final t = context.gc;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Resign this game?',
          style: GcType.heading(t.text, size: 18),
        ),
        content: Text(
          'Your opponent will be awarded the win.',
          style: GcType.body(t.textMuted, size: 14),
        ),
        actions: [
          GcButton(
            label: 'Keep playing',
            kind: GcButtonKind.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          GcButton(
            label: 'Resign',
            kind: GcButtonKind.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) controller.resign();
  }
}

/// Slim banner while the socket is down; the server holds the seat.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.gc;
    return ValueListenableBuilder<ConnectionPhase>(
      valueListenable: controller.connection.phase,
      builder: (context, phase, _) {
        final show =
            phase != ConnectionPhase.online && controller.review == null;
        return AnimatedSize(
          duration: GcMotion.fast,
          curve: GcMotion.enter,
          alignment: Alignment.topCenter,
          child: !show
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GcSpace.lg,
                    vertical: GcSpace.sm,
                  ),
                  color: phase == ConnectionPhase.offline
                      ? t.dangerSoft
                      : t.brassSoft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: phase == ConnectionPhase.offline
                              ? t.danger
                              : t.brass,
                        ),
                      ),
                      const SizedBox(width: GcSpace.sm),
                      Expanded(
                        child: Text(
                          phase == ConnectionPhase.offline
                              ? 'Offline. Retrying — your seat is held for a minute.'
                              : 'Reconnecting to the table…',
                          style: GcType.body(
                            t.text,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GcButton(
                        label: 'Retry now',
                        compact: true,
                        kind: GcButtonKind.ghost,
                        onPressed: controller.connection.reconnectNow,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

/// Piece types of [takenFrom]'s colour missing relative to the start.
List<PieceType> capturedPieces(
  Position start,
  Position now, {
  required PieceColor takenFrom,
}) {
  final counts = <PieceType, int>{};
  for (var sq = 0; sq < 64; sq++) {
    final p = start.pieceAt(sq);
    if (p != null && p.color == takenFrom) {
      counts[p.type] = (counts[p.type] ?? 0) + 1;
    }
  }
  for (var sq = 0; sq < 64; sq++) {
    final p = now.pieceAt(sq);
    if (p != null && p.color == takenFrom) {
      counts[p.type] = (counts[p.type] ?? 0) - 1;
    }
  }
  final out = <PieceType>[];
  for (final type in const [
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
    PieceType.pawn,
  ]) {
    final n = counts[type] ?? 0;
    for (var i = 0; i < n; i++) {
      out.add(type);
    }
  }
  return out;
}

int materialLead(Position position, PieceColor color) {
  var mine = 0;
  var theirs = 0;
  for (var sq = 0; sq < 64; sq++) {
    final p = position.pieceAt(sq);
    if (p == null || p.type == PieceType.king) continue;
    if (p.color == color) {
      mine += p.type.value;
    } else {
      theirs += p.type.value;
    }
  }
  return mine - theirs;
}
