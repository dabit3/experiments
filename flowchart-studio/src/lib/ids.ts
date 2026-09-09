import type { Diagram } from '../types'

let counter = 0

export function seedIds(diagram: Diagram): void {
  let max = 0
  for (const item of [...diagram.nodes, ...diagram.edges]) {
    const m = /^[ne](\d+)$/.exec(item.id)
    if (m) max = Math.max(max, Number(m[1]))
  }
  counter = Math.max(counter, max)
}

export function nodeId(): string {
  return `n${++counter}`
}

export function edgeId(): string {
  return `e${++counter}`
}
