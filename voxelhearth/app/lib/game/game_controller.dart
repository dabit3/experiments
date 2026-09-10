import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../net/game_client.dart';
import 'atlas.dart';
import 'renderer.dart';
import 'voxel_view.dart';

/// Local simulation of the player: input, prediction, targeting and the
/// per-frame scene description handed to the renderer.
class GameController extends ChangeNotifier {
  GameController(this.client, this.session, this.assets) : view = VoxelView(session.world) {
    physics = Physics(session.world);
    body.setPos(session.spawnX, session.spawnY, session.spawnZ);
    camera.yaw = session.spawnYaw;
    camera.pitch = session.spawnPitch;
    view.follow(body.x, body.z);
    _effectSub = client.effects.stream.listen(_onEffect);
    _worldSub = client.worldEvents.stream.listen(_onWorldEvent);
  }

  final GameClient client;
  final RoomSession session;
  final RenderAssets assets;
  final VoxelView view;
  late final Physics physics;
  final Body body = Body(width: Move.playerWidth, height: Move.playerHeight);
  final Camera camera = Camera();

  // input
  final Set<LogicalKeyboardKey> keys = <LogicalKeyboardKey>{};
  double joyX = 0, joyY = 0; // touch joystick -1..1
  bool touchJump = false, touchSneak = false, touchSprint = false, touchUp = false, touchDown = false;
  bool flying = false;
  bool mouseLook = false;
  double lookSensitivity = 0.0022;
  bool invertY = false;

  // state
  RayHit? target;
  int? targetEntity;
  double breakProgress = 0;
  bool breaking = false;
  double _breakCooldown = 0;
  double damageFlash = 0;
  double anim = 0;
  double _sendTimer = 0;
  double _timeLerp = 0;
  double pixelScale = 1;
  double _frameAvg = 16;
  int fps = 60;
  int _fpsCount = 0;
  double _fpsTimer = 0;
  bool paused = false;
  bool chatOpen = false;
  String? overlay; // 'inventory' | 'workbench' | 'chest' | 'kiln' | 'pause' | 'settings'
  bool dead = false;
  String deathCause = '';
  int lastHp = 20;
  ui.Image? entityImage;
  final List<Particle> particles = <Particle>[];
  final math.Random _rng = math.Random(7);
  StreamSubscription<Map<String, Object?>>? _effectSub;
  StreamSubscription<Map<String, Object?>>? _worldSub;
  bool _disposed = false;
  final List<String> hudToasts = <String>[];
  double swing = 0; // arm swing animation 0..1
  String? pickupText;
  double pickupTimer = 0;
  double heldLabelAge = 10;
  int _seq = 0;
  final Set<int> _pendingChunkRefresh = <int>{};

  bool get isCreative => session.mode == GameMode.creative;
  bool get inputBlocked => paused || chatOpen || overlay != null || dead || session.phase != Phase.playing;

  // ---------------------------------------------------------------- effects

  void _onEffect(Map<String, Object?> e) {
    final kind = jstr(e, 'kind');
    switch (kind) {
      case 'hurt_local':
        damageFlash = 1;
        _shake = 0.25;
        HapticFeedback.heavyImpact();
      case 'teleport':
        body.setPos(jdouble(e, 'x'), jdouble(e, 'y'), jdouble(e, 'z'));
        body.vx = body.vy = body.vz = 0;
      case 'break':
        _spawnBurst(
          jint(e, 'x') + 0.5,
          jint(e, 'y') + 0.5,
          jint(e, 'z') + 0.5,
          assets.atlas.average(_tileOf(jint(e, 'id'))),
          14,
        );
      case 'place':
        _spawnBurst(
          jint(e, 'x') + 0.5,
          jint(e, 'y') + 0.5,
          jint(e, 'z') + 0.5,
          assets.atlas.average(_tileOf(jint(e, 'id'))),
          5,
          speed: 1.2,
        );
      case 'craft':
        pickupText = '+${jint(e, 'count')} ${Registry.nameOf(jint(e, 'id'))}';
        pickupTimer = 2.2;
        HapticFeedback.lightImpact();
      case 'eat':
        pickupText = 'Yum';
        pickupTimer = 1.4;
      case 'hit':
        _spawnBurst(jdouble(e, 'x'), jdouble(e, 'y'), jdouble(e, 'z'), 0xffd94a3a, 8, speed: 2.5);
      case 'mob_died':
        _spawnBurst(jdouble(e, 'x'), jdouble(e, 'y') + 0.5, jdouble(e, 'z'), 0xffe0e0e0, 18, speed: 3);
      case 'inventory_full':
        pickupText = 'Inventory full';
        pickupTimer = 1.5;
      case 'died':
        dead = true;
        deathCause = jstr(e, 'cause');
        overlay = null;
        breaking = false;
      case 'mob_attack':
        _shake = math.max(_shake, 0.1);
      case 'open_ui':
        final ui = jstr(e, 'ui');
        overlay = ui == ContainerKind.inventory ? (overlay == 'inventory' ? 'inventory' : null) : ui;
        if (overlay != null) {
          breaking = false;
          breakProgress = 0;
        }
      case 'phase':
        if (session.phase == Phase.playing) {
          dead = false;
          overlay = null;
          paused = false;
          body.setPos(session.spawnX, session.spawnY, session.spawnZ);
          body.vx = body.vy = body.vz = 0;
          _unstick();
        } else {
          overlay = null;
          breaking = false;
        }
    }
    notifyListeners();
  }

