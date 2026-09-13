export function laserX(path, time) {
  const points = path.points;
  for (let i = 1; i < points.length; i++) {
    if (time <= points[i].time) {
      const a = points[i - 1], b = points[i];
      return a.x + (b.x - a.x) * Math.max(0, (time - a.time) / (b.time - a.time));
    }
  }
  return points.at(-1).x;
}

export class DuelEngine {
  constructor(chart) {
    this.chart = chart;
    this.events = [];
    for (const note of chart.notes) {
      this.events.push({ type: 'note', t: note.time, note, weight: 1000 });
      for (let t = note.time + chart.tick; t < note.time + note.duration - 0.01; t += chart.tick) {
        this.events.push({ type: 'hold', t, note, weight: 150 });
      }
    }
    for (const path of chart.lasers) {
      for (let t = path.points[0].time; t <= path.points.at(-1).time; t += chart.tick) {
        this.events.push({ type: 'laser', t, path, weight: 150 });
      }
      for (let i = 1; i < path.points.length; i++) {
        const a = path.points[i - 1], b = path.points[i];
        if (b.time - a.time < 0.04 && Math.abs(b.x - a.x) > 0.3) {
          this.events.push({ type: 'slam', t: b.time, path, from: a.x, to: b.x, weight: 600 });
        }
      }
    }
    this.events.sort((a, b) => a.t - b.t);
    this.total = this.events.reduce((sum, event) => sum + event.weight, 0);
  }

  player(id, name) {
    return {
      id, name, connected: true, ready: false, seq: -1, lastTime: -10,
      earned: 0, score: 0, combo: 0, maxCombo: 0, gauge: 50,
      critical: 0, near: 0, errors: 0, holdHits: 0, laserHits: 0, slamHits: 0,
      fxHits: 0, tapHits: 0, inputCount: 0, manualInputs: 0,
      judgment: 'STANDBY', judgmentAt: -10, lasers: [0.5, 0.5],
      processed: new Set(), buttons: Array.from({ length: 6 }, () => []),
      analog: [[], []],
    };
  }

  award(player, index, ratio, time, label) {
    if (player.processed.has(index)) return;
    const event = this.events[index];
    player.processed.add(index);
    player.earned += event.weight * ratio;
    player.score = Math.round(player.earned / this.total * 10_000_000);
    if (ratio > 0) {
      player.combo++;
      player.maxCombo = Math.max(player.maxCombo, player.combo);
      player.gauge = Math.min(100, player.gauge + (event.type === 'note' ? 0.65 : 0.12));
      if (ratio === 1) player.critical++;
      else player.near++;
      if (event.type === 'hold') player.holdHits++;
      if (event.type === 'laser') player.laserHits++;
      if (event.type === 'slam') player.slamHits++;
      if (event.type === 'note') {
        if (event.note.kind === 'fx') player.fxHits++;
        else player.tapHits++;
      }
    } else {
      player.combo = 0;
      player.errors++;
      player.gauge = Math.max(0, player.gauge - (event.type === 'note' ? 1.3 : 0.28));
    }
    // Button judgments stay readable while lasers generate many ticks.
    if (event.type === 'note' || event.type === 'slam' || time - player.judgmentAt > 0.15) {
      player.judgment = label;
      player.judgmentAt = time;
    }
  }

  input(player, message, now) {
    if (!Number.isSafeInteger(message.seq) || message.seq <= player.seq) return false;
    if (!Number.isFinite(message.time) || Math.abs(message.time - now) > 0.25) return false;
    const t = message.time;
    if (t < player.lastTime - 0.025 || t < 0 || t > this.chart.duration) return false;
    if (message.kind === 'button') {
      if (!Number.isInteger(message.lane) || message.lane < 0 || message.lane > 5 ||
          typeof message.down !== 'boolean') return false;
      const history = player.buttons[message.lane];
      const previous = history.at(-1);
      if (previous?.down === message.down) return false;
      history.push({ t, down: message.down });
      if (message.down) {
        let target = -1, distance = 0.121;
        this.events.forEach((event, index) => {
          if (event.type === 'note' && event.note.lane === message.lane && !player.processed.has(index)) {
            const delta = Math.abs(event.t - t);
            if (delta < distance) { target = index; distance = delta; }
          }
        });
        if (target !== -1) this.award(player, target, distance <= 0.05 ? 1 : 0.5, now,
          distance <= 0.05 ? 'CRITICAL' : 'NEAR');
      }
    } else if (message.kind === 'laser') {
      if (![0, 1].includes(message.color) || !Number.isFinite(message.x) || message.x < 0 || message.x > 1) return false;
      player.analog[message.color].push({ t, x: message.x });
      player.lasers[message.color] = message.x;
    } else return false;
    player.seq = message.seq;
    player.lastTime = Math.max(t, player.lastTime);
    player.inputCount++;
    if (message.source === 'touch') player.manualInputs++;
    return true;
  }

  advance(player, now) {
    this.events.forEach((event, index) => {
      if (event.t + 0.15 > now || player.processed.has(index)) return;
      if (event.type === 'note') {
        this.award(player, index, 0, now, 'ERROR');
      } else if (event.type === 'hold') {
        const held = player.buttons[event.note.lane].findLast(input => input.t <= event.t + 0.025)?.down;
        this.award(player, index, held ? 1 : 0, now, held ? 'HOLD' : 'BREAK');
      } else {
        const history = player.analog[event.path.color];
        const sample = history.findLast(input => input.t <= event.t + 0.04);
        const target = laserX(event.path, event.t);
        let hit = !!sample && event.t - sample.t < 0.18 && Math.abs(sample.x - target) <= 0.14;
        if (event.type === 'slam') {
          const before = history.findLast(input => input.t <= event.t - 0.035);
          hit = hit && !!before && Math.abs(before.x - event.from) < 0.23 &&
            Math.abs(sample.x - before.x) > 0.28;
        }
        this.award(player, index, hit ? 1 : 0, now,
          hit ? (event.type === 'slam' ? 'SLAM!' : 'LASER LOCK') : 'BREAK');
      }
    });
  }

  snapshot(player) {
    const {
      id, name, connected, ready, score, combo, maxCombo, gauge, critical, near,
      errors, holdHits, laserHits, slamHits, fxHits, tapHits, judgment, judgmentAt,
      lasers, inputCount, manualInputs,
    } = player;
    return {
      id, name, connected, ready, score, combo, maxCombo, gauge, critical, near,
      errors, holdHits, laserHits, slamHits, fxHits, tapHits, judgment, judgmentAt,
      lasers, inputCount, manualInputs,
    };
  }
}
