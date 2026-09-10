import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lastfort_core/lastfort_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locally persisted player profile: name, equipped cosmetics, Fort Pass XP
/// and career statistics. Stored with `shared_preferences` on every platform.
class Profile extends ChangeNotifier {
  Profile(this._prefs, {String? forcedName}) {
    final stored = _prefs.getString('name');
    name = forcedName ?? stored ?? _defaultName();
    if (forcedName == null && stored == null) _prefs.setString('name', name);
    loadout = Loadout.fromJson(_decode(_prefs.getString('loadout')));
    xp = _prefs.getInt('xp') ?? 0;
    unlocked = {...defaultUnlocked, ...?_prefs.getStringList('unlocked')};
    claimedTiers = {...?_prefs.getStringList('claimed')?.map(int.parse)};
    career = CareerStats.fromJson(_decode(_prefs.getString('career')));
    themeMode = _prefs.getString('theme') ?? 'system';
    serverUrl = _prefs.getString('server');
    reducedMotion = _prefs.getBool('reducedMotion') ?? false;
    sound = _prefs.getBool('sound') ?? true;
    haptics = _prefs.getBool('haptics') ?? true;
    seenIntro = _prefs.getBool('seenIntro') ?? false;
  }

  static Future<Profile> load({String? forcedName}) async {
    final prefs = await SharedPreferences.getInstance();
    return Profile(prefs, forcedName: forcedName);
  }

  final SharedPreferences _prefs;

  late String name;
  late Loadout loadout;
  late int xp;
  late Set<String> unlocked;
  late Set<int> claimedTiers;
  late CareerStats career;
  late String themeMode;
  String? serverUrl;
  late bool reducedMotion;
  late bool sound;
  late bool haptics;
  late bool seenIntro;

  int get level => tierForXp(xp);
  int get xpIntoTier => xp - level * xpPerTier;
  double get tierProgress =>
      level >= passTiers.length ? 1 : xpIntoTier / xpPerTier;

  /// Tiers whose XP requirement is met but whose reward is not yet claimed.
  List<PassTier> get claimable => [
    for (final t in passTiers)
      if (xp >= t.xpRequired && !claimedTiers.contains(t.tier)) t,
  ];

  bool owns(String cosmeticId) => unlocked.contains(cosmeticId);

  Cosmetic equipped(CosmeticSlot slot) => cosmeticById(loadout.idFor(slot));

  Future<void> setName(String v) async {
    name = v.trim().isEmpty ? _defaultName() : v.trim();
    await _prefs.setString('name', name);
    notifyListeners();
  }

  Future<void> equip(Cosmetic c) async {
    if (!owns(c.id)) return;
    loadout = loadout.withSlot(c.slot, c.id);
    await _prefs.setString('loadout', jsonEncode(loadout.toJson()));
    notifyListeners();
  }

  Future<void> claim(PassTier tier) async {
    if (xp < tier.xpRequired || claimedTiers.contains(tier.tier)) return;
    claimedTiers.add(tier.tier);
    unlocked.add(tier.rewardId);
    await _prefs.setStringList('claimed', [for (final t in claimedTiers) '$t']);
    await _prefs.setStringList('unlocked', unlocked.toList());
    notifyListeners();
  }

  /// Applies a match summary row for this player and returns the XP gained.
  Future<int> recordMatch(Map<String, Object?> row, {required bool won}) async {
    final gained = (row['xp'] as num? ?? 0).toInt();
    xp += gained;
    career.matches++;
    if (won) career.wins++;
    career.kills += (row['kills'] as num? ?? 0).toInt();
    career.damage += (row['damage'] as num? ?? 0).toInt();
    career.harvested += (row['harvested'] as num? ?? 0).toInt();
    career.built += (row['built'] as num? ?? 0).toInt();
    final place = (row['placement'] as num? ?? 0).toInt();
    if (place > 0 &&
        (career.bestPlacement == 0 || place < career.bestPlacement)) {
      career.bestPlacement = place;
    }
    await _prefs.setInt('xp', xp);
    await _prefs.setString('career', jsonEncode(career.toJson()));
    notifyListeners();
    return gained;
  }

  Future<void> setThemeMode(String v) async {
    themeMode = v;
    await _prefs.setString('theme', v);
    notifyListeners();
  }

  Future<void> setServerUrl(String? v) async {
    serverUrl = (v == null || v.trim().isEmpty) ? null : v.trim();
    if (serverUrl == null) {
      await _prefs.remove('server');
    } else {
      await _prefs.setString('server', serverUrl!);
    }
    notifyListeners();
  }

  Future<void> setToggles({
    bool? reducedMotion,
    bool? sound,
    bool? haptics,
  }) async {
    if (reducedMotion != null) {
      this.reducedMotion = reducedMotion;
      await _prefs.setBool('reducedMotion', reducedMotion);
    }
    if (sound != null) {
      this.sound = sound;
      await _prefs.setBool('sound', sound);
    }
    if (haptics != null) {
      this.haptics = haptics;
      await _prefs.setBool('haptics', haptics);
    }
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    seenIntro = true;
    await _prefs.setBool('seenIntro', true);
    notifyListeners();
  }

  String? get sessionToken => _prefs.getString('token');
  Future<void> saveSessionToken(String? token) async {
    if (token == null) {
      await _prefs.remove('token');
    } else {
      await _prefs.setString('token', token);
    }
  }

  static String _defaultName() {
    const adjectives = ['Swift', 'Ember', 'Storm', 'Quiet', 'Iron', 'Salt'];
    const nouns = ['Fox', 'Warden', 'Kite', 'Ridge', 'Lantern', 'Drift'];
    final ms = DateTime.now().millisecondsSinceEpoch;
    return '${adjectives[ms % adjectives.length]}${nouns[(ms ~/ 7) % nouns.length]}';
  }

  static Map<String, Object?>? _decode(String? s) {
    if (s == null) return null;
    final v = jsonDecode(s);
    return v is Map<String, Object?> ? v : null;
  }
}

class CareerStats {
  int matches = 0;
  int wins = 0;
  int kills = 0;
  int damage = 0;
  int harvested = 0;
  int built = 0;
  int bestPlacement = 0;

  Map<String, Object?> toJson() => {
    'matches': matches,
    'wins': wins,
    'kills': kills,
    'damage': damage,
    'harvested': harvested,
    'built': built,
    'best': bestPlacement,
  };

  static CareerStats fromJson(Map<String, Object?>? j) {
    final s = CareerStats();
    if (j == null) return s;
    s.matches = (j['matches'] as num? ?? 0).toInt();
    s.wins = (j['wins'] as num? ?? 0).toInt();
    s.kills = (j['kills'] as num? ?? 0).toInt();
    s.damage = (j['damage'] as num? ?? 0).toInt();
    s.harvested = (j['harvested'] as num? ?? 0).toInt();
    s.built = (j['built'] as num? ?? 0).toInt();
    s.bestPlacement = (j['best'] as num? ?? 0).toInt();
    return s;
  }
}