  int _tileOf(int id) => id == Ids.air ? 0 : itemTileFor(id);

  void _onWorldEvent(Map<String, Object?> e) {
    if (jstr(e, 't') == 'chunk') {
      _pendingChunkRefresh.add(ChunkKey.of(jint(e, 'cx'), jint(e, 'cz')));
    } else {
      view.blockChanged(jint(e, 'x'), jint(e, 'y'), jint(e, 'z'));
      final id = jint(e, 'id');
      if (id == Ids.air) {
        // settle particles nothing; server sends effect separately
      }
    }
  }

  // ---------------------------------------------------------------- frame

  double _shake = 0;

  void update(double dt) {
    if (_disposed) return;
    // Digging follows the wall clock so a slow frame rate never slows the pick.
    final wallDt = dt.clamp(0.0, 0.5);
    dt = dt.clamp(0, 0.05);
    anim += dt;
    _fpsTimer += dt;
    _fpsCount++;
    if (_fpsTimer >= 0.5) {
      fps = (_fpsCount / _fpsTimer).round();
      _fpsTimer = 0;
      _fpsCount = 0;
    }
    _adaptResolution(dt);
    _applyPendingChunks();
    _tickTime(dt);
    _movement(dt);
    view.follow(body.x, body.z);
    _interpolate(dt);
    _targeting();
    _breaking(wallDt);
    _particles(dt);
    if (damageFlash > 0) damageFlash = math.max(0, damageFlash - dt * 2.2);
    if (_shake > 0) _shake = math.max(0, _shake - dt);
    if (swing > 0) swing = math.max(0, swing - dt * 4);
    heldLabelAge += dt;
    if (pickupTimer > 0) {
      pickupTimer -= dt;
      if (pickupTimer <= 0) pickupText = null;
    }
    if (session.hp <= 0 && !dead && !isCreative) {
      dead = true;
      overlay = null;
      notifyListeners();
    }
    _sendTimer += dt;
    if (_sendTimer >= 0.05) {
      _sendTimer = 0;
      _sendMove();
    }
    _uploadEntities();
    view.upload().then((_) => _checkLoaded());
    _checkLoaded();
  }

  bool _wasLoaded = false;

  /// The world is playable once the voxel textures exist and the chunk under
  /// the player has arrived.
  bool get loaded => view.ready && spawnReady;

  void _checkLoaded() {
    if (_disposed) return;
    final now = loaded;
    if (now != _wasLoaded) {
      _wasLoaded = now;
      notifyListeners();
    }
  }

  void _applyPendingChunks() {
    if (_pendingChunkRefresh.isEmpty) return;
    var n = 0;
    for (final k in _pendingChunkRefresh.toList()) {
      view.chunkChanged(ChunkKey.cxOf(k), ChunkKey.czOf(k));
      _pendingChunkRefresh.remove(k);
      if (++n >= 3) break;
    }
  }

  void _adaptResolution(double dt) {
    _frameAvg = _frameAvg * 0.92 + dt * 1000 * 0.08;
    if (_frameAvg > 21 && pixelScale < 3) {
      pixelScale = math.min(3, pixelScale + 0.02);
    } else if (_frameAvg < 13 && pixelScale > 1) {
      pixelScale = math.max(1, pixelScale - 0.01);
    }
  }

