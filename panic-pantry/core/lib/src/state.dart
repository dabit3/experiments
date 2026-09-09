import 'items.dart';
import 'levels.dart';
import 'tiles.dart';

/// Per-tick controller state for one chef. Bots and humans produce the same shape.
class ChefInput {
  const ChefInput({
    this.dx = 0,
    this.dy = 0,
    this.interact = false,
    this.action = false,
    this.dash = false,
    this.emote,
    this.targetX,
    this.targetY,
  });

  static const none = ChefInput();

  /// Movement axis values in -1..1.
  final double dx;
  final double dy;

  /// Pick up / drop (edge triggered).
  final bool interact;

  /// Chop / spray (held).
  final bool action;

  /// Dash (edge triggered).
  final bool dash;

  /// Emote index (edge triggered), see [kEmotes].
  final int? emote;

  /// Tile the client believed it was facing when [interact] was pressed.
  /// Lets the server honour a pickup even if the chef has drifted a little.
  final int? targetX;
  final int? targetY;

  bool get isIdle => dx == 0 && dy == 0 && !interact && !action && !dash && emote == null;

  Map<String, dynamic> toJson() => {
    if (dx != 0) 'dx': _r(dx),
    if (dy != 0) 'dy': _r(dy),
    if (interact) 'i': true,
    if (action) 'a': true,
    if (dash) 'd': true,
    if (emote != null) 'e': emote,
    if (targetX != null) 'tx': targetX,
    if (targetY != null) 'ty': targetY,
  };

  static ChefInput fromJson(Map<String, dynamic> json) => ChefInput(
    dx: ((json['dx'] ?? 0) as num).toDouble().clamp(-1, 1),
    dy: ((json['dy'] ?? 0) as num).toDouble().clamp(-1, 1),
    interact: json['i'] == true,
    action: json['a'] == true,
    dash: json['d'] == true,
    emote: json['e'] as int?,
    targetX: json['tx'] as int?,
    targetY: json['ty'] as int?,
  );

  ChefInput copyWith({double? dx, double? dy, bool? interact, bool? action, bool? dash, int? emote}) => ChefInput(
    dx: dx ?? this.dx,
    dy: dy ?? this.dy,
    interact: interact ?? this.interact,
    action: action ?? this.action,
    dash: dash ?? this.dash,
    emote: emote ?? this.emote,
    targetX: targetX,
    targetY: targetY,
  );
}

/// Quick-communication pings shown as speech bubbles.
const List<String> kEmotes = ['Plate!', 'Chop!', 'Fire!', 'Nice!', 'Help!', 'Serve!'];

class Chef {
  Chef({required this.id, required this.slot, required this.name, required this.x, required this.y, this.bot = false});

  final String id;

  /// 0..3, decides colour.
  final int slot;
  final String name;
  final bool bot;

  double x;
  double y;
  Dir facing = Dir.down;
  Item? held;

  /// Remaining dash time and cooldown in seconds.
  double dash = 0;
  double dashCooldown = 0;

  /// Movement speed multiplier applied by dashing.
  double get speedMultiplier => dash > 0 ? 2.6 : 1;

  /// Whether the chef is currently chopping / washing / spraying.
  bool working = false;

  int? emote;
  double emoteTtl = 0;

  bool connected = true;

  int get tileX => x.floor();
  int get tileY => y.floor();

  Map<String, dynamic> toJson() => {
    'id': id,
    's': slot,
    'n': name,
    'b': bot,
    'x': _r(x),
    'y': _r(y),
    'f': facing.index,
    if (held != null) 'h': held!.toJson(),
    if (dash > 0) 'd': _r(dash),
    if (working) 'w': true,
    if (emote != null) 'e': emote,
    if (!connected) 'off': true,
  };

  static Chef fromJson(Map<String, dynamic> json) {
    final c = Chef(
      id: json['id'] as String,
      slot: json['s'] as int,
      name: json['n'] as String,
      bot: json['b'] == true,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
    c.facing = Dir.values[json['f'] as int];
    c.held = json['h'] == null ? null : Item.fromJson(json['h'] as Map<String, dynamic>);
    c.dash = ((json['d'] ?? 0) as num).toDouble();
    c.working = json['w'] == true;
    c.emote = json['e'] as int?;
    c.connected = json['off'] != true;
    return c;
  }
}

class Order {
  Order({required this.id, required this.dish, required this.remaining, required this.duration});

  final int id;
  final Dish dish;
  double remaining;
  final double duration;

  double get fraction => (remaining / duration).clamp(0, 1);

  Map<String, dynamic> toJson() => {'id': id, 'd': dish.name, 'r': _r(remaining), 'u': duration};

  static Order fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int,
    dish: Dish.parse(json['d'] as String),
    remaining: (json['r'] as num).toDouble(),
    duration: (json['u'] as num).toDouble(),
  );
}

