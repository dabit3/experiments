// Headless sanity check of the pure game logic: plays a seed with a naive
// corner strategy (left, down, right, up) and prints the outcome.
// Usage: node scripts/simulate.mjs [seed]   (Node >= 23.6 strips types natively)
import * as game from '../src/lib/game.ts'

const seed = Number(process.argv[2] ?? 99)
let state = game.newGame(seed)
const order = ['left', 'down', 'right', 'up']
while (state.banner !== 'over' && state.moves < 5000) {
  let next = state
  for (const dir of order) {
    next = game.move(state, dir)
    if (next !== state) break
  }
  if (next === state) break
  state = game.dismissBanner(next)
}

const grid = Array.from({ length: 4 }, () => Array(4).fill('.'))
for (const t of state.tiles) if (t.kind !== 'ghost') grid[t.row][t.col] = String(t.value)
console.log(
  `seed=${seed} moves=${state.moves} score=${state.score} highest=${game.highestTile(state.tiles)} banner=${state.banner}`,
)
console.log(grid.map((r) => r.map((v) => v.padStart(5)).join('')).join('\n'))