  double smoothTime = 1000;
  void _tickTime(double dt) {
    // Advance smoothly between snapshots.
    if (!session.freezeTime && session.phase == Phase.playing) {
      _timeLerp += dt * WorldConst.ticksPerSecond;
    }
    final target = session.time.toDouble();
    final predicted = target + _timeLerp;
    smoothTime = predicted % WorldConst.dayTicks;
    // Reset accumulated lerp whenever a new snapshot arrives.
    if (DateTime.now().difference(session.lastSnapshot).inMilliseconds < 60) _timeLerp = 0;
  }

  double get dayFraction => smoothTime / WorldConst.dayTicks;

  bool get isNight {
    final t = smoothTime;
    return t >= 13000 && t <= 23000;
  }

  // ---------------------------------------------------------------- movement

  bool _key(List<LogicalKeyboardKey> ks) => ks.any(keys.contains);

  void _movement(double dt) {
    if (session.phase != Phase.playing || !spawnReady) return;
    if (!_unstuckAtSpawn) _unstick();
    var fwd = 0.0, strafe = 0.0;
    var jump = false, sneak = false, sprint = false;
    var flyUp = 0.0;
    if (!inputBlocked) {
      if (_key([LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp])) fwd += 1;
      if (_key([LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown])) fwd -= 1;
      if (_key([LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight])) strafe += 1;
      if (_key([LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft])) strafe -= 1;
      jump = _key([LogicalKeyboardKey.space]) || touchJump;
      sneak = _key([LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight]) || touchSneak;
      sprint =
          _key([LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight, LogicalKeyboardKey.metaLeft]) ||
          touchSprint;
      fwd += -joyY;
      strafe += joyX;
      if (flying) {
        if (jump || touchUp) flyUp += 1;
        if (sneak || touchDown) flyUp -= 1;
      }
    }
    final len = math.sqrt(fwd * fwd + strafe * strafe);
    if (len > 1) {
      fwd /= len;
      strafe /= len;
    }
    final speed = flying
        ? Move.flySpeed
        : (body.inWater
              ? Move.swimSpeed
              : (sneak ? Move.sneakSpeed : (sprint && fwd > 0 ? Move.sprintSpeed : Move.walkSpeed)));
    final sy = math.sin(camera.yaw), cy = math.cos(camera.yaw);
    final wishX = (sy * fwd + cy * strafe) * speed;
    final wishZ = (cy * fwd - sy * strafe) * speed;
    body.flying = flying && isCreative;
    if (!body.flying) flying = false;
    if (sneak && body.onGround && !body.flying) {
      _sneakStep(dt, wishX, wishZ, jump && !flying);
    } else {
      physics.step(body, dt, wishX, wishZ, jump: jump && !flying, wishY: flyUp * Move.flySpeed * 0.8);
    }
    if (body.y < -8) {
      body.setPos(session.spawnX, session.spawnY, session.spawnZ);
      body.vy = 0;
    }
    // camera at eye height with a light head-bob when walking
    final moving = body.onGround && (body.vx.abs() + body.vz.abs()) > 0.5 && !sneak;
    final bob = moving ? math.sin(anim * 11) * 0.03 : 0.0;
    final shake = _shake > 0 ? (_rng.nextDouble() - 0.5) * _shake * 0.2 : 0.0;
    camera.x = body.x;
    camera.y = body.y + (sneak && !flying ? Move.sneakEye : Move.eyeHeight) + bob + shake;
    camera.z = body.z;
    _sneaking = sneak;
    _sprinting = sprint;
  }

  bool _sneaking = false, _sprinting = false;

  /// Sneaking never walks off an edge: reject moves that would leave the
  /// ground.
  void _sneakStep(double dt, double wishX, double wishZ, bool jump) {
    final ox = body.x, oz = body.z;
    physics.step(body, dt, wishX, wishZ, jump: jump);
    if (!body.onGround && body.vy <= 0 && !physics.blocked(body, body.x, body.y - 0.3, body.z)) {
      // would fall: undo the horizontal move
      body.setPos(ox, body.y, oz);
      body.vx = 0;
      body.vz = 0;
      body.onGround = true;
    }
  }

  bool _unstuckAtSpawn = false;

