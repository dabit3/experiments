// Dev helper: print the board for a seed/level/first-click and check it is solvable
// without guessing (single-point + pairwise subset deductions).
//   node scripts/solve.mjs <level> <seed> <firstRow> <firstCol>
import { createServer } from 'vite'

const [level = 'intermediate', seedArg = '1234', rowArg = '7', colArg = '7'] = process.argv.slice(2)
const seed = Number(seedArg)

const server = await createServer({ server: { middlewareMode: true }, logLevel: 'silent', appType: 'custom' })
const mod = await server.ssrLoadModule('/src/lib/board.ts')
const { LEVELS, emptyBoard, placeMines, neighbors } = mod

const spec = LEVELS[level]
const first = Number(rowArg) * spec.cols + Number(colArg)
const board = placeMines(emptyBoard(spec), seed, first)

function print(known) {
  const lines = []
  lines.push('    ' + [...Array(spec.cols).keys()].map((c) => String(c).padStart(2)).join(''))
  for (let r = 0; r < spec.rows; r++) {
    let line = String(r).padStart(2) + '  '
    for (let c = 0; c < spec.cols; c++) {
      const i = r * spec.cols + c
      const cell = board.cells[i]
      let ch
      if (known && !known.revealed.has(i) && !known.flags.has(i)) ch = ' .'
      else if (cell.mine) ch = ' *'
      else ch = cell.adjacent === 0 ? ' _' : ' ' + cell.adjacent
      line += ch
    }
    lines.push(line)
  }
  return lines.join('\n')
}

// Solver
const revealed = new Set()
const flags = new Set()
function reveal(i) {
  if (revealed.has(i) || flags.has(i)) return
  const stack = [i]
  while (stack.length) {
    const k = stack.pop()
    if (revealed.has(k) || flags.has(k)) continue
    revealed.add(k)
    if (board.cells[k].adjacent === 0) for (const n of neighbors(board, k)) if (!revealed.has(n)) stack.push(n)
  }
}
reveal(first)
const steps = []
let progress = true
while (progress) {
  progress = false
  const frontier = [...revealed].filter((i) => board.cells[i].adjacent > 0)
  const constraints = frontier
    .map((i) => {
      const ns = neighbors(board, i)
      const hidden = ns.filter((n) => !revealed.has(n) && !flags.has(n))
      const f = ns.filter((n) => flags.has(n)).length
      return { i, hidden, need: board.cells[i].adjacent - f }
    })
    .filter((c) => c.hidden.length > 0)
  for (const c of constraints) {
    if (c.need === c.hidden.length) {
      for (const h of c.hidden) if (!flags.has(h)) { flags.add(h); progress = true; steps.push(`flag ${idx(h)} (from ${idx(c.i)})`) }
    } else if (c.need === 0) {
      for (const h of c.hidden) if (!revealed.has(h)) { reveal(h); progress = true; steps.push(`chord ${idx(c.i)} -> reveal ${idx(h)}`) }
    }
  }
  if (progress) continue
  // subset rule
  for (const a of constraints) {
    for (const b of constraints) {
      if (a === b) continue
      const aSet = new Set(a.hidden)
      if (!b.hidden.every((h) => aSet.has(h))) continue
      const diff = a.hidden.filter((h) => !b.hidden.includes(h))
      if (diff.length === 0) continue
      const needDiff = a.need - b.need
      if (needDiff === 0) {
        for (const h of diff) if (!revealed.has(h)) { reveal(h); progress = true; steps.push(`subset ${idx(a.i)}⊃${idx(b.i)} -> reveal ${idx(h)}`) }
      } else if (needDiff === diff.length) {
        for (const h of diff) if (!flags.has(h)) { flags.add(h); progress = true; steps.push(`subset ${idx(a.i)}⊃${idx(b.i)} -> flag ${idx(h)}`) }
      }
    }
  }
  if (!progress) {
    // remaining-mines count rule
    const hidden = [...Array(board.cells.length).keys()].filter((i) => !revealed.has(i) && !flags.has(i))
    const left = spec.mines - flags.size
    if (left === 0) { for (const h of hidden) reveal(h); progress = hidden.length > 0 }
    else if (left === hidden.length) { for (const h of hidden) flags.add(h); progress = hidden.length > 0 }
  }
}
function idx(i) { return `r${Math.floor(i / spec.cols)}c${i % spec.cols}` }

const totalSafe = spec.rows * spec.cols - spec.mines
const wrong = [...flags].filter((f) => !board.cells[f].mine)
console.log(`level=${level} seed=${seed} first=r${rowArg}c${colArg}`)
console.log(print())
console.log(`\nsolver: revealed ${revealed.size}/${totalSafe} safe cells, flags ${flags.size}/${spec.mines}, wrong flags ${wrong.length}`)
console.log(revealed.size === totalSafe ? 'SOLVABLE WITHOUT GUESSING' : 'STUCK — guess required\n' + print({ revealed, flags }))
if (process.env.STEPS) console.log(steps.join('\n'))
await server.close()
