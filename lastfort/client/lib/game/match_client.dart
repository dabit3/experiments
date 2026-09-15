import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:lastfort_core/lastfort_core.dart';

/// A short-lived visual effect derived from a server event.
class Vfx {
  Vfx(
    this.kind,
    this.x,
    this.y, {
    this.x2 = 0,
    this.y2 = 0,
    this.value = 0,
    this.color = 0,
    this.ttl = 0.35,
  }) : age = 0;
  final String kind;
  final double x;
  final double y;
  final double x2;
  final double y2;
  final int value;
  final int color;
  final double ttl;
  double age;
  double get t => (age / ttl).clamp(0, 1);
  bool get dead => age >= ttl;
}

class FeedEntry {
  FeedEntry(this.text, this.accent, this.createdAt, {this.highlight = false});
  final String text;
  final int accent;
  final double createdAt;
  final bool highlight;
}

class _Predicted {
  _Predicted(this.seq, this.x, this.y, this.frame);
  final int seq;
  final double x;
  final double y;
  final InputFrame frame;
}

/// Smoothed presentation of a remote player between 20 Hz snapshots.
class RemoteView {
  double x = 0, y = 0, aim = 0;
  double fromX = 0, fromY = 0, fromAim = 0;
  double toX = 0, toY = 0, toAim = 0;
  double t = 1;
}

/// Client-side match state: a [Sim] replica fed by server snapshots, local
/// movement prediction with reconciliation, remote interpolation, event feed
/// and VFX. Rendering and HUD read from this object; input writes to it.
class MatchClient extends ChangeNotifier {
  MatchClient({required Map<String, Object?> start, required this.localName}) {
    rules = Rules.fromJson(start['rules'] as Map<String, Object?>);
    seed = (start['seed'] as num).toInt();
    mode = SquadMode.parse(start['mode'] as String);
    code = start['code'] as String? ?? '';
    sim = Sim(rules: rules, seed: seed, mode: mode);
    for (final pj in start['players'] as List<Object?>) {
      final j = pj as Map<String, Object?>;
      final p = sim.addPlayer(
        id: (j['id'] as num).toInt(),
        name: j['n'] as String,
        team: (j['t'] as num).toInt(),
        isBot: j['b'] as bool,
        loadout: Loadout.fromJson(j['ld'] as Map<String, Object?>?),
        platform: j['p'] as String,
      );
      p.applySnapshotJson(j);
    }
    resumed = start['resume'] == true;
    sim.phase = MatchPhase.bus;
  }

  late final Rules rules;
  late final int seed;
  late final SquadMode mode;
  late final String code;
  late final Sim sim;
  final String localName;
  bool resumed = false;

  int localId = 0;
  Player? get me => sim.players[localId];

  /// Player whose viewpoint the camera follows (self, or spectated target).
  Player? get viewTarget {
    final m = me;
    if (m == null) return null;
    if (m.eliminated && m.spectating != 0)
      return sim.players[m.spectating] ?? m;
    return m;
  }

  int snapshotsReceived = 0;
  int lastServerTick = 0;
  int playersLeft = 0;
  int teamsLeft = 0;
  double serverTimeSeconds = 0;
  Map<String, Object?>? summary;
  bool get ended => sim.phase == MatchPhase.ended;

  final List<Vfx> vfx = [];
  final ListQueue<FeedEntry> feed = ListQueue();
  final Map<int, RemoteView> remotes = {};
  final Set<int> hiddenStructureIds = {};

  // Prediction.
  int _seq = 0;
  final ListQueue<_Predicted> _history = ListQueue();
  int reconciliations = 0;
  double lastCorrection = 0;

  // Camera shake and hit flash for feedback.
  double shake = 0;
  double hitFlash = 0;
  double damageFlash = 0;
  double stormPulse = 0;
  int lastHitTick = -1000;

  /// Seconds until the bus auto-drops everyone still aboard (server-replicated).
  double get busSecondsLeft => sim.replicatedBusRemaining;

  /// Player id → name lookup for the feed.
  String nameOf(int id) =>
      sim.players[id]?.name ?? (id == 0 ? 'the storm' : '#$id');