enum Phase { lobby, countdown, playing, overtime, finished }

/// One-shot happenings since the last snapshot; clients turn them into effects.
class GameEvent {
  const GameEvent(this.kind, {this.x, this.y, this.chef, this.value, this.text});

  /// served, expired, burnt, fire, extinguished, chopped, cooked, plated, washed, dash, emote, wrong
  final String kind;
  final int? x;
  final int? y;
  final String? chef;
  final int? value;
  final String? text;

  Map<String, dynamic> toJson() => {
    'k': kind,
    if (x != null) 'x': x,
    if (y != null) 'y': y,
    if (chef != null) 'c': chef,
    if (value != null) 'v': value,
    if (text != null) 't': text,
  };

  static GameEvent fromJson(Map<String, dynamic> j) => GameEvent(
    j['k'] as String,
    x: j['x'] as int?,
    y: j['y'] as int?,
    chef: j['c'] as String?,
    value: j['v'] as int?,
    text: j['t'] as String?,
  );
}

/// Complete kitchen state. Mutated in place by the simulation; serialised as a
/// snapshot for clients, which rebuild it with [GameState.applySnapshot].
class GameState {
  GameState(this.level, {required this.playerCount}) {
    for (var y = 0; y < level.height; y++) {
      final row = level.rows[y];
      for (var x = 0; x < level.width; x++) {
        final c = row[x];
        final tile = tileFromChar(c);
        if (c == 'E') tile.item = const Extinguisher();
        if (c == 'S') tile.item = Pot();
        if (c == 'R') tile.item = PlateStack(count: level.startingPlates, dirty: false);
        if (c.codeUnitAt(0) >= 0x31 && c.codeUnitAt(0) <= 0x34) {
          spawns[int.parse(c) - 1] = (x + 0.5, y + 0.5);
        }
        _base.add(tile);
      }
    }
    for (final m in level.movers) {
      final cells = <Tile>[];
      for (var y = 0; y < m.height; y++) {
        for (var x = 0; x < m.width; x++) {
          final c = m.rows[y][x];
          final tile = c == '.' || (c.codeUnitAt(0) >= 0x31 && c.codeUnitAt(0) <= 0x34)
              ? Tile(TileType.platform)
              : tileFromChar(c);
          if (c == 'E') tile.item = const Extinguisher();
          if (c == 'S') tile.item = Pot();
          if (c == 'R') tile.item = PlateStack(count: level.startingPlates, dirty: false);
          if (c.codeUnitAt(0) >= 0x31 && c.codeUnitAt(0) <= 0x34) {
            spawns[int.parse(c) - 1] = (m.x + x + 0.5, m.y + y + 0.5);
          }
          cells.add(tile);
        }
      }
      moverTiles.add(cells);
      moverOffsets.add(0);
    }
  }

  final LevelDef level;
  final int playerCount;

  final List<Tile> _base = [];
  final List<List<Tile>> moverTiles = [];

  /// Current continuous offsets for each mover, in cells.
  final List<double> moverOffsets = [];

  final Map<int, (double, double)> spawns = {};
  final List<Chef> chefs = [];
  final List<Order> orders = [];
  final List<GameEvent> events = [];

  /// Plates that were served and will return dirty: seconds remaining for each.
  final List<double> plateReturns = [];

  Phase phase = Phase.lobby;
  int tick = 0;
  double time = 0;
  double countdown = 0;
  double timeLeft = 0;
  double overtimeLeft = 0;
  double nextOrderIn = 0;
  int nextOrderId = 1;

  int score = 0;
  int combo = 1;
  int bestCombo = 1;
  int served = 0;
  int expired = 0;
  int tips = 0;
  int wrongServes = 0;
  int burntPots = 0;
  final Map<String, int> servedByDish = {};

  int get width => level.width;
  int get height => level.height;

  bool get running => phase == Phase.playing || phase == Phase.overtime;

  List<int> get thresholds => level.thresholdsFor(playerCount);
  int get stars => LevelDef.starsFor(score, thresholds);

  Tile? baseTile(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    return _base[y * width + x];
  }

  /// Integer cell offset of mover [i].
  int moverCell(int i) => moverOffsets[i].round();

  /// Tile at world cell ([x], [y]) including mover tiles at their current cell.
  Tile? tileAt(int x, int y) {
    for (var i = 0; i < level.movers.length; i++) {
      final m = level.movers[i];
      final off = moverCell(i);
      final mx = m.x + (m.axis == 'x' ? off : 0);
      final my = m.y + (m.axis == 'y' ? off : 0);
      if (x >= mx && x < mx + m.width && y >= my && y < my + m.height) {
        return moverTiles[i][(y - my) * m.width + (x - mx)];
      }
    }
    return baseTile(x, y);
  }

