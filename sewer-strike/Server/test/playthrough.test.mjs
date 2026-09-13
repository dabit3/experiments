import test from 'node:test';
import assert from 'node:assert/strict';
import { Game } from '../game.mjs';

test('two input-only cooperative drivers can clear all waves and the boss', () => {
  const game = new Game('PLAY');
  game.addPlayer('a', 'Alpha', 0);
  game.addPlayer('b', 'Bravo', 2);
  game.ready('a'); game.ready('b');
  const history = new Set();
  for (let tick = 0; tick < 30 * 240 && !['clear', 'gameover'].includes(game.phase); tick++) {
    const state = game.snapshot();
    history.add(state.sector);
    if (tick % 3 === 0) {
      for (const p of state.players) {
        let target = state.enemies.toSorted((a, b) =>
          Math.hypot(a.x - p.x, (a.y - p.y) * 1.5) - Math.hypot(b.x - p.x, (b.y - p.y) * 1.5))[0];
        const down = state.players.find(q => q.id !== p.id && q.hp === 0);
        const slice = p.hp < 65 ? state.pickups[0] : undefined;
        if (down || slice) target = down || slice;
        const x = target?.x ?? state.gate + 35, y = target?.y ?? 0;
        const dx = x - p.x, dy = y - p.y;
        const reach = !target || down || slice ? 15 : p.hero === 2 ? 110 : 75;
        const inReach = target && !down && !slice && Math.abs(dx) < reach + 20 && Math.abs(dy) < 40;
        const action = tick % 63 === 0 ? 'jump' :
          inReach && tick % 12 === 0 ? p.power >= 50 ? 'special' : 'attack' : undefined;
        game.input(p.id, { seq: tick, dx: Math.abs(dx) > reach ? Math.sign(dx) : target ? Math.sign(dx) * .08 : 0,
          dy: Math.abs(dy) > 20 ? Math.sign(dy) * .8 : 0, action });
      }
    }
    game.update();
  }
  assert.equal(game.phase, 'clear', JSON.stringify(game.snapshot()));
  assert.deepEqual([...history], [0, 1, 2]);
  assert.equal(game.defeated, 18);
  for (const p of game.players) {
    assert.ok(p.stats.damage > 400);
    assert.ok(p.stats.jumps > 5);
    assert.ok(p.stats.specials > 1);
    assert.ok(p.stats.distance > 1000);
  }
});