  /// Builds the frame for this tick, applies prediction and returns the JSON
  /// message to send. [move] is a unit vector, [aim] radians.
  Map<String, Object?>? buildInput({
    required double moveX,
    required double moveY,
    required double aim,
    required bool fire,
    required bool sprint,
    required List<GameAction> actions,
  }) {
    final m = me;
    if (m == null || ended) return null;
    _seq++;
    final f = InputFrame(
      seq: _seq,
      moveX: moveX,
      moveY: moveY,
      aim: aim,
      fire: fire,
      sprint: sprint,
      actions: actions,
    );
    if (m.alive && m.connected) {
      m.aim = aim;
      final r = sim.movePlayer(m, moveX, moveY, sprint, sim.dt);
      m.x = r.x;
      m.y = r.y;
      m.moveX = moveX;
      m.moveY = moveY;
      m.sprint = sprint;
      _history.add(_Predicted(_seq, m.x, m.y, f));
      while (_history.length > 64) {
        _history.removeFirst();
      }
    }
    return {'t': Protocol.input, 'f': f.toJson()};
  }

  void setLocalId(int id) {
    localId = id;
    notifyListeners();
  }

  void applySnapshot(Map<String, Object?> snap) {
    snapshotsReceived++;
    final tick = (snap['tick'] as num).toInt();
    lastServerTick = tick;
    serverTimeSeconds = tick * sim.dt;
    final matchJson = snap['match'] as Map<String, Object?>;
    playersLeft = (matchJson['alive'] as num? ?? 0).toInt();
    teamsLeft = (matchJson['teamsAlive'] as num? ?? 0).toInt();

    // Remember where remotes were for interpolation.
    for (final p in sim.players.values) {
      if (p.id == localId) continue;
      final rv = remotes.putIfAbsent(p.id, RemoteView.new);
      rv.fromX = rv.x;
      rv.fromY = rv.y;
      rv.fromAim = rv.aim;
    }

    // Server position for the local player (before applySnapshot skips it).
    double? sx, sy;
    int ackSeq = 0;
    String? sState;
    for (final pj in snap['players'] as List<Object?>) {
      final j = pj as Map<String, Object?>;
      if ((j['id'] as num).toInt() == localId) {
        sx = (j['x'] as num).toDouble();
        sy = (j['y'] as num).toDouble();
        ackSeq = (j['seq'] as num? ?? 0).toInt();
        sState = j['s'] as String?;
      }
    }

    sim.applySnapshot(snap, localId: localId);

    for (final p in sim.players.values) {
      if (p.id == localId) continue;
      final rv = remotes[p.id]!;
      if (rv.fromX == 0 && rv.fromY == 0) {
        rv.fromX = p.x;
        rv.fromY = p.y;
        rv.fromAim = p.aim;
      }
      rv.toX = p.x;
      rv.toY = p.y;
      rv.toAim = p.aim;
      rv.t = 0;
    }

    final m = me;
    if (m != null && sx != null && sy != null) {
      final ownsPosition = sState == PlayerState.alive.name && m.connected;
      if (!ownsPosition) {
        // Bus / dropping / eliminated: server owns the position.
        m.x = sx;
        m.y = sy;
        _history.clear();
      } else {
        _reconcile(m, sx, sy, ackSeq);
      }
    }

    final ev = snap['ev'];
    if (ev is List<Object?>) {
      for (final e in ev) {
        _handleEvent(e as Map<String, Object?>);
      }
    }
    notifyListeners();
  }

  void _reconcile(Player m, double sx, double sy, int ackSeq) {
    while (_history.isNotEmpty && _history.first.seq < ackSeq) {
      _history.removeFirst();
    }
    if (_history.isEmpty || _history.first.seq != ackSeq) {
      // Nothing to compare against yet; trust the server if far off.
      final dx = m.x - sx;
      final dy = m.y - sy;
      if (dx * dx + dy * dy > 4) {
        m.x = sx;
        m.y = sy;
      }
      return;
    }
    final pred = _history.removeFirst();
    final dx = pred.x - sx;
    final dy = pred.y - sy;
    final err = math.sqrt(dx * dx + dy * dy);
    lastCorrection = err;
    if (err < 0.08) return;
    reconciliations++;
    // Rewind to the server state and replay unacknowledged inputs.
    m.x = sx;
    m.y = sy;
    for (final h in _history) {
      final r = sim.movePlayer(
        m,
        h.frame.moveX,
        h.frame.moveY,
        h.frame.sprint,
        sim.dt,
      );
      m.x = r.x;
      m.y = r.y;
    }
  }

