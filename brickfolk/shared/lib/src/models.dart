import 'avatar.dart';
import 'experiences.dart';

/// Public view of a player shared with other clients.
class PlayerSummary {
  const PlayerSummary({
    required this.id,
    required this.name,
    required this.avatar,
    this.platform = 'unknown',
    this.isBot = false,
    this.online = true,
  });

  final String id;
  final String name;
  final Avatar avatar;
  final String platform;
  final bool isBot;
  final bool online;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar.toJson(),
    'platform': platform,
    'isBot': isBot,
    'online': online,
  };

  static PlayerSummary fromJson(Map<String, Object?> json) => PlayerSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    avatar: Avatar.fromJson(
      (json['avatar'] as Map?)?.cast<String, Object?>() ?? const {},
    ),
    platform: json['platform'] as String? ?? 'unknown',
    isBot: json['isBot'] as bool? ?? false,
    online: json['online'] as bool? ?? true,
  );
}

/// Private view of the signed-in player.
class PlayerProfile {
  const PlayerProfile({
    required this.summary,
    required this.pips,
    required this.owned,
    required this.badges,
    required this.createdAt,
    required this.dailyStreak,
    required this.lastDailyClaim,
    required this.stats,
  });

  final PlayerSummary summary;
  final int pips;
  final Set<String> owned;
  final List<String> badges;
  final int createdAt;
  final int dailyStreak;
  final int? lastDailyClaim;
  final Map<String, int> stats;

  Map<String, Object?> toJson() => {
    ...summary.toJson(),
    'pips': pips,
    'owned': owned.toList()..sort(),
    'badges': badges,
    'createdAt': createdAt,
    'dailyStreak': dailyStreak,
    'lastDailyClaim': lastDailyClaim,
    'stats': stats,
  };