  /// Nudge the body up out of any solid block. Unloaded chunks read as
  /// bedrock, so this only runs once the chunk under the player exists.
  void _unstick() {
    if (!spawnReady) {
      _unstuckAtSpawn = false;
      return;
    }
    _unstuckAtSpawn = true;
    var guard = 0;
    while (physics.blocked(body, body.x, body.y, body.z) && guard++ < 60) {
      body.y += 1;
    }
  }

  void look(double dx, double dy) {
    if (inputBlocked) return;
    camera.yaw -= dx * lookSensitivity;
    camera.pitch += (invertY ? 1 : -1) * dy * lookSensitivity;
    camera.pitch = camera.pitch.clamp(-math.pi / 2 + 0.01, math.pi / 2 - 0.01);
  }

  void _sendMove() {
    if (session.phase != Phase.playing) return;
    client.send({
      't': Msg.move,
      'x': _r(body.x),
      'y': _r(body.y),
      'z': _r(body.z),
      'vx': _r(body.vx),
      'vy': _r(body.vy),
      'vz': _r(body.vz),
      'yaw': _r(camera.yaw),
      'pitch': _r(camera.pitch),
      'ground': body.onGround,
      'sneak': _sneaking,
      'sprint': _sprinting,
      'fly': body.flying,
      'seq': _seq++,
    });
  }

  static double _r(double v) => (v * 1000).roundToDouble() / 1000;

  // ---------------------------------------------------------------- entities

  void _interpolate(double dt) {
    final k = dt * 20;
    for (final p in session.players.values) {
      p.lerp = math.min(1, p.lerp + k);
    }
    for (final m in session.mobs.values) {
      m.lerp = math.min(1, m.lerp + k);
    }
  }

  List<EntityDraw> entityList() {
    final out = <EntityDraw>[];
    final cx = camera.x, cz = camera.z;
    for (final p in session.players.values) {
      if (p.id == session.youId) continue;
      final d = (p.rx - cx) * (p.rx - cx) + (p.rz - cz) * (p.rz - cz);
      if (d > 80 * 80) continue;
      out.add(EntityDraw(p.rx, p.ry, p.rz, p.yaw, 0, p.id.hashCode & 0x7fffffff, p.hp < 20 && p.hp <= 6));
    }
    for (final m in session.mobs.values) {
      final d = (m.rx - cx) * (m.rx - cx) + (m.rz - cz) * (m.rz - cz);
      if (d > 80 * 80) continue;
      final kind = switch (m.kind) {
        'mossback' => 1,
        'hollow' => 2,
        _ => 3,
      };
      out.add(EntityDraw(m.rx, m.ry, m.rz, m.yaw, kind, m.id, m.hurt));
    }
    out.sort((a, b) {
      final da = (a.x - cx) * (a.x - cx) + (a.z - cz) * (a.z - cz);
      final db = (b.x - cx) * (b.x - cx) + (b.z - cz) * (b.z - cz);
      return da.compareTo(db);
    });
    return out.length > 24 ? out.sublist(0, 24) : out;
  }

  List<EntityDraw> _lastEntities = const [];
  bool _entityUploading = false;

  void _uploadEntities() {
    if (_entityUploading) return;
    final ents = entityList();
    _lastEntities = ents;
    _entityUploading = true;
    final bytes = packEntities(ents, view.ox, view.oz);
    ui.decodeImageFromPixels(bytes, 128, 1, ui.PixelFormat.rgba8888, (img) {
      if (_disposed) {
        img.dispose();
        return;
      }
      entityImage?.dispose();
      entityImage = img;
      _entityUploading = false;
    });
  }

  // ---------------------------------------------------------------- targeting

  void _targeting() {
    final f = camera.forward;
    target = raycast(session.world, camera.x, camera.y, camera.z, f[0], f[1], f[2], Move.reach);
    // entity under the crosshair (closer than the block)
    targetEntity = null;
    var best = target?.dist ?? Move.reach;
    for (final m in session.mobs.values) {
      final t = _rayBox(
        camera.x,
        camera.y,
        camera.z,
        f[0],
        f[1],
        f[2],
        m.rx - 0.45,
        m.ry,
        m.rz - 0.45,
        m.rx + 0.45,
        m.ry + 1.9,
        m.rz + 0.45,
      );
      if (t != null && t < best) {
        best = t;
        targetEntity = m.id;
      }
    }
  }

