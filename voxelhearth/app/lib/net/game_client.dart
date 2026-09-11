import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../audio.dart';

enum ConnState { idle, connecting, connected, reconnecting, failed }

class RoomSummary {
  RoomSummary(this.code, this.name, this.mode, this.phase, this.players, this.humans);
  final String code, name, mode, phase;
  final int players, humans;

  static RoomSummary fromJson(Map<String, Object?> j) => RoomSummary(
    jstr(j, 'code'),
    jstr(j, 'name'),
    jstr(j, 'mode'),
    jstr(j, 'phase'),
    jint(j, 'players'),
    jint(j, 'humans'),
  );
}

class PlayerInfo {
  PlayerInfo.fromJson(Map<String, Object?> j)
    : id = jstr(j, 'id'),
      name = jstr(j, 'name'),
      platform = jstr(j, 'platform'),
      bot = jbool(j, 'bot'),
      connected = jbool(j, 'connected', true),
      ready = jbool(j, 'ready'),
      score = jint(j, 'score'),
      placed = jint(j, 'placed'),
      broken = jint(j, 'broken'),
      crafted = jint(j, 'crafted'),
      kills = jint(j, 'kills'),
      deaths = jint(j, 'deaths');
  final String id, name, platform;
  final bool bot, connected, ready;
  final int score, placed, broken, crafted, kills, deaths;
}

class RemotePlayer {
  RemotePlayer(this.id);
  final String id;
  String name = '';
  String platform = '';
  double x = 0, y = 0, z = 0, yaw = 0, pitch = 0;
  double px = 0, py = 0, pz = 0; // previous for interpolation
  double lerp = 1;
  int held = 0;
  bool sneak = false, sleep = false;
  int hp = 20;

  double get rx => px + (x - px) * lerp;
  double get ry => py + (y - py) * lerp;
  double get rz => pz + (z - pz) * lerp;
}

class RemoteMob {
  RemoteMob(this.id, this.kind);
  final int id;
  final String kind;
  double x = 0, y = 0, z = 0, yaw = 0;
  double px = 0, py = 0, pz = 0;
  double lerp = 1;
  int hp = 10;
  bool hurt = false;
  double get rx => px + (x - px) * lerp;
  double get ry => py + (y - py) * lerp;
  double get rz => pz + (z - pz) * lerp;
}

class ChatEntry {
  ChatEntry(this.tick, this.from, this.text, this.system, this.receivedAt);
  final int tick;
  final String from, text;
  final bool system;
  final DateTime receivedAt;
}

class Toast {
  Toast(this.text, this.at, {this.kind = 'info'});
  final String text;
  final DateTime at;
  final String kind;
}

/// Everything the UI and renderer need to know about the current room.
class RoomSession {
  RoomSession(this.seed) : world = World(seed);

  final int seed;
  final World world;
  String code = '', roomName = '', mode = GameMode.survival, phase = Phase.lobby;
  String? hostId;
  String youId = '';
  int time = 1000, tick = 0, matchEndTick = 0, durationTicks = 0;
  bool freezeTime = false, spawnMobs = true;
  List<int> spawn = const [0, 40, 0];
  double spawnX = 0, spawnY = 40, spawnZ = 0, spawnYaw = 0, spawnPitch = 0;
  final Map<String, RemotePlayer> players = <String, RemotePlayer>{};
  final Map<int, RemoteMob> mobs = <int, RemoteMob>{};
  List<PlayerInfo> roster = const [];
  final List<ChatEntry> chat = <ChatEntry>[];
  SlotList inventory = SlotList(Inventory.size);
  int selected = 0;
  int hp = 20, food = 20, air = 300, score = 0;
  String? openUi;
  int? openPos;
  SlotList? chestSlots;
  Map<String, Object?>? kiln;
  List<PlayerInfo> results = const [];
  String? resultsWorldHash, resultsChatHash;
  DateTime lastSnapshot = DateTime.now();
  final Set<int> chunksReceived = <int>{};

  bool get isHost => hostId == youId;
  int get chatLines => chat.length;

  String chatHash() {
    final h = Fnv32();
    for (final c in chat) {
      h.addString(c.from);
      h.addString(c.text);
    }
    return h.hex;
  }
}

typedef DriveHandler = Future<Map<String, Object?>> Function(Map<String, Object?> action);

/// WebSocket client with auto-reconnect; owns [RoomSession].
class GameClient extends ChangeNotifier {
  GameClient({required this.platform});

