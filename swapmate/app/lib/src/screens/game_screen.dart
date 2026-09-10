import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../net/game_client.dart';
import '../theme/tokens.dart';
import '../widgets/board_view.dart';
import '../widgets/chat_panel.dart';
import '../widgets/common.dart';
import '../widgets/move_list.dart';
import '../widgets/piece_painter.dart';

/// Programmatic access to the live game screen, used by the test channel to
/// drive the real UI (selection, taps, drops) rather than bypassing it.
abstract class GameScreenController {
  static GameScreenController? current;

  /// Plays [uci] on the local player's board through the same code path as a
  /// tap/drag. Returns an error string if the move is not playable now.
  String? playUci(String uci);

  /// Queues a premove/pre-drop.
  String? premoveUci(String uci);

  Map<String, dynamic> debugState();
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.client,
    required this.onToggleTheme,
  });

  final GameClient client;
  final VoidCallback onToggleTheme;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    implements GameScreenController {
  int? _selected;
  PieceType? _selectedReserve;
  Set<int> _targets = const {};
  StreamSubscription<GameEvent>? _events;
  StreamSubscription<ClientError>? _errors;
  StreamSubscription<ChatMessage>? _chat;
  final _boardKeys = {BoardId.a: GlobalKey(), BoardId.b: GlobalKey()};
  final _trayKeys = {for (final s in Seat.values) s: GlobalKey()};
  final _passes = <_Pass>[];
  _Toast? _toast;
  Timer? _toastTimer;
  bool _chatOpen = false;
  int _unread = 0;

  GameClient get client => widget.client;
  GameState get game => client.game!;
  Seat? get mySeat => client.mySeat;
  bool get spectating => mySeat == null;

  /// Board shown large: mine, or A for spectators.
  BoardId get mainBoard => mySeat?.board ?? BoardId.a;
  PieceColor orientationFor(BoardId b) {
    final seat = mySeat;
    if (seat == null) {
      return b == BoardId.a ? PieceColor.white : PieceColor.black;
    }
    return b == seat.board ? seat.color : seat.partner.color;
  }

  Position get myPosition => game.boards[mainBoard]!.position;
  bool get myTurn =>
      mySeat != null && !game.isOver && myPosition.turn == mySeat!.color;

  @override
  void initState() {
    super.initState();
    GameScreenController.current = this;
    _events = client.events.listen(_onEvent);
    _errors = client.errors.listen((e) {
      if (e.code == ErrorCode.illegalMove) {
        _show('Illegal move', danger: true);
        HapticFeedback.heavyImpact();
      } else if (e.code != 'connect_failed') {
        _show(e.message, danger: true);
      }
    });
    _chat = client.chatStream.listen((m) {
      if (!_chatOpen && m.fromId != client.playerId && !_isWide) {
        setState(() => _unread++);
      }
      if (m.quick != null && m.fromId != client.playerId) {
        _show('${m.fromName}: ${m.display}');
      }
    });
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 1024;

  @override
  void dispose() {
    if (GameScreenController.current == this) {
      GameScreenController.current = null;
    }
    _events?.cancel();
    _errors?.cancel();
    _chat?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(GameScreen old) {
    super.didUpdateWidget(old);
    // Clear a stale selection when the position changed under it.
    if (_selected != null &&
        myPosition.at(_selected!)?.color != mySeat?.color) {
      _clearSelection();
    }
  }

  void _clearSelection() {
    _selected = null;
    _selectedReserve = null;
    _targets = const {};
  }

  void _show(String text, {bool danger = false}) {
    _toastTimer?.cancel();
    setState(() => _toast = _Toast(text, danger));
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _onEvent(GameEvent e) {
    if (!mounted) return;
    switch (e.kind) {
      case 'pass':
        _animatePass(e);
        if (e.toBoard == mainBoard && e.toColor == mySeat?.color) {
          HapticFeedback.mediumImpact();
        }
      case 'check':
        if (e.board == mainBoard) {
          _show('Check!');
          HapticFeedback.mediumImpact();
        }
      case 'move':
        if (e.seat == mySeat) HapticFeedback.lightImpact();
      case 'end':
        HapticFeedback.heavyImpact();
    }
  }

  void _animatePass(GameEvent e) {
    final captured = e.captured;
    final toBoard = e.toBoard;
    final toColor = e.toColor;
    final move = e.move;
    if (captured == null ||
        toBoard == null ||
        toColor == null ||
        move == null) {
      return;
    }
    final fromBox =
        _boardKeys[e.board]?.currentContext?.findRenderObject() as RenderBox?;
    final toBox =
        _trayKeys[Seat.at(toBoard, toColor)]?.currentContext?.findRenderObject()
            as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (fromBox == null || toBox == null || overlayBox == null) return;
    final size = fromBox.size.shortestSide;
    final rect = BoardView.squareRect(move.to, size, orientationFor(e.board!));
    final start = overlayBox.globalToLocal(fromBox.localToGlobal(rect.center));
    final end = overlayBox.globalToLocal(
      toBox.localToGlobal(toBox.size.center(Offset.zero)),
    );
    final pass = _Pass(Piece(toColor, captured), start, end, rect.width);
    setState(() => _passes.add(pass));
    Timer(Motion.pass + const Duration(milliseconds: 60), () {
      if (mounted) setState(() => _passes.remove(pass));
    });
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  void _tapSquare(int sq) {
    if (spectating || game.isOver) return;
    final pos = myPosition;
    final me = mySeat!.color;
    final piece = pos.at(sq);

    if (_selectedReserve != null) {
      final m = Move.drop(_selectedReserve!, sq);
      if (piece == null) {
        _submit(m);
      } else if (piece.color == me) {
        setState(() {
          _selectedReserve = null;
          _select(sq);
        });
      }
      return;
    }
    if (_selected != null) {
      if (sq == _selected) {
        setState(_clearSelection);
        return;
      }
      if (piece != null && piece.color == me) {
        setState(() => _select(sq));
        return;
      }
      _tryMove(_selected!, sq);
      return;
    }
    if (piece != null && piece.color == me) setState(() => _select(sq));
  }

  void _select(int sq) {
    _selected = sq;
    _selectedReserve = null;
    _targets = myTurn
        ? myPosition.legalMovesFrom(sq).map((m) => m.to).toSet()
        : const {};
  }

  void _selectReserve(PieceType t) {
    if (spectating || game.isOver) return;
    setState(() {
      if (_selectedReserve == t) {
        _clearSelection();
      } else {
        _selected = null;
        _selectedReserve = t;
        _targets = myTurn
            ? myPosition
                  .legalMoves()
                  .where((m) => m.drop == t)
                  .map((m) => m.to)
                  .toSet()
            : const {};
      }
    });
  }

  Set<int> get _dropTargets => myTurn
      ? myPosition.legalMoves().where((m) => m.isDrop).map((m) => m.to).toSet()
      : const {};

  Future<void> _tryMove(int from, int to) async {
    final pos = myPosition;
    final piece = pos.at(from);
    if (piece == null) return;
    PieceType? promo;
    final toRank = Square.rankOf(to);
    if (piece.type == PieceType.pawn && (toRank == 0 || toRank == 7)) {
      if (myTurn &&
          !pos.legalMoves().any((m) => m.from == from && m.to == to)) {
        setState(_clearSelection);
        return;
      }
      promo = await _pickPromotion(piece.color);
      if (promo == null) {
        setState(_clearSelection);
        return;
      }
    }
    _submit(Move.normal(from, to, promotion: promo));
  }

  void _submit(Move m) {
    if (myTurn) {
      if (!myPosition.isLegal(m)) {
        _show('Illegal move', danger: true);
        HapticFeedback.heavyImpact();
        setState(_clearSelection);
        return;
      }
      client.move(m);
    } else {
      client.premove(m);
      _show(m.isDrop ? 'Pre-drop set' : 'Premove set');
    }
    setState(_clearSelection);
  }

  Future<PieceType?> _pickPromotion(PieceColor color) => showDialog<PieceType>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Promote to', style: context.type.headlineSmall),
            const SizedBox(height: Space.lg),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final t in [
                  PieceType.queen,
                  PieceType.rook,
                  PieceType.bishop,
                  PieceType.knight,
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                    child: InkWell(
                      key: Key('promo-${t.letter}'),
                      borderRadius: BorderRadius.circular(Radii.md),
                      onTap: () => Navigator.of(context).pop(t),
                      child: Padding(
                        padding: const EdgeInsets.all(Space.sm),
                        child: PieceGlyph(Piece(color, t), size: 56),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmResign() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Your team loses the match immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            key: const Key('resign-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (ok == true) client.resign();
  }

  // ---------------------------------------------------------------------------
  // Test channel
  // ---------------------------------------------------------------------------

  @override
  String? playUci(String uci) {
    if (spectating) return 'spectating';
    if (game.isOver) return 'game_over';
    final m = Move.parse(uci);
    if (!myTurn) return 'not_your_turn';
    if (!myPosition.isLegal(m)) return 'illegal';
    if (m.isDrop) {
      _selectReserve(m.drop!);
      _tapSquare(m.to);
    } else {
      _tapSquare(m.from!);
      if (m.promotion != null) {
        _submit(m);
      } else {
        _tapSquare(m.to);
      }
    }
    return null;
  }

  @override
  String? premoveUci(String uci) {
    if (spectating) return 'spectating';
    if (game.isOver) return 'game_over';
    client.premove(Move.parse(uci));
    return null;
  }

  @override
  Map<String, dynamic> debugState() => {
    'mainBoard': mainBoard.id,
    'myTurn': myTurn,
    'selected': _selected,
    'selectedReserve': _selectedReserve?.letter,
  };

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 1024;
    final medium = size.width >= 700 && size.width > size.height;

    return Scaffold(
      body: SafeArea(
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  setState(() {
                    if (_chatOpen) {
                      _chatOpen = false;
                    } else {
                      _clearSelection();
                    }
                  });
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: [
                  Column(
                    children: [
                      _header(context),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.md,
                            0,
                            Space.md,
                            Space.md,
                          ),
                          child: wide
                              ? _wideLayout(context)
                              : medium
                              ? _mediumLayout(context)
                              : _narrowLayout(context),
                        ),
                      ),
                    ],
                  ),
                  for (final p in _passes) _PassFlight(pass: p),
                  if (_toast != null)
                    Positioned(
                      top: 64,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _ToastView(_toast!, key: ValueKey(_toast)),
                      ),
                    ),
                  if (_chatOpen && !wide) _chatSheet(context),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: wide || _chatOpen
          ? null
          : Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              backgroundColor: c.accent,
              textColor: c.onAccent,
              child: FloatingActionButton.small(
                key: const Key('game-chat-fab'),
                heroTag: null,
                backgroundColor: c.surfaceRaised,
                foregroundColor: c.text,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: BorderSide(color: c.outline),
                ),
                onPressed: () => setState(() {
                  _chatOpen = true;
                  _unread = 0;
                }),
                child: const Icon(Icons.forum_outlined),
              ),
            ),
    );
  }

  Widget _header(BuildContext context) {
    final c = context.colors;
    final room = client.room!;
    final drawPending = game.drawOffers.isNotEmpty;
    final myDraw = mySeat != null && game.drawOffers.contains(mySeat);
    final opponentsDraw =
        mySeat != null && game.drawOffers.any((s) => s.team != mySeat!.team);
    final narrow = MediaQuery.sizeOf(context).width < 640;
    final drawLabel = opponentsDraw && !myDraw
        ? 'Accept draw'
        : myDraw
        ? 'Withdraw draw'
        : (drawPending ? 'Draw offered' : 'Offer draw');
    void onDraw() => client.draw(
      opponentsDraw && !myDraw ? 'accept' : (myDraw ? 'decline' : 'offer'),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.sm,
        Space.xs,
        Space.sm,
        Space.xs,
      ),
      child: Row(
        children: [
          const SizedBox(width: Space.xs),
          const SwapmateMark(size: 24),
          const SizedBox(width: Space.sm),
          Text('Swapmate', style: context.type.titleMedium),
          const SizedBox(width: Space.md),
          Chip2(room.code, icon: Icons.tag, dense: true),
          if (!narrow) ...[
            const SizedBox(width: Space.xs),
            Chip2(
              room.timeControl.label,
              icon: Icons.timer_outlined,
              dense: true,
            ),
          ],
          if (spectating) ...[
            const SizedBox(width: Space.xs),
            Chip2(
              'Spectating',
              icon: Icons.visibility_outlined,
              dense: true,
              color: c.accent,
              background: c.accentSoft,
            ),
          ],
          const Spacer(),
          if (narrow) ...[
            StatusPill(client, compact: true),
            PopupMenuButton<String>(
              key: const Key('game-menu'),
              tooltip: 'Game menu',
              icon: const Icon(Icons.more_horiz),
              onSelected: (v) => switch (v) {
                'draw' => onDraw(),
                'resign' => _confirmResign(),
                'leave' => client.leaveRoom(),
                _ => widget.onToggleTheme(),
              },
              itemBuilder: (_) => [
                if (!spectating && !game.isOver) ...[
                  PopupMenuItem(
                    value: 'draw',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.handshake_outlined),
                      title: Text(drawLabel),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'resign',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.flag_outlined, color: c.danger),
                      title: Text('Resign', style: TextStyle(color: c.danger)),
                    ),
                  ),
                ],
                if (spectating)
                  const PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.logout),
                      title: Text('Leave'),
                    ),
                  ),
                PopupMenuItem(
                  value: 'theme',
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      c.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    title: Text(c.isDark ? 'Light theme' : 'Dark theme'),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (!spectating && !game.isOver) ...[
              if (opponentsDraw && !myDraw)
                TextButton.icon(
                  onPressed: onDraw,
                  icon: Icon(
                    Icons.handshake_outlined,
                    size: 16,
                    color: c.accent,
                  ),
                  label: Text(drawLabel, style: TextStyle(color: c.accent)),
                )
              else
                TextButton(
                  key: const Key('game-draw'),
                  onPressed: onDraw,
                  child: Text(drawLabel),
                ),
              TextButton(
                key: const Key('game-resign'),
                onPressed: _confirmResign,
                style: TextButton.styleFrom(foregroundColor: c.danger),
                child: const Text('Resign'),
              ),
            ],
            if (spectating)
              TextButton(
                onPressed: client.leaveRoom,
                child: const Text('Leave'),
              ),
            const SizedBox(width: Space.xs),
            StatusPill(client),
            IconButton(
              tooltip: c.isDark ? 'Light theme' : 'Dark theme',
              onPressed: widget.onToggleTheme,
              icon: Icon(
                c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 11,
        child: _boardColumn(context, mainBoard, primary: true),
      ),
      const SizedBox(width: Space.lg),
      Expanded(
        flex: 8,
        child: _boardColumn(context, mainBoard.other, primary: false),
      ),
      const SizedBox(width: Space.lg),
      SizedBox(
        width: 300,
        child: Column(
          children: [
            Expanded(flex: 4, child: MoveList(moves: game.moves)),
            const SizedBox(height: Space.md),
            Expanded(flex: 5, child: ChatPanel(client: client)),
          ],
        ),
      ),
    ],
  );

  Widget _mediumLayout(BuildContext context) => Column(
    children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: _boardColumn(context, mainBoard, primary: true),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              flex: 8,
              child: _boardColumn(context, mainBoard.other, primary: false),
            ),
          ],
        ),
      ),
      if (!spectating) ...[
        const SizedBox(height: Space.xs),
        QuickChatStrip(onSend: client.quickChat, compact: true),
      ],
    ],
  );

  Widget _narrowLayout(BuildContext context) {
    final partner = mainBoard.other;
    return Column(
      children: [
        _miniBoardRow(context, partner),
        const SizedBox(height: Space.sm),
        Expanded(
          child: _boardColumn(context, mainBoard, primary: true, dense: true),
        ),
        if (!spectating) ...[
          const SizedBox(height: Space.xs),
          QuickChatStrip(onSend: client.quickChat, compact: true),
        ],
      ],
    );
  }

  /// Partner board shown small next to its clocks and reserves (phones).
  /// The row takes the height of the two player bars; the board fits it.
  Widget _miniBoardRow(BuildContext context, BoardId b) {
    final snap = game.boards[b]!;
    final pos = snap.position;
    final orient = orientationFor(b);
    final top = Seat.at(b, orient.opposite);
    final bottom = Seat.at(b, orient);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _framedBoard(
              b,
              BoardView(
                key: _boardKeys[b],
                position: pos,
                orientation: orient,
                boardId: b,
                lastMove: snap.lastMove,
                inCheck: snap.inCheck,
                showCoordinates: false,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _playerBar(context, top, snap, compact: true),
                const SizedBox(height: Space.xs),
                _playerBar(context, bottom, snap, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardColumn(
    BuildContext context,
    BoardId b, {
    required bool primary,
    bool dense = false,
  }) {
    final snap = game.boards[b]!;
    final pos = snap.position;
    final orient = orientationFor(b);
    final top = Seat.at(b, orient.opposite);
    final bottom = Seat.at(b, orient);
    final interactive = primary && !spectating && !game.isOver;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _playerBar(context, top, snap, dense: dense),
        const SizedBox(height: Space.sm),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: _framedBoard(
                b,
                BoardView(
                  key: _boardKeys[b],
                  position: pos,
                  orientation: orient,
                  boardId: b,
                  lastMove: snap.lastMove,
                  premove: primary ? game.premove : null,
                  selected: primary ? _selected : null,
                  targets: primary ? _targets : const {},
                  inCheck: snap.inCheck,
                  interactive: interactive,
                  onSquareTap: interactive ? _tapSquare : null,
                  onDragMove: interactive ? _tryMove : null,
                  onReserveDrop: interactive
                      ? (t, sq) => _submit(Move.drop(t, sq))
                      : null,
                  dropTargets: primary ? _dropTargets : const {},
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.sm),
        _playerBar(context, bottom, snap, dense: dense),
      ],
    );
  }

  Widget _framedBoard(BoardId b, Widget board) {
    final c = context.colors;
    final snap = game.boards[b]!;
    final over = game.isOver;
    final decided = over && game.result?.board == b;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.boardFrame,
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
        border: decided ? Border.all(color: c.accent, width: 2) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Stack(
          children: [
            Positioned.fill(child: board),
            if (over && snap.running == null && decided)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: c.accent.withValues(alpha: 0.9),
                  alignment: Alignment.center,
                  child: Text(
                    'Match decided here',
                    style: context.type.labelMedium?.copyWith(
                      color: c.onAccent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _playerBar(
    BuildContext context,
    Seat seat,
    BoardSnapshot snap, {
    bool compact = false,
    bool dense = false,
  }) {
    final c = context.colors;
    final room = client.room!;
    final p = room.seated(seat);
    final isMe = seat == mySeat;
    final isPartner = mySeat != null && seat == mySeat!.partner;
    final toMove = !game.isOver && snap.position.turn == seat.color;
    final reserve = snap.position.reserve(seat.color);
    final teamColor = c.team(seat.team);
    final label = isMe ? 'You' : (isPartner ? 'Partner' : null);
    return AnimatedContainer(
      duration: Motion.base,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.sm : (dense ? Space.sm : Space.md),
        vertical: compact || dense ? Space.xs : Space.sm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: toMove ? teamColor.withValues(alpha: 0.7) : c.outline,
          width: toMove ? 1.5 : 1,
        ),
      ),
      child: compact
          ? Row(
              children: [
                Avatar(
                  name: p?.name ?? '—',
                  team: seat.team,
                  size: 22,
                  isBot: p?.isBot ?? false,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p?.name ?? 'Empty',
                        overflow: TextOverflow.ellipsis,
                        style: context.type.labelMedium,
                      ),
                      ReserveTray(
                        trayKey: _trayKeys[seat],
                        reserve: reserve,
                        color: seat.color,
                        boardId: seat.board,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.xs),
                ClockView(
                  snapshot: snap,
                  color: seat.color,
                  sampledAt: game.serverTime,
                  serverNow: () => client.serverNow,
                  compact: true,
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, box) {
                final stacked = box.maxWidth < 440;
                final tray = ReserveTray(
                  trayKey: _trayKeys[seat],
                  reserve: reserve,
                  color: seat.color,
                  boardId: seat.board,
                  interactive: isMe && !game.isOver,
                  selected: isMe ? _selectedReserve : null,
                  onSelect: isMe ? _selectReserve : null,
                  dense: dense,
                );
                final identity = Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p?.name ?? 'Empty seat',
                              overflow: TextOverflow.ellipsis,
                              style: context.type.titleMedium,
                            ),
                          ),
                          if (label != null) ...[
                            const SizedBox(width: Space.xs),
                            Chip2(
                              label,
                              dense: true,
                              color: teamColor,
                              background: c.teamSoft(seat.team),
                            ),
                          ],
                          if (p != null && !p.connected && !p.isBot) ...[
                            const SizedBox(width: Space.xs),
                            Chip2(
                              'Reconnecting',
                              dense: true,
                              color: c.warning,
                              icon: Icons.wifi_off,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            platformIcon(p?.platform),
                            size: 12,
                            color: c.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p == null
                                ? ''
                                : (p.isBot ? 'Bot' : platformLabel(p.platform)),
                            style: context.type.bodySmall?.copyWith(
                              color: c.textFaint,
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Text(
                            toMove ? 'to move' : '',
                            style: context.type.labelSmall?.copyWith(
                              color: teamColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                final clock = ClockView(
                  snapshot: snap,
                  color: seat.color,
                  sampledAt: game.serverTime,
                  serverNow: () => client.serverNow,
                  isMine: isMe,
                );
                final avatar = Avatar(
                  name: p?.name ?? '—',
                  team: seat.team,
                  size: 34,
                  isBot: p?.isBot ?? false,
                );
                if (stacked) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          avatar,
                          const SizedBox(width: Space.sm),
                          identity,
                          const SizedBox(width: Space.sm),
                          clock,
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      SizedBox(width: double.infinity, child: tray),
                    ],
                  );
                }
                return Row(
                  children: [
                    avatar,
                    const SizedBox(width: Space.sm),
                    identity,
                    const SizedBox(width: Space.sm),
                    Flexible(flex: 0, child: tray),
                    const SizedBox(width: Space.sm),
                    clock,
                  ],
                );
              },
            ),
    );
  }

  Widget _chatSheet(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _chatOpen = false),
        child: Container(
          color: c.shadow.withValues(alpha: 0.4),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: MoveList(moves: game.moves, dense: true),
                      ),
                      const SizedBox(height: Space.sm),
                      Expanded(
                        flex: 3,
                        child: ChatPanel(client: client, compact: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast {
  const _Toast(this.text, this.danger);
  final String text;
  final bool danger;
}

class _ToastView extends StatelessWidget {
  const _ToastView(this.toast, {super.key});
  final _Toast toast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.base,
      curve: Motion.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -8),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: toast.danger ? c.danger : c.surfaceRaised,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: toast.danger ? c.danger : c.outlineStrong),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          toast.text,
          style: context.type.labelLarge?.copyWith(
            color: toast.danger ? Colors.white : c.text,
          ),
        ),
      ),
    );
  }
}

class _Pass {
  _Pass(this.piece, this.from, this.to, this.size);
  final Piece piece;
  final Offset from;
  final Offset to;
  final double size;
}

/// A captured piece arcing from the capture square to the partner's tray.
class _PassFlight extends StatelessWidget {
  const _PassFlight({required this.pass});
  final _Pass pass;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.pass,
    curve: Motion.emphasized,
    builder: (context, t, _) {
      final p = Offset.lerp(pass.from, pass.to, t)!;
      final lift = -120 * (4 * t * (1 - t));
      final scale = 1.35 - 0.7 * t;
      final size = pass.size * scale;
      return Positioned(
        left: p.dx - size / 2,
        top: p.dy + lift - size / 2,
        child: IgnorePointer(
          child: Opacity(
            opacity: t > 0.9 ? (1 - t) * 10 : 1,
            child: PieceGlyph(pass.piece, size: size),
          ),
        ),
      );
    },
  );
}