  void _handleEvent(Map<String, Object?> e) {
    final type = e['e'] as String;
    final now = serverTimeSeconds;
    switch (type) {
      case 'shot':
        final pid = (e['p'] as num).toInt();
        final p = sim.players[pid];
        if (p == null) break;
        final shots = e['s'] as List<Object?>;
        for (final s in shots) {
          final j = s as Map<String, Object?>;
          final hit = (j['h'] as num).toInt();
          vfx.add(
            Vfx(
              'tracer',
              p.x,
              p.y,
              x2: (j['x'] as num).toDouble(),
              y2: (j['y'] as num).toDouble(),
              value: hit,
              color: pid == localId ? 0xFFFFE3A3 : 0xFFFFB3B3,
              ttl: 0.12,
            ),
          );
          if (hit != 0) {
            vfx.add(
              Vfx(
                'impact',
                (j['x'] as num).toDouble(),
                (j['y'] as num).toDouble(),
                color: hit == 1 ? 0xFFFF6B6B : 0xFFE0E6F0,
                ttl: 0.3,
              ),
            );
          }
        }
        if (pid == localId) shake = math.max(shake, 0.35);
      case 'hit':
        final target = (e['p'] as num).toInt();
        final by = (e['by'] as num).toInt();
        final d = (e['d'] as num).toInt();
        final sh = e['sh'] == true;
        vfx.add(
          Vfx(
            'damage',
            (e['x'] as num).toDouble(),
            (e['y'] as num).toDouble(),
            value: d,
            color: sh ? 0xFF4DA3FF : 0xFFFFFFFF,
            ttl: 0.9,
          ),
        );
        if (target == localId) {
          damageFlash = 1;
          shake = math.max(shake, 0.6);
          lastHitTick = lastServerTick;
        }
        if (by == localId) hitFlash = 1;
      case 'eliminated':
        final target = (e['p'] as num).toInt();
        final by = (e['by'] as num).toInt();
        final weapon = e['w'] as String? ?? '';
        final t = sim.players[target];
        final byName = by == 0 ? 'The storm' : nameOf(by);
        final verb = by == 0 ? 'claimed' : 'eliminated';
        final withText = weapon.isEmpty || by == 0 ? '' : ' ($weapon)';
        _feed(
          '$byName $verb ${nameOf(target)}$withText',
          by == localId
              ? 0xFF2FD3C6
              : (target == localId ? 0xFFFF4D5E : 0xFFEEF3FA),
          highlight: by == localId || target == localId,
        );
        if (t != null) {
          vfx.add(Vfx('elim', t.x, t.y, color: 0xFFFF7A2F, ttl: 1.2));
        }
      case 'placed':
        final pid = (e['p'] as num).toInt();
        final sj = e['s'] as Map<String, Object?>;
        vfx.add(
          Vfx(
            'build',
            sim.world.tileCenter((sj['gx'] as num).toInt()),
            sim.world.tileCenter((sj['gy'] as num).toInt()),
            color: 0xFF7FD6E8,
            ttl: 0.4,
          ),
        );
        if (pid == localId) shake = math.max(shake, 0.1);
      case 'swing':
        final pid = (e['p'] as num).toInt();
        final give = (e['g'] as num).toInt();
        final mat = e['m'] as String? ?? '';
        if (give > 0) {
          vfx.add(
            Vfx(
              'harvest',
              (e['x'] as num).toDouble(),
              (e['y'] as num).toDouble(),
              value: give,
              color: switch (mat) {
                'wood' => 0xFFB07A3C,
                'stone' => 0xFF9AA3AD,
                'metal' => 0xFF7FD6E8,
                _ => 0xFFFFFFFF,
              },
              ttl: 0.8,
            ),
          );
        } else {
          vfx.add(
            Vfx(
              'impact',
              (e['x'] as num).toDouble(),
              (e['y'] as num).toDouble(),
              color: 0x88FFFFFF,
              ttl: 0.2,
            ),
          );
        }
        if (pid == localId && give > 0) shake = math.max(shake, 0.12);
      case 'chest':
        final pid = (e['p'] as num).toInt();
        if (pid == localId) _feed('Chest opened', 0xFFFFB13D);
      case 'pickup':
        final pid = (e['p'] as num).toInt();
        if (pid == localId) {
          final item = Item.fromJson(e['item'] as Map<String, Object?>);
          _feed('Picked up ${item.label}', item.rarity.argb);
        }
      case 'stormHit':
        final pid = (e['p'] as num).toInt();
        if (pid == localId) {
          damageFlash = math.max(damageFlash, 0.6);
          stormPulse = 1;
        }
      case 'teamOut':
        final team = (e['team'] as num).toInt();
        final place = (e['place'] as num).toInt();
        if (me?.team == team) {
          _feed('Your squad placed #$place', 0xFFFFC857, highlight: true);
        }
      case 'landed':
        final pid = (e['p'] as num).toInt();
        final p = sim.players[pid];
        if (p != null)
          vfx.add(Vfx('land', p.x, p.y, color: 0xFFEEF3FA, ttl: 0.5));
      case 'busGone':
        _feed('The bus has left the island', 0xFF93A0B8);
      case 'reconnected':
        final pid = (e['p'] as num).toInt();
        if (pid != localId) _feed('${nameOf(pid)} reconnected', 0xFF93A0B8);
      case 'disconnected':
        final pid = (e['p'] as num).toInt();
        if (pid != localId) _feed('${nameOf(pid)} lost connection', 0xFF93A0B8);
      case 'nodeGone':
        break;
      case 'buildFailed':
        final pid = (e['p'] as num).toInt();
        if (pid == localId) _feed('Not enough materials', 0xFFFF4D5E);
      case 'matchEnd':
        break;
    }
    _trimFeed(now);
  }

