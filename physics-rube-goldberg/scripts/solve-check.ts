// Headless solvability check that runs every level's reference layout through the
// deterministic simulation without a browser.
//   node --experimental-strip-types scripts/solve-check.ts            all levels
//   node --experimental-strip-types scripts/solve-check.ts 2 '<json>'  one level with a custom layout
import { LEVELS } from '../src/levels.ts'
import { Sim } from '../src/physics/sim.ts'
import type { PlacedPart } from '../src/parts.ts'

const referenceLayouts: Record<number, PlacedPart[]> = {
  1: [{ id: 'a', type: 'ramp', x: 180, y: 320, angle: 30 }],
  2: [
    { id: 'a', type: 'ramp', x: 150, y: 250, angle: 30 },
    { id: 'b', type: 'ramp', x: 400, y: 330, angle: -15 },
  ],
  3: [
    { id: 'a', type: 'ramp', x: 160, y: 300, angle: 30 },
    { id: 'b', type: 'trampoline', x: 400, y: 552, angle: 0 },
  ],
  4: [
    { id: 'a', type: 'fan', x: 52, y: 545, angle: 0 },
    { id: 'b', type: 'ramp', x: 740, y: 535, angle: -30 },
  ],
  5: [
    { id: 'a', type: 'ramp', x: 130, y: 200, angle: 30 },
    { id: 'b', type: 'trampoline', x: 780, y: 552, angle: 0 },
  ],
}

const only = process.argv[2] ? Number(process.argv[2]) : undefined
const override = process.argv[3] ? (JSON.parse(process.argv[3]) as PlacedPart[]) : undefined

for (const level of LEVELS) {
  if (only && level.id !== only) continue
  const parts = override ?? referenceLayouts[level.id] ?? []
  const sim = new Sim(level)
  sim.build(level, parts)
  sim.run()
  const samples: string[] = []
  let t = 0
  while (sim.mode === 'running' && t < 40000) {
    sim.tick(t)
    t += 1000 / 60
    if (sim.steps % 30 === 0) samples.push(`${(sim.ball.position.x | 0)},${sim.ball.position.y | 0}`)
  }
  console.log(
    `L${level.id} ${level.name}: ${sim.mode}${sim.failReason ? ' (' + sim.failReason + ')' : ''} after ${sim.elapsed.toFixed(2)}s  ball=${sim.ball.position.x | 0},${sim.ball.position.y | 0}`,
  )
  console.log('   path: ' + samples.slice(0, 30).join(' '))
}
