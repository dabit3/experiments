/// Message type identifiers for the Brickfolk JSON-over-WebSocket protocol.
///
/// Every frame is a JSON object with a `type` field. See `PROTOCOL.md` at the
/// root of the project for the full contract.
abstract final class MsgType {
  // Client -> server
  static const hello = 'hello';
  static const ping = 'ping';
  static const avatarUpdate = 'avatar.update';
  static const shopBuy = 'shop.buy';
  static const dailyClaim = 'daily.claim';
  static const friendsRequest = 'friends.request';
  static const friendsAccept = 'friends.accept';
  static const friendsDecline = 'friends.decline';
  static const friendsRemove = 'friends.remove';
  static const partyCreate = 'party.create';
  static const partyJoin = 'party.join';
  static const partyLeave = 'party.leave';
  static const partyLaunch = 'party.launch';
  static const chatSend = 'chat.send';
  static const placesList = 'places.list';
  static const placeRate = 'place.rate';
  static const profileGet = 'profile.get';
  static const roomCreate = 'room.create';
  static const roomJoin = 'room.join';
  static const roomLeave = 'room.leave';
  static const roomReady = 'room.ready';
  static const input = 'input';
  static const testReport = 'test.report';

  // Server -> client
  static const welcome = 'welcome';
  static const pong = 'pong';
  static const error = 'error';
  static const playerUpdated = 'player.updated';
  static const dailyResult = 'daily.result';
  static const friendsState = 'friends.state';
  static const partyState = 'party.state';
  static const chatMessage = 'chat.message';
  static const places = 'places';
  static const profile = 'profile';
  static const roomState = 'room.state';
  static const gameState = 'game.state';
  static const gameEvent = 'game.event';
  static const gameResults = 'game.results';
  static const testControl = 'test.control';
}

/// Error codes carried by [MsgType.error] frames.
abstract final class ErrorCode {
  static const badRequest = 'bad_request';
  static const nameTaken = 'name_taken';
  static const invalidName = 'invalid_name';
  static const notFound = 'not_found';
  static const roomFull = 'room_full';
  static const notEnoughPips = 'not_enough_pips';
  static const alreadyOwned = 'already_owned';
  static const notLeader = 'not_leader';
  static const cooldown = 'cooldown';
  static const rateLimited = 'rate_limited';
  static const unauthenticated = 'unauthenticated';
}

/// Chat channels.
abstract final class ChatChannel {
  static const global = 'global';
  static const party = 'party';
  static const room = 'room';
}

/// Protocol version negotiated in `hello`/`welcome`.
const protocolVersion = 1;

/// Simulation tick rate used by every experience.
const ticksPerSecond = 30;
const tickDt = 1 / ticksPerSecond;

/// Maximum players in a room (bots included).
const maxRoomPlayers = 8;

/// Player name rules.
final RegExp playerNamePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,15}$');
