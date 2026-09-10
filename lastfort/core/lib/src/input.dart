import 'constants.dart';

/// Discrete actions carried inside an [InputFrame].
enum ActionType {
  jump,
  select,
  buildMode,
  setPiece,
  setMaterial,
  place,
  edit,
  interact,
  use,
  drop,
  reload,
  emote,
  spectateNext,
  thank,
}

class GameAction {
  const GameAction(this.type,
      {this.slot = 0, this.value = '', this.gx, this.gy});

  final ActionType type;
  final int slot;
  final String value;
  final int? gx;
  final int? gy;

  Map<String, Object?> toJson() => {
        't': type.name,
        if (slot != 0) 's': slot,
        if (value.isNotEmpty) 'v': value,
        if (gx != null) 'gx': gx,
        if (gy != null) 'gy': gy,
      };

  static GameAction fromJson(Map<String, Object?> j) => GameAction(
        ActionType.values.byName(j['t'] as String),
        slot: (j['s'] as num? ?? 0).toInt(),
        value: j['v'] as String? ?? '',
        gx: (j['gx'] as num?)?.toInt(),
        gy: (j['gy'] as num?)?.toInt(),
      );

  Piece? get piece => value.isEmpty ? null : Piece.values.asNameMap()[value];
  Material? get material =>
      value.isEmpty ? null : Material.values.asNameMap()[value];
  PieceEdit? get pieceEdit =>
      value.isEmpty ? null : PieceEdit.values.asNameMap()[value];
}

/// One tick of player intent. `seq` lets the client reconcile prediction.
class InputFrame {
  const InputFrame({
    required this.seq,
    this.moveX = 0,
    this.moveY = 0,
    this.aim = 0,
    this.fire = false,
    this.sprint = false,
    this.actions = const [],
  });

  final int seq;
  final double moveX;
  final double moveY;
  final double aim;
  final bool fire;
  final bool sprint;
  final List<GameAction> actions;

  Map<String, Object?> toJson() => {
        'seq': seq,
        'mx': double.parse(moveX.toStringAsFixed(3)),
        'my': double.parse(moveY.toStringAsFixed(3)),
        'aim': double.parse(aim.toStringAsFixed(3)),
        if (fire) 'fire': true,
        if (sprint) 'sprint': true,
        if (actions.isNotEmpty) 'act': [for (final a in actions) a.toJson()],
      };

  static InputFrame fromJson(Map<String, Object?> j) => InputFrame(
        seq: (j['seq'] as num? ?? 0).toInt(),
        moveX: (j['mx'] as num? ?? 0).toDouble().clamp(-1, 1),
        moveY: (j['my'] as num? ?? 0).toDouble().clamp(-1, 1),
        aim: (j['aim'] as num? ?? 0).toDouble(),
        fire: j['fire'] == true,
        sprint: j['sprint'] == true,
        actions: [
          for (final a in (j['act'] as List<Object?>? ?? const []))
            GameAction.fromJson(a as Map<String, Object?>),
        ],
      );
}
