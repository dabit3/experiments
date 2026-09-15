import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:voxelhearth_core/voxelhearth_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A connected WebSocket.
class Client {
  Client(this.channel, this.hub);

  final WebSocketChannel channel;
  final Hub hub;
  String? playerId;
  String? token;
  String name = 'Wanderer';
  String platform = Platform.unknown;
  String? roomCode;
  bool isDirector = false;
  bool closed = false;

  void send(Map<String, Object?> msg) {
    if (closed) return;
    try {
      channel.sink.add(jsonEncode(msg));
    } catch (_) {
      closed = true;
    }
  }

  void error(String code, String message) => send({'t': Msg.error, 'code': code, 'msg': message});
}

class PendingHash {
  PendingHash(this.id, this.room, this.expect, this.director);
  final String id;
  final Room room;
  final Set<String> expect;
  final Client director;
  final Map<String, Object?> got = <String, Object?>{};
  Timer? timer;
}

/// Owns rooms, connections, persistence and the tick loop.
class Hub {
  Hub({
    required this.saveDir,
    this.testMode = false,
    this.directorKey = 'voxelhearth-director',
    this.defaultSeed,
    this.log = print,
    this.tickHz = 20,
  });

  final String saveDir;
  final bool testMode;
  final String directorKey;
  final int? defaultSeed;
  final void Function(String) log;
  final int tickHz;

  final Map<String, Room> rooms = <String, Room>{};
  final Set<Client> clients = <Client>{};
  final Map<String, Client> byPlayer = <String, Client>{};
  final Map<String, String> tokenToPlayer = <String, String>{};
  final Map<String, String> playerRoom = <String, String>{};
  final Map<String, PendingHash> pendingHashes = <String, PendingHash>{};
  final math.Random _random = math.Random.secure();
  Timer? _ticker;
  int _driveCounter = 0;

  void start() {
    Directory(saveDir).createSync(recursive: true);
    _ticker = Timer.periodic(Duration(milliseconds: (1000 / tickHz).round()), (_) => _tickAll());
  }

  Future<void> stop() async {
    _ticker?.cancel();
    saveAll();
    for (final c in clients.toList()) {
      await c.channel.sink.close();
    }
  }

  void _tickAll() {
    for (final room in rooms.values) {
      final active = room.players.values.any((p) => p.connected && !p.isBot) || room.phase == Phase.playing;
      if (!active) continue;
      room.tickOnce();
    }
    if (DateTime.now().second % 10 == 0 && DateTime.now().millisecond < 60) saveAll();
  }

  // ---------------------------------------------------------------- persistence

  String _savePath(String code) => p.join(saveDir, '$code.json');

  void saveAll() {
    for (final room in rooms.values) {
      if (!room.dirty) continue;
      room.dirty = false;
      try {
        File(_savePath(room.code)).writeAsStringSync(jsonEncode(room.toSave()));
      } catch (e) {
        log('save failed for ${room.code}: $e');
      }
    }
  }

