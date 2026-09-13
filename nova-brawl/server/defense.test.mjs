import test from 'node:test';
import assert from 'node:assert/strict';
import { Arena, fighter } from './combat.mjs';

test('invulnerable defender takes neither damage nor combo launch', () => {
  const arena = new Arena('DODGE');
  const attacker = fighter('a', 'Flare', 0);
  const defender = fighter('b', 'Ion', 1);
  arena.players = [attacker, defender];
  defender.pos.x = -2;
  defender.invulnerable = 0.4;
  attacker.combo = 2;
  attacker.comboAt = arena.tick;
  arena.action(attacker, defender, 'melee');
  assert.equal(defender.hp, 300);
  assert.deepEqual(defender.velocity, { x: 0, y: 0, z: 0 });
  assert.equal(attacker.hits, 0);
});