  double? _rayBox(
    double ox,
    double oy,
    double oz,
    double dx,
    double dy,
    double dz,
    double x0,
    double y0,
    double z0,
    double x1,
    double y1,
    double z1,
  ) {
    double tmin = -1e9, tmax = 1e9;
    for (final a in [
      [ox, dx, x0, x1],
      [oy, dy, y0, y1],
      [oz, dz, z0, z1],
    ]) {
      final o = a[0], d = a[1];
      if (d.abs() < 1e-9) {
        if (o < a[2] || o > a[3]) return null;
        continue;
      }
      var t0 = (a[2] - o) / d, t1 = (a[3] - o) / d;
      if (t0 > t1) {
        final tmp = t0;
        t0 = t1;
        t1 = tmp;
      }
      tmin = math.max(tmin, t0);
      tmax = math.min(tmax, t1);
      if (tmin > tmax) return null;
    }
    if (tmax < 0) return null;
    return tmin < 0 ? 0 : tmin;
  }

  void _breaking(double dt) {
    if (_breakCooldown > 0) _breakCooldown -= dt;
    if (!breaking || inputBlocked) {
      breakProgress = 0;
      _breakTarget = null;
      return;
    }
    final t = target;
    if (t == null) {
      breakProgress = 0;
      _breakTarget = null;
      return;
    }
    final key = BlockPos.key(t.x, t.y, t.z);
    if (_breakTarget != key) {
      _breakTarget = key;
      breakProgress = 0;
    }
    final def = Registry.block(t.id);
    if (def.hardness < 0 && !isCreative) return;
    swing = 1;
    final secs = isCreative ? 0.12 : Registry.breakSeconds(t.id, session.inventory[session.selected].id);
    breakProgress += dt / math.max(0.05, secs);
    if (breakProgress >= 1 && _breakCooldown <= 0) {
      client.send({'t': Msg.breakBlock, 'x': t.x, 'y': t.y, 'z': t.z});
      // predict locally so the world responds instantly
      session.world.set(t.x, t.y, t.z, Ids.air);
      view.blockChanged(t.x, t.y, t.z);
      breakProgress = 0;
      _breakCooldown = isCreative ? 0.18 : 0.3;
      HapticFeedback.mediumImpact();
    }
  }

  int? _breakTarget;

  void startBreak() {
    if (inputBlocked) return;
    final te = targetEntity;
    if (te != null) {
      client.send({'t': Msg.attack, 'id': te});
      swing = 1;
      HapticFeedback.selectionClick();
      return;
    }
    breaking = true;
  }

  void stopBreak() {
    breaking = false;
    breakProgress = 0;
  }

  /// Quick tap on touch: hit whatever is under the crosshair.
  void tapBreak() {
    if (inputBlocked) return;
    swing = 1;
    final te = targetEntity;
    if (te != null) {
      client.send({'t': Msg.attack, 'id': te});
      HapticFeedback.selectionClick();
    }
  }

  void setChatOpen(bool open) {
    chatOpen = open;
    if (open) {
      breaking = false;
      keys.clear();
    }
    notifyListeners();
  }

  void setPaused(bool p) {
    paused = p;
    if (p) {
      breaking = false;
      keys.clear();
    }
    notifyListeners();
  }

  /// True once the chunk under the player has arrived from the server.
  bool get spawnReady => session.world.isLoaded(body.x.floor(), body.z.floor());

  /// Right click / secondary tap: interact, eat or place.
  void use() {
    if (inputBlocked) return;
    swing = 1;
    final held = session.inventory[session.selected];
    final t = target;
    if (t != null && !_sneaking) {
      if (t.id == Ids.workbench || t.id == Ids.chest || t.id == Ids.kiln || t.id == Ids.bed) {
        client.send({'t': Msg.interact, 'x': t.x, 'y': t.y, 'z': t.z});
        return;
      }
    }
    if (held.isNotEmpty && held.def.food > 0) {
      client.send({'t': Msg.eat});
      return;
    }
    if (t == null || held.isEmpty || !Registry.isBlock(held.id)) return;
    var px = t.x + t.nx, py = t.y + t.ny, pz = t.z + t.nz;
    final def = Registry.block(t.id);
    if (def.replaceable) {
      px = t.x;
      py = t.y;
      pz = t.z;
    }
    final placeDef = Registry.block(held.id);
    if (placeDef.solid && physics.blockOverlaps(body, px, py, pz)) return;
    client.send({'t': Msg.placeBlock, 'x': px, 'y': py, 'z': pz, 'nx': t.nx, 'ny': t.ny, 'nz': t.nz});
    HapticFeedback.lightImpact();
  }

