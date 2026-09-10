import 'dart:convert';

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:sqlite3/sqlite3.dart';

/// Persistent player record.
class PlayerRecord {
  PlayerRecord({
    required this.id,
    required this.name,
    required this.token,
    required this.avatar,
    required this.pips,
    required this.owned,
    required this.badges,
    required this.createdAt,
    required this.dailyStreak,
    required this.lastDailyClaim,
    required this.stats,
    required this.plot,
  });

  final String id;
  final String name;
  final String token;
  Avatar avatar;
  int pips;
  final Set<String> owned;
  final List<String> badges;
  final int createdAt;
  int dailyStreak;
  int? lastDailyClaim;
  final Map<String, int> stats;
  TycoonPlot plot;

  PlayerSummary summary({String platform = 'unknown', bool online = true}) =>
      PlayerSummary(
        id: id,
        name: name,
        avatar: avatar,
        platform: platform,
        online: online,
      );

  PlayerProfile profile({String platform = 'unknown', bool online = true}) =>
      PlayerProfile(
        summary: summary(platform: platform, online: online),
        pips: pips,
        owned: owned,
        badges: badges,
        createdAt: createdAt,
        dailyStreak: dailyStreak,
        lastDailyClaim: lastDailyClaim,
        stats: stats,
      );

  /// Awards a badge; returns true if it was new.
  bool award(String badgeId) {
    if (badges.contains(badgeId)) return false;
    badges.add(badgeId);
    return true;
  }

  void bump(String stat, [int by = 1]) => stats[stat] = (stats[stat] ?? 0) + by;
}

class FriendRow {
  const FriendRow(this.fromId, this.toId, this.accepted);

  final String fromId;
  final String toId;
  final bool accepted;
}

/// SQLite-backed store for players and friendships.
class Store {
  Store(String path) : _db = sqlite3.open(path) {
    _db.execute('''
      PRAGMA journal_mode = WAL;
      CREATE TABLE IF NOT EXISTS players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        token TEXT NOT NULL UNIQUE,
        avatar TEXT NOT NULL,
        pips INTEGER NOT NULL,
        owned TEXT NOT NULL,
        badges TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        daily_streak INTEGER NOT NULL DEFAULT 0,
        last_daily_claim INTEGER,
        stats TEXT NOT NULL DEFAULT '{}',
        plot TEXT NOT NULL DEFAULT '{}'
      );
      CREATE TABLE IF NOT EXISTS friends (
        from_id TEXT NOT NULL,
        to_id TEXT NOT NULL,
        accepted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (from_id, to_id)
      );
    ''');
  }

  final Database _db;

  int get playerCount =>
      _db.select('SELECT COUNT(*) AS n FROM players').first['n'] as int;

  PlayerRecord? byName(String name) =>
      _first('SELECT * FROM players WHERE name = ? COLLATE NOCASE', [name]);

  PlayerRecord? byToken(String token) =>
      _first('SELECT * FROM players WHERE token = ?', [token]);

  PlayerRecord? byId(String id) =>
      _first('SELECT * FROM players WHERE id = ?', [id]);

  PlayerRecord? _first(String sql, List<Object?> args) {
    final rows = _db.select(sql, args);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  PlayerRecord _fromRow(Row r) => PlayerRecord(
    id: r['id'] as String,
    name: r['name'] as String,
    token: r['token'] as String,
    avatar: Avatar.fromJson(_map(r['avatar'])),
    pips: r['pips'] as int,
    owned: (jsonDecode(r['owned'] as String) as List).cast<String>().toSet(),
    badges: (jsonDecode(r['badges'] as String) as List).cast<String>(),
    createdAt: r['created_at'] as int,
    dailyStreak: r['daily_streak'] as int,
    lastDailyClaim: r['last_daily_claim'] as int?,
    stats: _map(r['stats']).map((k, v) => MapEntry(k, (v as num).toInt())),
    plot: TycoonPlot.fromJson(_map(r['plot'])),
  );

  Map<String, Object?> _map(Object? raw) =>
      ((jsonDecode(raw as String) as Map?) ?? const {}).cast<String, Object?>();

  PlayerRecord create({
    required String id,
    required String name,
    required String token,
    required int nowMs,
    Avatar avatar = const Avatar(),
  }) {
    final record = PlayerRecord(
      id: id,
      name: name,
      token: token,
      avatar: avatar,
      pips: 100,
      owned: {'face_smile', 'hat_none', 'acc_none'},
      badges: ['welcome'],
      createdAt: nowMs,
      dailyStreak: 0,
      lastDailyClaim: null,
      stats: {},
      plot: TycoonPlot(),
    );
    _db.execute(
      'INSERT INTO players (id, name, token, avatar, pips, owned, badges, '
      'created_at, daily_streak, last_daily_claim, stats, plot) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      _values(record),
    );
    return record;
  }

  void save(PlayerRecord p) {
    _db.execute(
      'UPDATE players SET avatar = ?, pips = ?, owned = ?, badges = ?, '
      'daily_streak = ?, last_daily_claim = ?, stats = ?, plot = ? WHERE id = ?',
      [
        jsonEncode(p.avatar.toJson()),
        p.pips,
        jsonEncode(p.owned.toList()..sort()),
        jsonEncode(p.badges),
        p.dailyStreak,
        p.lastDailyClaim,
        jsonEncode(p.stats),
        jsonEncode(p.plot.toJson()),
        p.id,
      ],
    );
  }

  List<Object?> _values(PlayerRecord p) => [
    p.id,
    p.name,
    p.token,
    jsonEncode(p.avatar.toJson()),
    p.pips,
    jsonEncode(p.owned.toList()..sort()),
    jsonEncode(p.badges),
    p.createdAt,
    p.dailyStreak,
    p.lastDailyClaim,
    jsonEncode(p.stats),
    jsonEncode(p.plot.toJson()),
  ];

  // Friends -----------------------------------------------------------------

  List<FriendRow> friendRowsFor(String playerId) => _db
      .select('SELECT * FROM friends WHERE from_id = ? OR to_id = ?', [
        playerId,
        playerId,
      ])
      .map(
        (r) => FriendRow(
          r['from_id'] as String,
          r['to_id'] as String,
          r['accepted'] == 1,
        ),
      )
      .toList();

  FriendRow? friendRow(String a, String b) {
    final rows = _db.select(
      'SELECT * FROM friends WHERE (from_id = ? AND to_id = ?) '
      'OR (from_id = ? AND to_id = ?)',
      [a, b, b, a],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return FriendRow(
      r['from_id'] as String,
      r['to_id'] as String,
      r['accepted'] == 1,
    );
  }

  void addRequest(String from, String to) => _db.execute(
    'INSERT OR IGNORE INTO friends (from_id, to_id, accepted) VALUES (?, ?, 0)',
    [from, to],
  );

  void acceptRequest(String from, String to) => _db.execute(
    'UPDATE friends SET accepted = 1 WHERE from_id = ? AND to_id = ?',
    [from, to],
  );

  void removeFriendship(String a, String b) => _db.execute(
    'DELETE FROM friends WHERE (from_id = ? AND to_id = ?) '
    'OR (from_id = ? AND to_id = ?)',
    [a, b, b, a],
  );

  void close() => _db.close();
}
