import test from 'node:test';
import assert from 'node:assert/strict';
import { advance, createRoom, player, input, validTeam } from './engine.mjs';

function fixture() {
  const room = createRoom('ABC123');
  room.players = [player('a', 'Alice', [0, 1, 2]), player('b', 'Bob', [3, 4, 5])];
  const act = (i, action, extra = {}) => input(room, room.players[i],
    { seq: room.players[i].lastSeq + 1, action, ...extra });
  act(0, 'ready'); act(1, 'ready');
  const tick = n => { for (let i = 0; i < n; i++) advance(room); };
  tick(60);
  return { room, act, tick };
}
test('team validation disallows duplicates, unknown heroes, wrong cardinality', () => {
  assert.equal(validTeam([0, 1, 2]), true);
  for (const team of [[0, 0, 1], [0, 1], [0, 1, 6], ['0', 1, 2], null]) assert.equal(validTeam(team), false);
});
test('two ready votes and countdown gate combat; duplicate sequence is ignored', () => {
  const room = createRoom('TEST');
  room.players = [player('a', 'A', [0, 1, 2]), player('b', 'B', [3, 4, 5])];
  input(room, room.players[0], { seq: 1, action: 'ready' });
  assert.equal(room.phase, 'lobby');
  input(room, room.players[1], { seq: 1, action: 'ready' });
  assert.equal(room.phase, 'countdown');
  assert.equal(input(room, room.players[0], { seq: 1, action: 'quick' }), false);
  assert.equal(room.players[0].attack, null);
});
test('quick interrupts a winding strong attack; recovery prohibits attack spam', () => {
  const { room, act, tick } = fixture();
  act(1, 'strong');
  act(0, 'quick');
  assert.equal(act(0, 'quick'), false);
  tick(4);
  assert.ok(room.players[1].hp[0] < 150);
  assert.equal(room.players[1].attack, null);
  tick(20);
  assert.equal(room.players[0].hp[0], 125);
});
test('held block reduces damage; timed guard parries and awards power', () => {
  const { room, act, tick } = fixture();
  act(1, 'block', { down: true });
  tick(6);
  act(0, 'strong'); tick(11);
  const blockedDamage = 150 - room.players[1].hp[0];
  assert.ok(blockedDamage > 0 && blockedDamage < 10);
  act(1, 'block', { down: false });
  tick(10);
  act(0, 'quick');
  act(1, 'block', { down: true });
  tick(4);
  assert.equal(room.players[1].hp[0], 150 - blockedDamage);
  assert.ok(room.events.some(e => e.type === 'parry'));
});
test('meter cannot be spent before earned; special mash is capped and cooldown enforced', () => {
  const { room, act, tick } = fixture();
  assert.equal(act(0, 'special'), false);
  for (let i = 0; i < 5; i++) { act(0, 'quick'); tick(10); }
  assert.ok(room.players[0].power[0] >= 100);
  act(0, 'special');
  for (let i = 0; i < 20; i++) { act(0, 'special'); tick(1); }
  assert.ok(room.players[0].attack.mash <= 10);
  tick(20);
  assert.ok(room.players[0].specials > 0);
  assert.ok(room.events.some(e => e.label === 'DEVASTATION'));
});
test('tag preserves health and power with cooldown; KO advances and team defeat ends match', () => {
  const { room, act, tick } = fixture();
  act(0, 'tag', { slot: 1 }); tick(12);
  assert.equal(room.players[0].active, 1);
  assert.equal(act(0, 'tag', { slot: 0 }), false);
  tick(90);
  assert.equal(act(0, 'tag', { slot: 0 }), true);
  tick(12);
  for (let i = 0; i < 200 && room.phase === 'fight'; i++) {
    act(0, room.players[0].power[room.players[0].active] >= 100 ? 'special' : 'strong');
    tick(48);
  }
  assert.equal(room.phase, 'result');
  assert.equal(room.winner, 'a');
  assert.deepEqual(room.players[1].hp, [0, 0, 0]);
  act(0, 'rematch');
  assert.equal(room.phase, 'result');
  act(1, 'rematch');
  assert.equal(room.phase, 'countdown');
  assert.equal(room.round, 2);
  assert.deepEqual(room.players[1].hp, [150, 110, 105]);
});
test('disconnected peer pauses the authoritative fight clock and damage', () => {
  const { room, act, tick } = fixture();
  act(0, 'strong');
  room.players[1].connected = false;
  const time = room.time;
  tick(100);
  assert.equal(room.time, time);
  assert.equal(room.players[1].hp[0], 150);
  room.players[1].connected = true;
  tick(15);
  assert.ok(room.players[1].hp[0] < 150);
});
