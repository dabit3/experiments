import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { advance, input, resetPlayer } from "../Server/engine.mjs";

const song = { notes: [{ id: 0, lane: 2, at: 1000 }, { id: 1, lane: 6, at: 1000 }, { id: 2, lane: 2, at: 1500 }] };

test("chords score independently; duplicate sequences and repeated notes cannot score", () => {
  const player = {};
  resetPlayer(player);
  assert.equal(input(player, song, 1020, 2, 0), true);
  assert.equal(input(player, song, 1020, 6, 0), false);
  assert.equal(input(player, song, 1020, 6, 1), true);
  assert.equal(input(player, song, 1020, 2, 2), false);
  assert.equal(player.combo, 2);
  assert.equal(player.counts.cool, 2);
  advance(player, song, 1800);
  assert.equal(player.combo, 0);
  assert.equal(player.maxCombo, 2);
  assert.equal(player.counts.miss, 1);
  assert.equal(player.judged.size, 3);
});

test("timing boundaries and invalid lanes never invent hits", () => {
  for (const [offset, verdict] of [[45, "cool"], [46, "great"], [-90, "great"], [91, "good"], [141, "bad"]]) {
    const player = {};
    resetPlayer(player);
    input(player, song, 1000 + offset, 2, 0);
    assert.equal(player.counts[verdict], 1);
  }
  const player = {};
  resetPlayer(player);
  assert.equal(input(player, song, 1000, 9, 0), false);
  assert.equal(input(player, song, 800, 2, 1), false);
  assert.equal(player.score, 0);
});

test("each authored song covers nine controls and aligns notes to musical eighth beats", () => {
  const songs = JSON.parse(readFileSync(new URL("../Resources/songs.json", import.meta.url)));
  assert.equal(songs.length, 2);
  for (const chart of songs) {
    assert.equal(new Set(chart.notes.map(note => note.lane)).size, 9);
    assert.equal(new Set(chart.notes.map(note => note.id)).size, chart.notes.length);
    assert.ok(chart.notes.length > 150);
    for (const note of chart.notes) {
      const halfBeat = 30_000 / chart.bpm;
      assert.ok(Math.abs(note.at / halfBeat - Math.round(note.at / halfBeat)) < 0.003);
      assert.ok(note.at < chart.duration - 1000);
    }
  }
});