  final String platform;
  String serverUrl = 'ws://localhost:8787/ws';
  String playerName = 'Wanderer';
  String? token;
  String? playerId;
  bool serverTestMode = false;

  ConnState state = ConnState.idle;
  String? lastError;
  int reconnectAttempt = 0;
  List<RoomSummary> rooms = const [];
  RoomSession? session;
  final List<Toast> toasts = <Toast>[];
  final StreamController<Map<String, Object?>> effects = StreamController.broadcast();
  final StreamController<Map<String, Object?>> worldEvents = StreamController.broadcast();
  DriveHandler? driveHandler;
  Map<String, Object?> Function(Map<String, Object?> request)? hashProvider;
  int pingMs = 0;
  bool joiningRoom = false;
  bool _awaitingRejoin = false;
  String? pendingJoinCode;

  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _manualClose = false;

  // ---------------------------------------------------------------- connection

  Future<void> connect() async {
    _manualClose = false;
    _reconnectTimer?.cancel();
    await _closeSocket();
    state = reconnectAttempt > 0 ? ConnState.reconnecting : ConnState.connecting;
    lastError = null;
    notifyListeners();
    try {
      final ch = WebSocketChannel.connect(Uri.parse(serverUrl));
      _ch = ch;
      await ch.ready.timeout(const Duration(seconds: 8));
      _sub = ch.stream.listen(
        _onData,
        onDone: _onDone,
        onError: (Object e) => _onDone(error: e.toString()),
      );
      send({
        't': Msg.hello,
        'name': playerName,
        'platform': platform,
        'token': token,
        'version': ProtocolVersion.current,
      });
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        send({'t': Msg.ping, 'ts': DateTime.now().millisecondsSinceEpoch});
      });
    } catch (e) {
      lastError = _friendlyError(e.toString());
      _onDone(error: lastError);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('TimeoutException')) return 'Timed out reaching the server.';
    if (e.contains('refused') || e.contains('Failed host lookup') || e.contains('WebSocketChannelException')) {
      return 'Could not reach the server at $serverUrl.';
    }
    return e.length > 140 ? '${e.substring(0, 140)}…' : e;
  }

  void _onDone({String? error}) {
    _pingTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _ch = null;
    if (_manualClose) {
      state = ConnState.idle;
      notifyListeners();
      return;
    }
    if (error != null) lastError = _friendlyError(error);
    reconnectAttempt++;
    state = reconnectAttempt > 8 ? ConnState.failed : ConnState.reconnecting;
    notifyListeners();
    if (state == ConnState.failed) return;
    final delay = Duration(milliseconds: math.min(8000, 400 * (1 << math.min(reconnectAttempt, 4))));
    _reconnectTimer = Timer(delay, connect);
  }

  Future<void> disconnect() async {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _closeSocket();
    state = ConnState.idle;
    session = null;
    notifyListeners();
  }

  void retryNow() {
    reconnectAttempt = 0;
    connect();
  }

  bool get awaitingRejoin => _awaitingRejoin;

  /// Test hook: sever the socket as if the network dropped. The normal
  /// reconnect path then re-sends `hello` with the session token and the
  /// server rejoins us to the room we were in.
  Future<void> dropConnection() async {
    await _closeSocket();
    _onDone(error: 'Connection dropped');
  }

  Future<void> _closeSocket() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _ch?.sink.close();
    } catch (_) {}
    _ch = null;
  }

  void send(Map<String, Object?> msg) {
    final ch = _ch;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  // ---------------------------------------------------------------- room actions

  void refreshRooms() => send({'t': Msg.listRooms});

  void createRoom({
    required String name,
    required String mode,
    int? seed,
    int durationTicks = 0,
    bool freezeTime = false,
    bool spawnMobs = true,
    int bots = 0,
    String? code,
    int startTime = 1000,
  }) {
    joiningRoom = true;
    notifyListeners();
    send({
      't': Msg.createRoom,
      'name': name,
      'mode': mode,
      'seed': ?seed,
      'durationTicks': durationTicks,
      'freezeTime': freezeTime,
      'spawnMobs': spawnMobs,
      'bots': bots,
      'code': ?code,
      'startTime': startTime,
    });
  }

  void joinRoom(String code) {
    joiningRoom = true;
    pendingJoinCode = code;
    notifyListeners();
    send({'t': Msg.joinRoom, 'code': code});
  }

  void leaveRoom() {
    send({'t': Msg.leaveRoom});
    session = null;
    notifyListeners();
  }

  /// Replace the local session with synthetic data (visual fixtures).
  void showFixture(RoomSession? s) {
    session = s;
    notifyListeners();
  }

  /// Drop the room on this side only (used when the server is unreachable).
  void leaveRoomLocal() {
    session = null;
    reconnectAttempt = 0;
    notifyListeners();
    connect();
  }

  void toast(String text, {String kind = 'info'}) {
    toasts.add(Toast(text, DateTime.now(), kind: kind));
    if (toasts.length > 4) toasts.removeAt(0);
    notifyListeners();
    Timer(const Duration(milliseconds: 3600), () {
      toasts.removeWhere((t) => DateTime.now().difference(t.at).inMilliseconds >= 3500);
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------- inbound

  void _onData(dynamic data) {
    Map<String, Object?> m;
    try {
      final d = jsonDecode(data as String);
      if (d is! Map) return;
      m = d.cast<String, Object?>();
    } catch (_) {
      return;
    }
    final t = jstr(m, 't');
    switch (t) {
      case Msg.welcome:
        playerId = jstr(m, 'playerId');
        token = jstr(m, 'token');
        serverTestMode = jbool(m, 'testMode');
        reconnectAttempt = 0;
        state = ConnState.connected;
        lastError = null;
        // The server either rejoins us to our room or answers with the room
        // list; the latter means the room is gone (e.g. server restarted).
        _awaitingRejoin = session != null;
        notifyListeners();
      case Msg.pong:
        final ts = jint(m, 'ts');
        pingMs = DateTime.now().millisecondsSinceEpoch - ts;
      case Msg.rooms:
        rooms = (m['rooms'] as List? ?? const [])
            .map((e) => RoomSummary.fromJson((e as Map).cast<String, Object?>()))
            .toList();
        if (_awaitingRejoin) {
          _awaitingRejoin = false;
          session = null;
          lastError = 'The world you were in is no longer available';
        }
        notifyListeners();
      case Msg.error:
        final code = jstr(m, 'code');
        final msg = jstr(m, 'msg');
        if (code == 'no_room' || code == 'bad_code' || code == 'version') {
          joiningRoom = false;
          lastError = msg;
        }
        if (code != 'no_recipe' && code != 'unknown') toast(msg, kind: 'error');
        notifyListeners();
      case Msg.roomJoined:
        _awaitingRejoin = false;
        _onRoomJoined(m);
      case Msg.roomState:
        _onRoomState(m);
      case Msg.chunk:
        final s = session;
        if (s == null) return;
        final cx = jint(m, 'cx'), cz = jint(m, 'cz');
        s.world.applyEdits(cx, cz, jints(m, 'edits'));
        s.chunksReceived.add(ChunkKey.of(cx, cz));
        worldEvents.add({'t': 'chunk', 'cx': cx, 'cz': cz});
      case Msg.blockSet:
        final s = session;
        if (s == null) return;
        final x = jint(m, 'x'), y = jint(m, 'y'), z = jint(m, 'z');
        s.world.set(x, y, z, jint(m, 'id'));
        worldEvents.add({'t': 'block', 'x': x, 'y': y, 'z': z, 'id': jint(m, 'id')});
      case Msg.snapshot:
        _onSnapshot(m);
      case Msg.playerJoined:
      case Msg.playerLeft:
        // roster comes through room_state; nothing else to do
        break;
      case Msg.inventory:
        final s = session;
        if (s == null) return;
        s.inventory = SlotList.fromJson(m['slots'], Inventory.size);
        s.selected = jint(m, 'selected', s.selected);
        notifyListeners();
      case Msg.stats:
        final s = session;
        if (s == null) return;
        final oldHp = s.hp;
        s.hp = jint(m, 'hp', 20);
        s.food = jint(m, 'food', 20);
        s.air = jint(m, 'air', 300);
        s.score = jint(m, 'score', s.score);
        if (s.hp < oldHp) effects.add({'kind': 'hurt_local', 'amount': oldHp - s.hp});
        notifyListeners();
      case Msg.container:
        final s = session;
        if (s == null) return;
        if (jstr(m, 'kind') == ContainerKind.chest) {
          s.chestSlots = SlotList.fromJson(m['slots'], 27);
        } else if (jstr(m, 'kind') == ContainerKind.kiln) {
          s.kiln = jmap(m, 'kiln');
        }
        notifyListeners();
      case Msg.chatMsg:
        final s = session;
        if (s == null) return;
        s.chat.add(ChatEntry(jint(m, 'tick'), jstr(m, 'from'), jstr(m, 'text'), jbool(m, 'system'), DateTime.now()));
        if (s.chat.length > 300) s.chat.removeAt(0);
        if (!jbool(m, 'system') && jstr(m, 'from') != playerName) Sfx.play('chat', gain: 0.7);
        notifyListeners();
      case Msg.phase:
        final s = session;
        if (s == null) return;
        final prevPhase = s.phase;
        s.phase = jstr(m, 'phase', s.phase);
        if (s.phase != prevPhase) {
          if (s.phase == Phase.playing) Sfx.play('match_start');
          if (s.phase == Phase.results) Sfx.play('match_end');
        }
        s.tick = jint(m, 'tick', s.tick);
        s.matchEndTick = jint(m, 'matchEndTick', s.matchEndTick);
        if (m.containsKey('time')) s.time = jint(m, 'time', s.time);
        if (s.phase == Phase.results) {
          s.results = (m['results'] as List? ?? const [])
              .map((e) => PlayerInfo.fromJson((e as Map).cast<String, Object?>()))
              .toList();
          s.resultsWorldHash = jstr(m, 'worldHash');
          s.resultsChatHash = jstr(m, 'chatHash');
        }
        if (s.phase == Phase.lobby) s.results = const [];
        effects.add({'kind': 'phase', 'phase': s.phase});
        notifyListeners();
      case Msg.timeSet:
        final s = session;
        if (s == null) return;
        s.time = jint(m, 'time', s.time);
        notifyListeners();
      case Msg.teleport:
        effects.add({'kind': 'teleport', 'x': jdouble(m, 'x'), 'y': jdouble(m, 'y'), 'z': jdouble(m, 'z')});
      case Msg.openUi:
        final s = session;
        if (s == null) return;
        final kind = jstr(m, 'kind');
        s.openUi = kind == ContainerKind.inventory ? null : kind;
        s.openPos = m.containsKey('x') ? BlockPos.key(jint(m, 'x'), jint(m, 'y'), jint(m, 'z')) : null;
        if (kind == ContainerKind.inventory) {
          s.chestSlots = null;
          s.kiln = null;
        }
        effects.add({'kind': 'open_ui', 'ui': kind});
        notifyListeners();
      case Msg.effect:
        final kind = jstr(m, 'kind');
        if (kind == 'toast') toast(jstr(m, 'text'));
        effects.add(m);
      case Msg.drive:
        _onDrive(m);
      case Msg.hashRequest:
        final s = session;
        final provider = hashProvider;
        if (s == null) return;
        final extra = provider?.call(m) ?? const <String, Object?>{};
        final region = jints(m, 'region');
        send({
          if (region.length == 6)
            'region': s.world.regionHash(region[0], region[1], region[2], region[3], region[4], region[5]),
          't': Msg.clientHash,
          'id': m['id'],
          'world': s.world.editsHash(),
          'chat': s.chatHash(),
          'chatLines': s.chat.length,
          'phase': s.phase,
          'players': s.players.length,
          ...extra,
        });
      default:
        break;
    }
  }

  void _onRoomJoined(Map<String, Object?> m) {
    final seed = jint(m, 'seed');
    final s = RoomSession(seed);
    s.code = jstr(m, 'code');
    s.roomName = jstr(m, 'roomName');
    s.mode = jstr(m, 'mode', GameMode.survival);
    s.phase = jstr(m, 'phase', Phase.lobby);
    s.time = jint(m, 'time', 1000);
    s.freezeTime = jbool(m, 'freezeTime');
    s.durationTicks = jint(m, 'durationTicks');
    s.tick = jint(m, 'tick');
    s.youId = jstr(m, 'you');
    s.hostId = m['host'] as String?;
    s.spawn = jints(m, 'spawn');
    s.spawnX = jdouble(m, 'x');
    s.spawnY = jdouble(m, 'y');
    s.spawnZ = jdouble(m, 'z');
    s.spawnYaw = jdouble(m, 'yaw');
    s.spawnPitch = jdouble(m, 'pitch');
    s.matchEndTick = jint(m, 'matchEndTick');
    s.roster = (m['players'] as List? ?? const [])
        .map((e) => PlayerInfo.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    for (final c in m['chat'] as List? ?? const []) {
      final j = (c as Map).cast<String, Object?>();
      s.chat.add(ChatEntry(jint(j, 'tick'), jstr(j, 'from'), jstr(j, 'text'), jbool(j, 'system'), DateTime.now()));
    }
    session = s;
    joiningRoom = false;
    pendingJoinCode = null;
    notifyListeners();
  }

  void _onRoomState(Map<String, Object?> m) {
    final s = session;
    if (s == null) return;
    s.roomName = jstr(m, 'name', s.roomName);
    s.mode = jstr(m, 'mode', s.mode);
    s.phase = jstr(m, 'phase', s.phase);
    s.hostId = m['host'] as String? ?? s.hostId;
    s.durationTicks = jint(m, 'durationTicks', s.durationTicks);
    s.freezeTime = jbool(m, 'freezeTime', s.freezeTime);
    s.spawnMobs = jbool(m, 'spawnMobs', s.spawnMobs);
    s.matchEndTick = jint(m, 'matchEndTick', s.matchEndTick);
    s.tick = jint(m, 'tick', s.tick);
    s.time = jint(m, 'time', s.time);
    s.roster = (m['players'] as List? ?? const [])
        .map((e) => PlayerInfo.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    for (final p in s.roster) {
      final rp = s.players.putIfAbsent(p.id, () => RemotePlayer(p.id));
      rp.name = p.name;
      rp.platform = p.platform;
    }
    notifyListeners();
  }

  void _onSnapshot(Map<String, Object?> m) {
    final s = session;
    if (s == null) return;
    s.tick = jint(m, 'tick', s.tick);
    s.time = jint(m, 'time', s.time);
    s.lastSnapshot = DateTime.now();
    final seen = <String>{};
    for (final e in m['players'] as List? ?? const []) {
      final j = (e as Map).cast<String, Object?>();
      final id = jstr(j, 'id');
      seen.add(id);
      final rp = s.players.putIfAbsent(id, () => RemotePlayer(id));
      rp.px = rp.rx;
      rp.py = rp.ry;
      rp.pz = rp.rz;
      rp.lerp = 0;
      rp.x = jdouble(j, 'x');
      rp.y = jdouble(j, 'y');
      rp.z = jdouble(j, 'z');
      rp.yaw = jdouble(j, 'yaw');
      rp.pitch = jdouble(j, 'pitch');
      rp.held = jint(j, 'held');
      rp.sneak = jbool(j, 'sneak');
      rp.sleep = jbool(j, 'sleep');
      rp.hp = jint(j, 'hp', 20);
      if (rp.px == 0 && rp.py == 0 && rp.pz == 0) {
        rp.px = rp.x;
        rp.py = rp.y;
        rp.pz = rp.z;
      }
    }
    s.players.removeWhere((id, _) => !seen.contains(id));
    final seenMobs = <int>{};
    for (final e in m['mobs'] as List? ?? const []) {
      final j = (e as Map).cast<String, Object?>();
      final id = jint(j, 'id');
      seenMobs.add(id);
      final rm = s.mobs.putIfAbsent(id, () => RemoteMob(id, jstr(j, 'kind')));
      rm.px = rm.rx;
      rm.py = rm.ry;
      rm.pz = rm.rz;
      rm.lerp = 0;
      rm.x = jdouble(j, 'x');
      rm.y = jdouble(j, 'y');
      rm.z = jdouble(j, 'z');
      rm.yaw = jdouble(j, 'yaw');
      rm.hp = jint(j, 'hp');
      rm.hurt = jbool(j, 'hurt');
      if (rm.px == 0 && rm.py == 0 && rm.pz == 0) {
        rm.px = rm.x;
        rm.py = rm.y;
        rm.pz = rm.z;
      }
    }
    s.mobs.removeWhere((id, _) => !seenMobs.contains(id));
  }

  Future<void> _onDrive(Map<String, Object?> m) async {
    final id = jstr(m, 'id');
    final action = jmap(m, 'action') ?? const <String, Object?>{};
    final handler = driveHandler;
    Map<String, Object?> result;
    if (handler == null) {
      result = {'ok': false, 'error': 'no drive handler active'};
    } else {
      try {
        result = await handler(action);
      } catch (e) {
        result = {'ok': false, 'error': e.toString()};
      }
    }
    send({...result, 't': Msg.driveDone, 'id': id});
  }

  @override
  void dispose() {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _closeSocket();
    effects.close();
    worldEvents.close();
    super.dispose();
  }
}
