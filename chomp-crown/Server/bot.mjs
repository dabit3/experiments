import { nextDirection } from './game.mjs';

export function chooseInput(state, id, style = 'hunter') {
  const p = state.players.find(player => player.id === id);
  if (!p?.alive || state.phase !== 'playing') return null;
  const x = Math.round(p.x), y = Math.round(p.y);
  const enemies = state.players.filter(other => other.id !== id && other.alive);
  const vulnerable = enemies.filter(other => other.power <= 0);
  let target;
  if (p.power > 1 && vulnerable.length && style === 'hunter') {
    target = vulnerable.sort((a, b) => Math.hypot(a.x - x, a.y - y) - Math.hypot(b.x - x, b.y - y))[0];
  } else {
    const powers = state.powers.filter(power => power.active);
    if (powers.length && p.power < 1) {
      target = powers.sort((a, b) => {
        const da = Math.abs(a.x - x) + Math.abs(a.y - y);
        const db = Math.abs(b.x - x) + Math.abs(b.y - y);
        return style === 'runner' ? db - da : da - db;
      })[0];
    } else {
      target = state.pellets.map(k => {
        const [px, py] = k.split(',').map(Number);
        return { x: px, y: py };
      }).filter(t => t.x !== x || t.y !== y)
        .sort((a, b) => Math.abs(a.x - x) + Math.abs(a.y - y) - Math.abs(b.x - x) - Math.abs(b.y - y))[0];
    }
  }
  return target ? nextDirection(x, y, Math.round(target.x), Math.round(target.y)) : null;
}