  static PlayerProfile fromJson(Map<String, Object?> json) => PlayerProfile(
    summary: PlayerSummary.fromJson(json),
    pips: (json['pips'] as num?)?.toInt() ?? 0,
    owned: ((json['owned'] as List?) ?? const []).cast<String>().toSet(),
    badges: ((json['badges'] as List?) ?? const []).cast<String>(),
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
    lastDailyClaim: (json['lastDailyClaim'] as num?)?.toInt(),
    stats: ((json['stats'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.channel,
    required this.from,
    required this.text,
    required this.filtered,
    required this.timestamp,
  });

  final int id;
  final String channel;
  final PlayerSummary from;
  final String text;
  final bool filtered;
  final int timestamp;

  Map<String, Object?> toJson() => {
    'id': id,
    'channel': channel,
    'from': from.toJson(),
    'text': text,
    'filtered': filtered,
    'timestamp': timestamp,
  };

  static ChatMessage fromJson(Map<String, Object?> json) => ChatMessage(
    id: (json['id'] as num).toInt(),
    channel: json['channel'] as String,
    from: PlayerSummary.fromJson((json['from'] as Map).cast<String, Object?>()),
    text: json['text'] as String,
    filtered: json['filtered'] as bool? ?? false,
    timestamp: (json['timestamp'] as num).toInt(),
  );
}

class PartyState {
  const PartyState({
    required this.code,
    required this.leaderId,
    required this.members,
    this.roomCode,
    this.experience,
  });

  final String code;
  final String leaderId;
  final List<PlayerSummary> members;
  final String? roomCode;
  final ExperienceKind? experience;

  Map<String, Object?> toJson() => {
    'code': code,
    'leaderId': leaderId,
    'members': members.map((m) => m.toJson()).toList(),
    'roomCode': roomCode,
    'experience': experience?.id,
  };

  static PartyState fromJson(Map<String, Object?> json) => PartyState(
    code: json['code'] as String,
    leaderId: json['leaderId'] as String,
    members: ((json['members'] as List?) ?? const [])
        .map((m) => PlayerSummary.fromJson((m as Map).cast()))
        .toList(),
    roomCode: json['roomCode'] as String?,
    experience: ExperienceKind.fromId(json['experience'] as String?),
  );
}

enum RoomPhase { lobby, countdown, playing, results }

class RoomMember {
  const RoomMember({required this.player, required this.ready});

  final PlayerSummary player;
  final bool ready;

  Map<String, Object?> toJson() => {'player': player.toJson(), 'ready': ready};

  static RoomMember fromJson(Map<String, Object?> json) => RoomMember(
    player: PlayerSummary.fromJson((json['player'] as Map).cast()),
    ready: json['ready'] as bool? ?? false,
  );
}

class RoomState {
  const RoomState({
    required this.code,
    required this.experience,
    required this.phase,
    required this.members,
    required this.seed,
    this.countdownEndsAt,
    this.matchEndsAt,
    this.round = 0,
  });

  final String code;
  final ExperienceKind experience;
  final RoomPhase phase;
  final List<RoomMember> members;
  final int seed;
  final int? countdownEndsAt;
  final int? matchEndsAt;
  final int round;

  Map<String, Object?> toJson() => {
    'code': code,
    'experience': experience.id,
    'phase': phase.name,
    'members': members.map((m) => m.toJson()).toList(),
    'seed': seed,
    'countdownEndsAt': countdownEndsAt,
    'matchEndsAt': matchEndsAt,
    'round': round,
  };

  static RoomState fromJson(Map<String, Object?> json) => RoomState(
    code: json['code'] as String,
    experience: ExperienceKind.fromId(json['experience'] as String)!,
    phase: RoomPhase.values.byName(json['phase'] as String),
    members: ((json['members'] as List?) ?? const [])
        .map((m) => RoomMember.fromJson((m as Map).cast()))
        .toList(),
    seed: (json['seed'] as num).toInt(),
    countdownEndsAt: (json['countdownEndsAt'] as num?)?.toInt(),
    matchEndsAt: (json['matchEndsAt'] as num?)?.toInt(),
    round: (json['round'] as num?)?.toInt() ?? 0,
  );
}

/// One row of the end-of-match leaderboard. Identical on every client.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.player,
    required this.score,
    required this.detail,
    required this.pipsEarned,
    required this.badgesEarned,
  });

  final int rank;
  final PlayerSummary player;
  final int score;

  /// Human readable detail such as `Finished 42.3s` or `Stage 7`.
  final String detail;
  final int pipsEarned;
  final List<String> badgesEarned;

  Map<String, Object?> toJson() => {
    'rank': rank,
    'player': player.toJson(),
    'score': score,
    'detail': detail,
    'pipsEarned': pipsEarned,
    'badgesEarned': badgesEarned,
  };

  static LeaderboardEntry fromJson(Map<String, Object?> json) =>
      LeaderboardEntry(
        rank: (json['rank'] as num).toInt(),
        player: PlayerSummary.fromJson((json['player'] as Map).cast()),
        score: (json['score'] as num).toInt(),
        detail: json['detail'] as String,
        pipsEarned: (json['pipsEarned'] as num?)?.toInt() ?? 0,
        badgesEarned: ((json['badgesEarned'] as List?) ?? const [])
            .cast<String>(),
      );
}

class MatchResults {
  const MatchResults({
    required this.roomCode,
    required this.experience,
    required this.entries,
    required this.checksum,
    required this.durationMs,
  });

  final String roomCode;
  final ExperienceKind experience;
  final List<LeaderboardEntry> entries;

  /// Deterministic digest of the ranking so clients can prove they show the
  /// same result.
  final String checksum;
  final int durationMs;

  Map<String, Object?> toJson() => {
    'roomCode': roomCode,
    'experience': experience.id,
    'entries': entries.map((e) => e.toJson()).toList(),
    'checksum': checksum,
    'durationMs': durationMs,
  };

  static MatchResults fromJson(Map<String, Object?> json) => MatchResults(
    roomCode: json['roomCode'] as String,
    experience: ExperienceKind.fromId(json['experience'] as String)!,
    entries: ((json['entries'] as List?) ?? const [])
        .map((e) => LeaderboardEntry.fromJson((e as Map).cast()))
        .toList(),
    checksum: json['checksum'] as String,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
  );

  /// Computes the checksum for a list of entries: a stable string built from
  /// rank, player name, score and detail. Uses only string operations so the
  /// value is identical on every platform.
  static String computeChecksum(Iterable<LeaderboardEntry> entries) {
    var h = 7;
    for (final e in entries) {
      final line = '${e.rank}|${e.player.name}|${e.score}|${e.detail}';
      for (final code in line.codeUnits) {
        h = (h * 31 + code) % 1000000007;
      }
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}
