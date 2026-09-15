import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, MAZE, makePlayer, walkable, nextDirection } from '../Server/game.mjs';
import { chooseInput } from '../Server/bot.mjs';

function match() {
  const game = new Game('TEST');
  game.players = [makePlayer('player-a', 'Gold', 0), makePlayer('player-b', 'Rose', 1)];
  game.ready('player-a'); game.ready('player-b');
  for (let i = 0; i < 91; i++) game.step();
  for (const p of game.players) p.shield = 0;
  return game;
}
test('all playable cells connect and maze dimensions are stable', () => {
  assert.ok(MAZE.every(row => row.length === 19));
  for (let y = 0; y < MAZE.length; y++) {
    for (let x = 0; x < MAZE[y].length; x++) {
      if (walkable(x, y) && (x !== 1 || y !== 1)) assert.ok(nextDirection(1, 1, x, y), `${x},${y}`);
    }
  }
});
test('walls stop movement and buffered turns wait for junction centers', () => {
  const game = match(), p = game.players[0];
  Object.assign(p, { x: 1, y: 1, dir: 'left', wanted: 'left' });
  game.move(p, 3);
  assert.equal(p.x, 1);
  Object.assign(p, { x: 1.4, y: 3, dir: 'right', wanted: 'up' });
  game.move(p, 2.6);
  assert.equal(p.y, 3);
  assert.ok(Math.abs(p.x - 4) < 1e-7);
  game.move(p, 1);
  assert.equal(p.y, 2);
});
test('power collection, timer expiry and authority over human eating', () => {
  const game = match(), [a, b] = game.players;
  Object.assign(a, { x: 1, y: 1, dir: 'left', wanted: 'left' });
  game.step();
  assert.equal(a.power, 7);
  assert.equal(game.powers[0].active, false);
  Object.assign(b, { x: 1.5, y: 1, dir: 'left', wanted: 'left' });
  game.step();
  assert.equal(b.alive, false);
  assert.equal(a.kills, 1);
  assert.equal(a.crowns, 1);
  assert.equal(game.phase, 'roundOver');
  const expiry = match();
  expiry.players[0].power = 0.01;
  expiry.step();
  assert.equal(expiry.players[0].power, 0);
});
test('equal-power collision knocks back without eliminating either human', () => {
  const game = match(), [a, b] = game.players;
  Object.assign(a, { x: 3.8, y: 3, dir: 'right', wanted: 'right' });
  Object.assign(b, { x: 4.2, y: 3, dir: 'left', wanted: 'left' });
  game.step();
  assert.ok(a.alive && b.alive);
  assert.equal(a.dir, 'left');
  assert.equal(b.dir, 'right');
  assert.ok(a.x < b.x);
});
test('ghosts eliminate normal peers and respawn after a powered peer eats them', () => {
  for (const powered of [false, true]) {
    const game = match(), p = game.players[0];
    Object.assign(p, { x: 9, y: 7, power: powered ? 5 : 0, dir: 'up', wanted: 'up' });
    Object.assign(game.ghosts[0], { x: 9, y: 7, respawn: 0 });
    game.step();
    assert.equal(p.alive, powered);
    if (powered) assert.ok(game.ghosts[0].respawn > 0 && p.score >= 200);
  }
});
test('ordered input rejects duplicates, invalid values and stale sequences', () => {
  const game = match();
  assert.equal(game.input('player-a', 10, 'down'), true);
  assert.equal(game.input('player-a', 9, 'right'), false);
  assert.equal(game.input('player-a', 10, 'up'), false);
  assert.equal(game.input('player-a', 11, 'teleport'), false);
  assert.equal(game.players[0].wanted, 'down');
});
test('crowns accumulate across rounds; both rematch votes reset the match', () => {
  const game = match(), p = game.players[0];
  game.endRound(p, 'test');
  for (let i = 0; i < 212; i++) game.step();
  assert.equal(game.round, 2);
  assert.equal(game.phase, 'playing');
  game.endRound(p, 'test');
  assert.equal(game.winnerId, p.id);
  game.ready(p.id);
  assert.equal(game.phase, 'matchOver');
  game.ready(game.players[1].id);
  assert.equal(game.phase, 'countdown');
  assert.equal(game.round, 1);
  assert.equal(p.crowns, 0);
});
test('disconnect pauses the entire authoritative clock', () => {
  const game = match(), clock = game.clock, x = game.players[0].x;
  game.players[1].connected = false;
  for (let i = 0; i < 60; i++) game.step();
  assert.equal(game.clock, clock);
  assert.equal(game.players[0].x, x);
  assert.ok(game.pauseReason.includes('Rose'));
});
test('ordinary input drivers complete a multi-round game without forced outcomes', () => {
  const game = match();
  for (let i = 0; i < 30 * 240 && game.phase !== 'matchOver'; i++) {
    const state = game.snapshot();
    game.players.forEach((p, index) => {
      const input = chooseInput(state, p.id, index ? 'runner' : 'hunter');
      if (input) game.input(p.id, i, input);
    });
    game.step();
    for (const p of game.players) assert.ok(walkable(Math.round(p.x), Math.round(p.y)));
  }
  assert.equal(game.phase, 'matchOver');
  assert.ok(game.round >= 2);
  assert.ok(game.players.every(p => p.score > 0));
  assert.equal(game.players.find(p => p.id === game.winnerId).crowns, 2);
});
