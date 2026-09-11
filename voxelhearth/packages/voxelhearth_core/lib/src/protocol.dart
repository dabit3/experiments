/// JSON-over-WebSocket message names. Every message is an object with a
/// string `t` field; see PROTOCOL.md for the full field list.
class Msg {
  // client -> server
  static const hello = 'hello';
  static const createRoom = 'create_room';
  static const joinRoom = 'join_room';
  static const leaveRoom = 'leave_room';
  static const listRooms = 'list_rooms';
  static const startMatch = 'start_match';
  static const endMatch = 'end_match';
  static const backToLobby = 'back_to_lobby';
  static const roomSettings = 'room_settings';
  static const addBot = 'add_bot';
  static const removeBot = 'remove_bot';
  static const move = 'move';
  static const breakBlock = 'break';
  static const placeBlock = 'place';
  static const interact = 'interact';
  static const selectSlot = 'select_slot';
  static const moveItem = 'move_item';
  static const craft = 'craft';
  static const eat = 'eat';
  static const attack = 'attack';
  static const sleep = 'sleep';
  static const chat = 'chat';
  static const requestChunks = 'request_chunks';
  static const setMode = 'set_mode';
  static const ping = 'ping';
  static const clientHash = 'client_hash';
  static const driveDone = 'drive_done';
  static const director = 'director';
  static const drive = 'drive';
  static const hashRequest = 'hash_request';
  static const directorQuery = 'director_query';

  // server -> client
  static const welcome = 'welcome';
  static const rooms = 'rooms';
  static const roomJoined = 'room_joined';
  static const roomState = 'room_state';
  static const chunk = 'chunk';
  static const blockSet = 'block_set';
  static const snapshot = 'snapshot';
  static const playerJoined = 'player_joined';
  static const playerLeft = 'player_left';
  static const inventory = 'inventory';
  static const stats = 'stats';
  static const container = 'container';
  static const chatMsg = 'chat_msg';
  static const phase = 'phase';
  static const error = 'error';
  static const pong = 'pong';
  static const timeSet = 'time_set';
  static const teleport = 'teleport';
  static const openUi = 'open_ui';
  static const hashes = 'hashes';
  static const directorEvent = 'director_event';
  static const effect = 'effect';
}

class Phase {
  static const lobby = 'lobby';
  static const playing = 'playing';
  static const results = 'results';
}

class GameMode {
  static const survival = 'survival';
  static const creative = 'creative';
}

class Platform {
  static const web = 'web';
  static const ios = 'ios';
  static const android = 'android';
  static const macos = 'macos';
  static const bot = 'bot';
  static const unknown = 'unknown';
}

/// Container kinds a client can have open.
class ContainerKind {
  static const inventory = 'inventory';
  static const workbench = 'workbench';
  static const chest = 'chest';
  static const kiln = 'kiln';
}

class ProtocolVersion {
  static const current = 1;
}

/// Helpers for lenient JSON reading.
int jint(Map<String, Object?> m, String k, [int d = 0]) {
  final v = m[k];
  return v is num ? v.toInt() : d;
}

double jdouble(Map<String, Object?> m, String k, [double d = 0]) {
  final v = m[k];
  return v is num ? v.toDouble() : d;
}

String jstr(Map<String, Object?> m, String k, [String d = '']) {
  final v = m[k];
  return v is String ? v : d;
}

bool jbool(Map<String, Object?> m, String k, [bool d = false]) {
  final v = m[k];
  return v is bool ? v : d;
}

List<int> jints(Map<String, Object?> m, String k) {
  final v = m[k];
  if (v is List) return v.map((e) => e is num ? e.toInt() : 0).toList();
  return const [];
}

Map<String, Object?>? jmap(Map<String, Object?> m, String k) {
  final v = m[k];
  return v is Map ? v.cast<String, Object?>() : null;
}