  void selectSlot(int i) {
    final s = i.clamp(0, Inventory.hotbarSize - 1);
    if (session.selected == s) return;
    session.selected = s;
    heldLabelAge = 0;
    client.send({'t': Msg.selectSlot, 'slot': s});
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void scrollSlot(int dir) => selectSlot((session.selected + dir) % Inventory.hotbarSize);

  void toggleFly() {
    if (!isCreative) return;
    flying = !flying;
    if (flying) body.vy = 0;
  }

  // ---------------------------------------------------------------- keys

  bool handleKey(KeyEvent e) {
    final k = e.logicalKey;
    if (e is KeyDownEvent) {
      keys.add(k);
      if (chatOpen) return false;
      if (k == LogicalKeyboardKey.escape) {
        if (overlay != null) {
          closeOverlay();
        } else {
          paused = !paused;
        }
        notifyListeners();
        return true;
      }
      if (paused) return false;
      if (k == LogicalKeyboardKey.keyE) {
        if (overlay == null) {
          openInventory();
        } else {
          closeOverlay();
        }
        return true;
      }
      if (k == LogicalKeyboardKey.keyT || k == LogicalKeyboardKey.slash || k == LogicalKeyboardKey.enter) {
        if (overlay == null) {
          chatOpen = true;
          notifyListeners();
          return true;
        }
      }
      if (k == LogicalKeyboardKey.keyF) {
        toggleFly();
        return true;
      }
      if (k == LogicalKeyboardKey.keyQ) {
        client.send({'t': 'drop_item', 'slot': session.selected, 'count': 1});
        return true;
      }
      if (k == LogicalKeyboardKey.tab) {
        showRoster = !showRoster;
        notifyListeners();
        return true;
      }
      final digit = k.keyId - LogicalKeyboardKey.digit1.keyId;
      if (digit >= 0 && digit < 9) {
        selectSlot(digit);
        return true;
      }
    } else if (e is KeyUpEvent) {
      keys.remove(k);
    }
    return false;
  }

  bool showRoster = false;

  void openInventory() {
    overlay = 'inventory';
    breaking = false;
    notifyListeners();
  }

  void closeOverlay() {
    if (overlay != null && overlay != 'inventory' && overlay != 'pause' && overlay != 'settings') {
      client.send({'t': 'close_ui'});
    }
    overlay = null;
    session.openUi = null;
    notifyListeners();
  }

  void togglePause() {
    paused = !paused;
    notifyListeners();
  }

  void respawn() {
    client.send({'t': 'respawn'});
    dead = false;
    damageFlash = 0;
    notifyListeners();
  }

  // ---------------------------------------------------------------- particles

  void _spawnBurst(double x, double y, double z, int argb, int n, {double speed = 2.0}) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final b = (_rng.nextDouble() - 0.3) * math.pi;
      final s = speed * (0.4 + _rng.nextDouble());
      particles.add(
        Particle(
          x + (_rng.nextDouble() - 0.5) * 0.6,
          y + (_rng.nextDouble() - 0.5) * 0.6,
          z + (_rng.nextDouble() - 0.5) * 0.6,
          math.cos(a) * math.cos(b) * s,
          math.sin(b) * s + 1.5,
          math.sin(a) * math.cos(b) * s,
          argb,
          0.6 + _rng.nextDouble() * 0.5,
        ),
      );
    }
    if (particles.length > 300) particles.removeRange(0, particles.length - 300);
  }

  void _particles(double dt) {
    for (final p in particles) {
      p.life -= dt;
      p.vy -= 12 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.z += p.vz * dt;
      if (session.world.isSolid(p.x.floor(), p.y.floor(), p.z.floor())) {
        p.vy = 0;
        p.vx *= 0.5;
        p.vz *= 0.5;
        p.y = p.y.floorToDouble() + 1.001;
      }
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  /// Projects a world point to screen space; null when behind the camera.
  ui.Offset? project(double x, double y, double z, ui.Size size) {
    final f = camera.forward, r = camera.right, u = camera.up;
    final dx = x - camera.x, dy = y - camera.y, dz = z - camera.z;
    final depth = dx * f[0] + dy * f[1] + dz * f[2];
    if (depth < 0.05) return null;
    final px = dx * r[0] + dy * r[1] + dz * r[2];
    final py = dx * u[0] + dy * u[1] + dz * u[2];
    final tanY = math.tan(camera.fovDeg * math.pi / 360);
    final tanX = tanY * size.width / size.height;
    final sx = (px / depth / tanX + 1) * 0.5 * size.width;
    final sy = (1 - py / depth / tanY) * 0.5 * size.height;
    return ui.Offset(sx, sy);
  }

  SceneFrame frame() => SceneFrame(
    camera: camera,
    view: view,
    dayFraction: dayFraction,
    anim: anim,
    entities: _lastEntities,
    target: target == null || inputBlocked ? null : [target!.x, target!.y, target!.z],
    breakProgress: breakProgress,
    underwater: physics.headInFluid(body),
    damage: damageFlash,
    maxDist: 96,
    pixelScale: pixelScale,
  );

  // ---------------------------------------------------------------- test drive

  void _lookAtPoint(double tx, double ty, double tz) {
    final dx = tx - camera.x, dy = ty - camera.y, dz = tz - camera.z;
    camera.yaw = math.atan2(dx, dz);
    camera.pitch = math.atan2(dy, math.sqrt(dx * dx + dz * dz));
    _targeting();
  }

  /// Scripted input channel used by the automated cross-platform test.
  Future<Map<String, Object?>> drive(Map<String, Object?> a) async {
    final t = jstr(a, 't');
    switch (t) {
      case 'look':
        camera.yaw = jdouble(a, 'yaw', camera.yaw);
        camera.pitch = jdouble(a, 'pitch', camera.pitch);
        return {'ok': true};
      case 'look_at':
        _lookAtPoint(jdouble(a, 'x') + 0.5, jdouble(a, 'y') + 0.5, jdouble(a, 'z') + 0.5);
        return {
          'ok': true,
          'target': target == null ? null : [target!.x, target!.y, target!.z, target!.id],
        };
      case 'teleport':
        body.setPos(jdouble(a, 'x'), jdouble(a, 'y'), jdouble(a, 'z'));
        body.vx = body.vy = body.vz = 0;
        _unstick();
        _sendMove();
        return {'ok': true, 'x': body.x, 'y': body.y, 'z': body.z};
      case 'walk':
        // hold keys for a duration
        final dur = jdouble(a, 'seconds', 0.5);
        final dir = jstr(a, 'dir', 'forward');
        final key = switch (dir) {
          'back' => LogicalKeyboardKey.keyS,
          'left' => LogicalKeyboardKey.keyA,
          'right' => LogicalKeyboardKey.keyD,
          _ => LogicalKeyboardKey.keyW,
        };
        keys.add(key);
        if (jbool(a, 'jump')) keys.add(LogicalKeyboardKey.space);
        await Future<void>.delayed(Duration(milliseconds: (dur * 1000).round()));
        keys.remove(key);
        keys.remove(LogicalKeyboardKey.space);
        return {'ok': true, 'x': body.x, 'y': body.y, 'z': body.z};
      case 'break':
        final tx = jint(a, 'x'), ty = jint(a, 'y'), tz = jint(a, 'z');
        await drive({'t': 'look_at', 'x': tx, 'y': ty, 'z': tz});
        final hit = target;
        if (hit == null || hit.x != tx || hit.y != ty || hit.z != tz) {
          return {
            'ok': false,
            'error': 'target not under crosshair',
            'hit': hit == null ? null : [hit.x, hit.y, hit.z],
          };
        }
        breaking = true;
        final deadline = DateTime.now().add(const Duration(seconds: 12));
        while (session.world.peek(tx, ty, tz) != Ids.air && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
        breaking = false;
        return {'ok': session.world.peek(tx, ty, tz) == Ids.air};
      case 'place':
        // place held block onto face of (x,y,z) with normal (nx,ny,nz)
        final tx = jint(a, 'x'), ty = jint(a, 'y'), tz = jint(a, 'z');
        final look = await drive({'t': 'look_at', 'x': tx, 'y': ty, 'z': tz});
        final hit = target;
        if (hit == null) return {'ok': false, 'error': 'nothing targeted', 'look': look};
        use();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        return {
          'ok': true,
          'placedAt': [hit.x + hit.nx, hit.y + hit.ny, hit.z + hit.nz],
        };
      case 'place_at':
        // place exactly at (x,y,z) by looking at the supporting neighbour
        final tx = jint(a, 'x'), ty = jint(a, 'y'), tz = jint(a, 'z');
        for (final d in const [
          [0, -1, 0],
          [0, 1, 0],
          [1, 0, 0],
          [-1, 0, 0],
          [0, 0, 1],
          [0, 0, -1],
        ]) {
          final nx = tx + d[0], ny = ty + d[1], nz = tz + d[2];
          if (!Registry.block(session.world.peek(nx, ny, nz)).solid) continue;
          // Aim at the centre of the neighbour's face that touches the target.
          _lookAtPoint(nx + 0.5 - d[0] * 0.5, ny + 0.5 - d[1] * 0.5, nz + 0.5 - d[2] * 0.5);
          final hit = target;
          if (hit == null || hit.x != nx || hit.y != ny || hit.z != nz) continue;
          if (hit.x + hit.nx != tx || hit.y + hit.ny != ty || hit.z + hit.nz != tz) continue;
          use();
          final deadline = DateTime.now().add(const Duration(seconds: 4));
          while (session.world.peek(tx, ty, tz) == Ids.air && DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
          return {'ok': session.world.peek(tx, ty, tz) != Ids.air, 'block': session.world.peek(tx, ty, tz)};
        }
        return {'ok': false, 'error': 'no visible supporting face for $tx,$ty,$tz'};
      case 'select_slot':
        selectSlot(jint(a, 'slot'));
        return {'ok': true};
      case 'chat':
        client.send({'t': Msg.chat, 'text': jstr(a, 'text')});
        return {'ok': true};
      case 'give':
        client.send({'t': 'give', 'id': jint(a, 'id'), 'count': jint(a, 'count', 1), 'slot': jint(a, 'slot', -1)});
        return {'ok': true};
      case 'craft':
        client.send({'t': Msg.craft, 'grid': jints(a, 'grid'), 'n': jint(a, 'n', 2), 'count': jint(a, 'count', 1)});
        return {'ok': true};
      case 'open_inventory':
        openInventory();
        return {'ok': true};
      case 'close_overlay':
        closeOverlay();
        return {'ok': true};
      case 'toggle_chat':
        chatOpen = jbool(a, 'open', !chatOpen);
        notifyListeners();
        return {'ok': true};
      case 'pause':
        paused = jbool(a, 'on', !paused);
        notifyListeners();
        return {'ok': true};
      case 'state':
        return {
          'ok': true,
          'x': body.x,
          'y': body.y,
          'z': body.z,
          'yaw': camera.yaw,
          'pitch': camera.pitch,
          'phase': session.phase,
          'hp': session.hp,
          'food': session.food,
          'score': session.score,
          'selected': session.selected,
          'held': session.inventory[session.selected].toJson(),
          'worldHash': session.world.editsHash(),
          'chatHash': session.chatHash(),
          'chatLines': session.chat.length,
          'fps': fps,
          'pixelScale': pixelScale,
          'players': session.players.length,
          'ready': view.ready,
          'ground': body.onGround,
          'spawn': [session.spawnX, session.spawnY, session.spawnZ],
          'spawnReady': spawnReady,
        };
      case 'block':
        return {'ok': true, 'block': session.world.peek(jint(a, 'x'), jint(a, 'y'), jint(a, 'z'))};
      case 'wait_ready':
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while ((!view.ready || session.chunksReceived.length < 9) && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return {'ok': view.ready, 'chunks': session.chunksReceived.length};
      default:
        return {'ok': false, 'error': 'unknown drive action $t'};
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _effectSub?.cancel();
    _worldSub?.cancel();
    entityImage?.dispose();
    entityImage = null;
    view.dispose();
    super.dispose();
  }
}

class Particle {
  Particle(this.x, this.y, this.z, this.vx, this.vy, this.vz, this.color, this.life);
  double x, y, z, vx, vy, vz;
  final int color;
  double life;
}

/// Tile used to represent an item or block in 2D UI.
int itemTileFor(int id) {
  if (Registry.isBlock(id)) {
    final t = tilesFor(id);
    return t.side;
  }
  return itemTile(id);
}