  Room? _loadRoom(String code) {
    final f = File(_savePath(code));
    if (!f.existsSync()) return null;
    try {
      final j = (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
      final room = _newRoom(
        code: code,
        name: jstr(j, 'name', code),
        seed: jint(j, 'seed'),
        mode: jstr(j, 'mode', GameMode.survival),
      );
      room.loadSave(j);
      room.phase = Phase.lobby;
      return room;
    } catch (e) {
      log('failed to load room $code: $e');
      return null;
    }
  }

  Room _newRoom({
    required String code,
    required String name,
    required int seed,
    String mode = GameMode.survival,
    int durationTicks = 0,
    bool freezeTime = false,
    bool spawnMobs = true,
    int startTime = 1000,
  }) {
    final room = Room(
      code: code,
      name: name,
      seed: seed,
      mode: mode,
      durationTicks: durationTicks,
      freezeTime: freezeTime,
      spawnMobs: spawnMobs,
      startTime: startTime,
      cheats: testMode,
      emit: (target, msg) => _emit(code, target, msg),
    );
    rooms[code] = room;
    return room;
  }

  void _emit(String roomCode, String? target, Map<String, Object?> msg) {
    if (target != null) {
      byPlayer[target]?.send(msg);
      return;
    }
    for (final c in clients) {
      if (c.roomCode == roomCode && c.playerId != null) c.send(msg);
      if (c.isDirector && msg['t'] == Msg.chatMsg) c.send({'t': Msg.directorEvent, 'room': roomCode, 'event': msg});
      if (c.isDirector && msg['t'] == Msg.phase) c.send({'t': Msg.directorEvent, 'room': roomCode, 'event': msg});
    }
  }

  String _newCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    while (true) {
      final code = List.generate(5, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
      if (!rooms.containsKey(code) && !File(_savePath(code)).existsSync()) return code;
    }
  }

  String _newToken() => List.generate(24, (_) => _random.nextInt(36).toRadixString(36)).join();

  // ---------------------------------------------------------------- connections

  void onConnect(WebSocketChannel channel) {
    final c = Client(channel, this);
    clients.add(c);
    channel.stream.listen(
      (data) => _onMessage(c, data),
      onDone: () => _onClose(c),
      onError: (Object e) => _onClose(c),
      cancelOnError: true,
    );
  }

  void _onClose(Client c) {
    c.closed = true;
    clients.remove(c);
    final pid = c.playerId;
    if (pid != null && byPlayer[pid] == c) {
      byPlayer.remove(pid);
      final room = c.roomCode == null ? null : rooms[c.roomCode!];
      room?.disconnect(pid);
      room?.dirty = true;
    }
  }

  void _onMessage(Client c, Object? data) {
    Map<String, Object?> m;
    try {
      final decoded = jsonDecode(data is String ? data : utf8.decode(data as List<int>));
      if (decoded is! Map) return;
      m = decoded.cast<String, Object?>();
    } catch (_) {
      c.error('bad_json', 'Could not parse message');
      return;
    }
    final t = jstr(m, 't');
    try {
      switch (t) {
        case Msg.hello:
          _hello(c, m);
        case Msg.ping:
          c.send({'t': Msg.pong, 'ts': m['ts'], 'serverTime': DateTime.now().millisecondsSinceEpoch});
        case Msg.director:
          _director(c, m);
        case Msg.listRooms:
          c.send({'t': Msg.rooms, 'rooms': _roomList()});
        case Msg.createRoom:
          _createRoom(c, m);
        case Msg.joinRoom:
          _joinRoom(c, jstr(m, 'code').toUpperCase().trim());
        case Msg.leaveRoom:
          _leaveRoom(c);
        case Msg.clientHash:
          _clientHash(c, m);
        case Msg.driveDone:
          for (final d in clients.where((x) => x.isDirector)) {
            d.send({
              't': Msg.directorEvent,
              'room': c.roomCode,
              'event': {...m, 'player': c.name, 'playerId': c.playerId},
            });
          }
        case Msg.drive:
        case Msg.hashRequest:
        case Msg.directorQuery:
          if (!c.isDirector) {
            c.error('forbidden', 'director only');
          } else {
            _directorCommand(c, m);
          }
        default:
          final pid = c.playerId;
          final code = c.roomCode;
          if (pid == null || code == null) {
            c.error('not_in_room', 'Join a room first');
            return;
          }
          rooms[code]?.handle(pid, m);
      }
    } catch (e, st) {
      log('error handling $t: $e\n$st');
      c.error('internal', 'Server error handling $t');
    }
  }

  void _hello(Client c, Map<String, Object?> m) {
    final version = jint(m, 'version', 1);
    if (version != ProtocolVersion.current) {
      c.error('version', 'Protocol version mismatch (server ${ProtocolVersion.current})');
    }
    var name = jstr(m, 'name', 'Wanderer').trim();
    if (name.isEmpty) name = 'Wanderer';
    if (name.length > 20) name = name.substring(0, 20);
    c.name = name;
    c.platform = jstr(m, 'platform', Platform.unknown);
    var token = jstr(m, 'token');
    String playerId;
    if (token.isNotEmpty && tokenToPlayer.containsKey(token)) {
      playerId = tokenToPlayer[token]!;
    } else {
      token = testMode ? 'test-${name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-')}' : _newToken();
      playerId = tokenToPlayer[token] ?? 'p-${_hashName(token)}';
      tokenToPlayer[token] = playerId;
    }
    // Kick a stale connection for the same player (reconnect).
    final old = byPlayer[playerId];
    if (old != null && old != c) {
      old.playerId = null;
      old.closed = true;
      old.channel.sink.close();
      clients.remove(old);
    }
    c.playerId = playerId;
    c.token = token;
    byPlayer[playerId] = c;
    c.send({
      't': Msg.welcome,
      'playerId': playerId,
      'token': token,
      'name': name,
      'serverVersion': ProtocolVersion.current,
      'testMode': testMode,
      'tickHz': tickHz,
    });
    // Auto-rejoin a room the player was in before disconnecting.
    final prior = playerRoom[playerId];
    if (prior != null && rooms.containsKey(prior)) {
      _joinRoom(c, prior);
    } else {
      c.send({'t': Msg.rooms, 'rooms': _roomList()});
    }
  }

  String _hashName(String s) {
    final h = Fnv32()..addString(s);
    return h.hex;
  }

  List<Map<String, Object?>> _roomList() => rooms.values
      .map(
        (r) => {
          'code': r.code,
          'name': r.name,
          'mode': r.mode,
          'phase': r.phase,
          'players': r.players.values.where((p) => p.connected || p.isBot).length,
          'humans': r.humanCount,
        },
      )
      .toList();

  void _createRoom(Client c, Map<String, Object?> m) {
    if (c.playerId == null) {
      c.error('no_hello', 'Send hello first');
      return;
    }
    _leaveRoom(c, silent: true);
    final requested = jstr(m, 'code').toUpperCase().trim();
    final code = testMode && requested.isNotEmpty ? requested : _newCode();
    if (rooms.containsKey(code)) {
      _joinRoom(c, code);
      return;
    }
    final seed = m.containsKey('seed') ? jint(m, 'seed') : (defaultSeed ?? _random.nextInt(1 << 30));
    var name = jstr(m, 'name', "${c.name}'s world").trim();
    if (name.isEmpty) name = "${c.name}'s world";
    final room = _newRoom(
      code: code,
      name: name,
      seed: seed,
      mode: jstr(m, 'mode', GameMode.survival),
      durationTicks: jint(m, 'durationTicks', 0),
      freezeTime: jbool(m, 'freezeTime', false),
      spawnMobs: jbool(m, 'spawnMobs', true),
      startTime: jint(m, 'startTime', 1000),
    );
    final bots = jint(m, 'bots', 0).clamp(0, 6);
    for (var i = 0; i < bots; i++) {
      room.addBot();
    }
    log('room $code created by ${c.name} (seed $seed, ${room.mode})');
    _joinRoom(c, code);
  }

  void _joinRoom(Client c, String code) {
    final pid = c.playerId;
    if (pid == null) {
      c.error('no_hello', 'Send hello first');
      return;
    }
    if (code.isEmpty) {
      c.error('bad_code', 'Enter a room code');
      return;
    }
    var room = rooms[code] ?? _loadRoom(code);
    if (room == null) {
      c.error('no_room', 'No room with code $code');
      return;
    }
    if (c.roomCode != null && c.roomCode != code) _leaveRoom(c, silent: true);
    c.roomCode = code;
    playerRoom[pid] = code;
    final saved = room.savedPlayers.remove(pid);
    room.join(pid, c.name, c.platform, saved: saved);
    for (final d in clients.where((x) => x.isDirector)) {
      d.send({
        't': Msg.directorEvent,
        'room': code,
        'event': {'t': 'joined', 'player': c.name, 'playerId': pid, 'platform': c.platform},
      });
    }
  }

  void _leaveRoom(Client c, {bool silent = false}) {
    final code = c.roomCode;
    final pid = c.playerId;
    if (code == null || pid == null) return;
    rooms[code]?.leave(pid);
    playerRoom.remove(pid);
    c.roomCode = null;
    if (!silent) c.send({'t': Msg.rooms, 'rooms': _roomList()});
  }

  // ---------------------------------------------------------------- director (test mode)

  void _director(Client c, Map<String, Object?> m) {
    if (!testMode) {
      c.error('forbidden', 'Server is not running in test mode');
      return;
    }
    if (jstr(m, 'key') != directorKey) {
      c.error('forbidden', 'Bad director key');
      return;
    }
    c.isDirector = true;
    c.name = 'director';
    c.send({'t': 'director_ok', 'rooms': _roomList()});
  }

  void _directorCommand(Client d, Map<String, Object?> m) {
    final t = jstr(m, 't');
    final code = jstr(m, 'room').toUpperCase();
    final room = rooms[code];
    switch (t) {
      case Msg.drive:
        // Target by name, player id, or `@platform` (first connected client).
        final target = jstr(m, 'player');
        final client = clients
            .where(
              (c) =>
                  c.playerId != null &&
                  (c.name == target ||
                      c.playerId == target ||
                      (target.startsWith('@') && c.platform == target.substring(1))),
            )
            .firstOrNull;
        if (client == null) {
          d.send({
            't': Msg.directorEvent,
            'event': {'t': 'drive_done', 'id': m['id'], 'ok': false, 'error': 'no such player $target'},
          });
          return;
        }
        final id = jstr(m, 'id', 'd${++_driveCounter}');
        client.send({'t': Msg.drive, 'id': id, 'action': m['action']});
      case Msg.hashRequest:
        if (room == null) {
          d.error('no_room', 'no room $code');
          return;
        }
        final id = 'h${++_driveCounter}';
        final expect = clients.where((c) => c.roomCode == code && c.playerId != null).map((c) => c.playerId!).toSet();
        final pending = PendingHash(id, room, expect, d);
        pendingHashes[id] = pending;
        for (final c in clients.where((c) => c.roomCode == code && c.playerId != null)) {
          c.send({'t': Msg.hashRequest, 'id': id, 'region': m['region']});
        }
        pending.timer = Timer(const Duration(seconds: 8), () => _finishHash(pending, timedOut: true));
        if (expect.isEmpty) _finishHash(pending);
      case Msg.directorQuery:
        if (room == null) {
          d.send({
            't': Msg.directorEvent,
            'event': {'t': 'query', 'room': code, 'exists': false},
          });
          return;
        }
        final cmd = jmap(m, 'cmd');
        if (cmd != null) {
          final host = room.hostId;
          if (host != null) room.handle(host, cmd);
        }
        d.send({
          't': Msg.directorEvent,
          'event': {
            't': 'query',
            'room': code,
            'exists': true,
            'state': room.roomStateJson(),
            'worldHash': room.world.editsHash(),
            'chatHash': room.chatHash(),
            'chat': room.chat.map((c) => c.toJson()).toList(),
            'positions': room.players.values.map((p) => p.toSnapshot()).toList(),
            'mobs': room.mobs.values.map((m) => m.toSnapshot()).toList(),
            'inventories': {for (final p in room.players.values) p.name: p.inv.toJson()},
            'blocks': _blocksFor(room, m),
          },
        });
    }
  }

  List<int>? _blocksFor(Room room, Map<String, Object?> m) {
    final region = jints(m, 'region');
    if (region.length != 6) return null;
    final out = <int>[];
    for (var y = region[1]; y <= region[4]; y++) {
      for (var z = region[2]; z <= region[5]; z++) {
        for (var x = region[0]; x <= region[3]; x++) {
          out.add(room.world.peek(x, y, z));
        }
      }
    }
    return out;
  }

  void _clientHash(Client c, Map<String, Object?> m) {
    final pending = pendingHashes[jstr(m, 'id')];
    if (pending == null || c.playerId == null) return;
    pending.got[c.name] = {
      'playerId': c.playerId,
      'platform': c.platform,
      'world': m['world'],
      'chat': m['chat'],
      'region': m['region'],
      'chatLines': m['chatLines'],
      'phase': m['phase'],
      'players': m['players'],
    };
    pending.expect.remove(c.playerId);
    if (pending.expect.isEmpty) _finishHash(pending);
  }

  void _finishHash(PendingHash pending, {bool timedOut = false}) {
    if (!pendingHashes.containsKey(pending.id)) return;
    pendingHashes.remove(pending.id);
    pending.timer?.cancel();
    pending.director.send({
      't': Msg.hashes,
      'id': pending.id,
      'room': pending.room.code,
      'timedOut': timedOut,
      'missing': pending.expect.toList(),
      'server': {
        'world': pending.room.world.editsHash(),
        'chat': pending.room.chatHash(),
        'chatLines': pending.room.chat.length,
        'phase': pending.room.phase,
      },
      'clients': pending.got,
    });
  }
}