  /// Index of the mover whose tiles cover ([x],[y]) or -1.
  int moverAt(int x, int y) {
    for (var i = 0; i < level.movers.length; i++) {
      final m = level.movers[i];
      final off = moverCell(i);
      final mx = m.x + (m.axis == 'x' ? off : 0);
      final my = m.y + (m.axis == 'y' ? off : 0);
      if (x >= mx && x < mx + m.width && y >= my && y < my + m.height) return i;
    }
    return -1;
  }

  bool walkable(int x, int y) => tileAt(x, y)?.type.walkable ?? false;

  /// Whether ([x],[y]) is walkable now or at either end of any mover's travel.
  /// Used by bots to plan routes that wait for moving platforms.
  bool walkableAny(int x, int y) {
    if (walkable(x, y)) return true;
    for (var i = 0; i < level.movers.length; i++) {
      final m = level.movers[i];
      for (final off in [0, m.range]) {
        final mx = m.x + (m.axis == 'x' ? off : 0);
        final my = m.y + (m.axis == 'y' ? off : 0);
        if (x >= mx && x < mx + m.width && y >= my && y < my + m.height) {
          if (moverTiles[i][(y - my) * m.width + (x - mx)].type.walkable) return true;
        }
      }
    }
    return false;
  }

  Iterable<(int, int, Tile)> allTiles() sync* {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final t = tileAt(x, y);
        if (t != null) yield (x, y, t);
      }
    }
  }

  Chef? chefById(String id) {
    for (final c in chefs) {
      if (c.id == id) return c;
    }
    return null;
  }

  Map<String, dynamic> toSnapshot({bool includeEvents = true}) {
    final tiles = <String, dynamic>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final t = _base[y * width + x];
        final j = t.toJson();
        if (j.isNotEmpty) tiles['$x,$y'] = j;
      }
    }
    final movers = <List<Map<String, dynamic>>>[];
    for (final cells in moverTiles) {
      movers.add(cells.map((t) => t.toJson()).toList());
    }
    return {
      'tick': tick,
      'time': _r(time),
      'phase': phase.name,
      'countdown': _r(countdown),
      'timeLeft': _r(timeLeft),
      'overtime': _r(overtimeLeft),
      'score': score,
      'combo': combo,
      'served': served,
      'expired': expired,
      'tiles': tiles,
      'movers': movers,
      'offsets': moverOffsets.map(_r).toList(),
      'chefs': chefs.map((c) => c.toJson()).toList(),
      'orders': orders.map((o) => o.toJson()).toList(),
      if (includeEvents && events.isNotEmpty) 'events': events.map((e) => e.toJson()).toList(),
    };
  }

  /// Rebuild this state from a server snapshot. Chef objects are replaced.
  void applySnapshot(Map<String, dynamic> s) {
    tick = s['tick'] as int;
    time = (s['time'] as num).toDouble();
    phase = Phase.values.byName(s['phase'] as String);
    countdown = (s['countdown'] as num).toDouble();
    timeLeft = (s['timeLeft'] as num).toDouble();
    overtimeLeft = (s['overtime'] as num).toDouble();
    score = s['score'] as int;
    combo = s['combo'] as int;
    served = s['served'] as int;
    expired = s['expired'] as int;
    final tiles = s['tiles'] as Map<String, dynamic>;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final t = _base[y * width + x];
        final j = tiles['$x,$y'];
        if (j == null) {
          t.item = null;
          t.progress = 0;
          t.conveyor = 0;
          t.fire = 0;
        } else {
          t.applyJson(j as Map<String, dynamic>);
        }
      }
    }
    final movers = s['movers'] as List;
    for (var i = 0; i < moverTiles.length && i < movers.length; i++) {
      final cells = movers[i] as List;
      for (var k = 0; k < cells.length && k < moverTiles[i].length; k++) {
        moverTiles[i][k].applyJson(cells[k] as Map<String, dynamic>);
      }
    }
    final offsets = s['offsets'] as List;
    for (var i = 0; i < moverOffsets.length && i < offsets.length; i++) {
      moverOffsets[i] = (offsets[i] as num).toDouble();
    }
    chefs
      ..clear()
      ..addAll((s['chefs'] as List).map((c) => Chef.fromJson(c as Map<String, dynamic>)));
    orders
      ..clear()
      ..addAll((s['orders'] as List).map((o) => Order.fromJson(o as Map<String, dynamic>)));
    events
      ..clear()
      ..addAll(((s['events'] ?? const []) as List).map((e) => GameEvent.fromJson(e as Map<String, dynamic>)));
  }

  Map<String, dynamic> results() => {
    'levelId': level.id,
    'score': score,
    'stars': stars,
    'thresholds': thresholds,
    'served': served,
    'expired': expired,
    'tips': tips,
    'bestCombo': bestCombo,
    'wrongServes': wrongServes,
    'burntPots': burntPots,
    'servedByDish': servedByDish,
    'players': playerCount,
    'tick': tick,
  };
}

double _r(double v) => (v * 1000).round() / 1000;