  void _feed(String text, int accent, {bool highlight = false}) {
    feed.addFirst(
      FeedEntry(text, accent, serverTimeSeconds, highlight: highlight),
    );
    while (feed.length > 6) {
      feed.removeLast();
    }
  }

  void _trimFeed(double now) {
    feed.removeWhere((f) => now - f.createdAt > eliminationFeedTtl);
  }

  /// Advances presentation state (interpolation, VFX ageing) by [dt] seconds.
  void advance(double dt) {
    final step = dt / sim.dt;
    for (final rv in remotes.values) {
      rv.t = math.min(1, rv.t + step);
      rv.x = rv.fromX + (rv.toX - rv.fromX) * rv.t;
      rv.y = rv.fromY + (rv.toY - rv.fromY) * rv.t;
      rv.aim = _lerpAngle(rv.fromAim, rv.toAim, rv.t);
    }
    for (final v in vfx) {
      v.age += dt;
    }
    vfx.removeWhere((v) => v.dead);
    shake = math.max(0, shake - dt * 2.2);
    hitFlash = math.max(0, hitFlash - dt * 4);
    damageFlash = math.max(0, damageFlash - dt * 2.5);
    stormPulse = math.max(0, stormPulse - dt * 1.5);
    _trimFeed(serverTimeSeconds);
  }

  /// Whether [p] was included in a recent snapshot (interest managed).
  bool isVisible(Player p) =>
      p.id == localId || p.team == me?.team || sim.tick - p.lastSeenTick <= 2;

  /// Presentation position for any player (interpolated for remotes).
  ({double x, double y, double aim}) viewOf(Player p) {
    if (p.id == localId) return (x: p.x, y: p.y, aim: p.aim);
    final rv = remotes[p.id];
    if (rv == null || rv.t >= 1 && rv.toX == 0)
      return (x: p.x, y: p.y, aim: p.aim);
    return (x: rv.x, y: rv.y, aim: rv.aim);
  }

  void setSummary(Map<String, Object?> s) {
    summary = s;
    sim.phase = MatchPhase.ended;
    notifyListeners();
  }

  /// Deterministic short digest of the summary so screenshots on every
  /// platform can be compared at a glance.
  static String digest(Map<String, Object?> summary) {
    final players = (summary['players'] as List<Object?>)
        .cast<Map<String, Object?>>();
    var h = 0x811C9DC5;
    void mix(int v) {
      h = mul32(h ^ (v & 0xFF), 0x01000193);
      h = mul32(h ^ ((v >> 8) & 0xFF), 0x01000193);
      h = mul32(h ^ ((v >> 16) & 0xFF), 0x01000193);
    }

    mix((summary['seed'] as num).toInt());
    mix((summary['endTick'] as num).toInt());
    mix((summary['winnerTeam'] as num? ?? -1).toInt() + 1);
    for (final p in players) {
      for (final k in const [
        'id',
        'team',
        'placement',
        'kills',
        'damage',
        'harvested',
        'built',
        'chests',
        'survived',
        'xp',
      ]) {
        mix((p[k] as num? ?? 0).toInt());
      }
    }
    return h.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  static double _lerpAngle(double a, double b, double t) {
    var d = (b - a) % (math.pi * 2);
    if (d > math.pi) d -= math.pi * 2;
    if (d < -math.pi) d += math.pi * 2;
    return a + d * t;
  }
}
