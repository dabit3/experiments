// Breadth-first Sokoban solver used to check that every level in
// src/game/levels.ts is solvable and that its `par` equals the optimal
// number of moves. Run with: node scripts/verify-levels.mjs
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const src = readFileSync(join(here, '../src/game/levels.ts'), 'utf8')

// Pull the level literals out of the TS source without a TS toolchain.
const levels = []
const levelRe = /id:\s*(\d+),\s*name:\s*'([^']*)',\s*rows:\s*\[([\s\S]*?)\],\s*par:\s*(\d+)/g
for (const m of src.matchAll(levelRe)) {
  const rows = [...m[3].matchAll(/'([^']*)'/g)].map((r) => r[1])
  levels.push({ id: Number(m[1]), name: m[2], rows, par: Number(m[4]) })
}

const DIRS = [
  ['U', 0, -1],
  ['D', 0, 1],
  ['L', -1, 0],
  ['R', 1, 0],
]

function solve(rows) {
  const h = rows.length
  const w = Math.max(...rows.map((r) => r.length))
  const wall = (x, y) => x < 0 || y < 0 || x >= w || y >= h || rows[y][x] === '#'
  const targets = new Set()
  let player
  const crates = []
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const c = rows[y][x] ?? ' '
      if ('.*+'.includes(c)) targets.add(y * w + x)
      if ('$*'.includes(c)) crates.push(y * w + x)
      if ('@+'.includes(c)) player = y * w + x
    }
  const key = (p, cs) => p + '|' + [...cs].sort((a, b) => a - b).join(',')
  const solved = (cs) => cs.every((c) => targets.has(c))

  const start = { p: player, cs: crates, path: '' }
  const seen = new Set([key(player, crates)])
  let queue = [start]
  let explored = 0
  while (queue.length) {
    const nextQueue = []
    for (const s of queue) {
      explored++
      if (solved(s.cs)) return { path: s.path, explored }
      const px = s.p % w
      const py = Math.floor(s.p / w)
      for (const [name, dx, dy] of DIRS) {
        const nx = px + dx
        const ny = py + dy
        if (wall(nx, ny)) continue
        const n = ny * w + nx
        let cs = s.cs
        const ci = cs.indexOf(n)
        if (ci >= 0) {
          const bx = nx + dx
          const by = ny + dy
          const b = by * w + bx
          if (wall(bx, by) || cs.includes(b)) continue
          // Prune crates pushed into a non-target corner.
          if (!targets.has(b)) {
            const vert = wall(bx, by - 1) || wall(bx, by + 1)
            const horiz = wall(bx - 1, by) || wall(bx + 1, by)
            if (vert && horiz) continue
          }
          cs = cs.slice()
          cs[ci] = b
        }
        const k = key(n, cs)
        if (seen.has(k)) continue
        seen.add(k)
        nextQueue.push({ p: n, cs, path: s.path + name })
      }
    }
    queue = nextQueue
  }
  return null
}

let ok = true
for (const level of levels) {
  const t0 = performance.now()
  const result = solve(level.rows)
  const ms = (performance.now() - t0).toFixed(0)
  if (!result) {
    ok = false
    console.log(`Level ${level.id} "${level.name}": UNSOLVABLE`)
    continue
  }
  const optimal = result.path.length
  const parOk = optimal === level.par
  if (!parOk) ok = false
  console.log(
    `Level ${level.id} "${level.name}": optimal ${optimal} moves (par ${level.par}${parOk ? '' : ' MISMATCH'}), ` +
      `${result.explored} states, ${ms}ms\n  ${result.path}`,
  )
}
process.exit(ok ? 0 : 1)
