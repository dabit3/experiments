/// Wire-level constants for the Lastfort JSON-over-WebSocket protocol.
/// See PROTOCOL.md for the full specification.
class Protocol {
  static const version = 1;

  // Client -> server
  static const hello = 'hello';
  static const createRoom = 'createRoom';
  static const joinRoom = 'joinRoom';
  static const leaveRoom = 'leaveRoom';
  static const ready = 'ready';
  static const startMatch = 'startMatch';
  static const setLoadout = 'setLoadout';
  static const input = 'input';
  static const ping = 'ping';
  static const testControl = 'testControl';

  // Server -> client
  static const welcome = 'welcome';
  static const error = 'error';
  static const roomState = 'roomState';
  static const matchStart = 'matchStart';
  static const snapshot = 'snapshot';
  static const events = 'events';
  static const matchEnd = 'matchEnd';
  static const pong = 'pong';
  static const testAck = 'testAck';
}

/// Error codes sent in `error` messages.
class ProtocolError {
  static const badMessage = 'bad_message';
  static const roomNotFound = 'room_not_found';
  static const roomFull = 'room_full';
  static const matchInProgress = 'match_in_progress';
  static const notHost = 'not_host';
  static const notInRoom = 'not_in_room';
  static const badToken = 'bad_token';
  static const versionMismatch = 'version_mismatch';
}
