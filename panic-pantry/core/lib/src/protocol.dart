/// Wire protocol constants. See PROTOCOL.md for the full contract.
class Msg {
  // client -> server
  static const hello = 'hello';
  static const roomCreate = 'room.create';
  static const roomJoin = 'room.join';
  static const roomLeave = 'room.leave';
  static const roomReady = 'room.ready';
  static const roomSetLevel = 'room.setLevel';
  static const roomAddBot = 'room.addBot';
  static const roomRemoveBot = 'room.removeBot';
  static const roomStart = 'room.start';
  static const roomRematch = 'room.rematch';
  static const input = 'input';
  static const ping = 'ping';
  static const testReport = 'test.report';

  // server -> client
  static const welcome = 'welcome';
  static const roomState = 'room.state';
  static const snapshot = 'game.snapshot';
  static const results = 'game.results';
  static const pong = 'pong';
  static const error = 'error';
  static const testInput = 'test.input';
  static const testCommand = 'test.command';
}

/// Protocol version; bumped on incompatible changes.
const int kProtocolVersion = 1;

/// Default server port.
const int kDefaultPort = 8787;
