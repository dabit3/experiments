import { snapOrigin } from './geometry'
import type { Diagram, FlowNode, PortSide } from '../types'

const LAYER_GAP = 90
const NODE_GAP = 60

/**
 * Simple layered (Sugiyama-style) layout: back edges are dropped to break
 * cycles, nodes are layered by longest path from the sources, ordered within a
 * layer by the barycenter of their neighbours, then stacked top-to-bottom with
 * each layer centred horizontally.
 */
export function layeredLayout(diagram: Diagram): Diagram {
  const nodes = diagram.nodes
  if (nodes.length === 0) return diagram
  const ids = nodes.map((n) => n.id)
  const index = new Map(ids.map((id, i) => [id, i]))
  const out: number[][] = ids.map(() => [])
  for (const e of diagram.edges) {
    const s = index.get(e.source)
    const t = index.get(e.target)
    if (s === undefined || t === undefined || s === t) continue
    out[s].push(t)
  }

  // Break cycles with a DFS: an edge to a node still on the stack is a back edge.
  const state = new Array<number>(ids.length).fill(0)
  const dag: number[][] = ids.map(() => [])
  const visit = (u: number) => {
    state[u] = 1
    for (const v of out[u]) {
      if (state[v] === 1) continue
      dag[u].push(v)
      if (state[v] === 0) visit(v)
    }
    state[u] = 2
  }
  for (let i = 0; i < ids.length; i++) if (state[i] === 0) visit(i)

  // Longest-path layering over the DAG.
  const indeg = new Array<number>(ids.length).fill(0)
  for (const vs of dag) for (const v of vs) indeg[v]++
  const layer = new Array<number>(ids.length).fill(0)
  const queue = indeg.map((d, i) => (d === 0 ? i : -1)).filter((i) => i >= 0)
  const remaining = indeg.slice()
  while (queue.length) {
    const u = queue.shift() as number
    for (const v of dag[u]) {
      layer[v] = Math.max(layer[v], layer[u] + 1)
      if (--remaining[v] === 0) queue.push(v)
    }
  }

  const layerCount = Math.max(...layer) + 1
  const layers: number[][] = Array.from({ length: layerCount }, () => [])
  for (let i = 0; i < ids.length; i++) layers[layer[i]].push(i)

  // Barycenter ordering, sweeping down then up a few times.
  const position = new Array<number>(ids.length).fill(0)
  const inc: number[][] = ids.map(() => [])
  for (let u = 0; u < ids.length; u++) for (const v of dag[u]) inc[v].push(u)
  const refresh = () => layers.forEach((l) => l.forEach((n, i) => (position[n] = i)))
  refresh()
  for (let sweep = 0; sweep < 4; sweep++) {
    const down = sweep % 2 === 0
    const order = down ? layers.keys() : [...layers.keys()].reverse()
    for (const li of order) {
      const neighbours = (n: number) => (down ? inc[n] : dag[n])
      const bary = new Map<number, number>()
      for (const n of layers[li]) {
        const ns = neighbours(n)
        bary.set(n, ns.length ? ns.reduce((a, b) => a + position[b], 0) / ns.length : position[n])
      }
      layers[li].sort((a, b) => (bary.get(a) as number) - (bary.get(b) as number) || position[a] - position[b])
      refresh()
    }
  }

  const placed = new Map<string, FlowNode>()
  let y = 0
  for (const l of layers) {
    const rowH = Math.max(...l.map((i) => nodes[i].h))
    const totalW = l.reduce((a, i) => a + nodes[i].w, 0) + NODE_GAP * (l.length - 1)
    let x = -totalW / 2
    for (const i of l) {
      const n = nodes[i]
      placed.set(n.id, { ...n, ...snapOrigin(x, y + (rowH - n.h) / 2, n.w, n.h, true) })
      x += n.w + NODE_GAP
    }
    y += rowH + LAYER_GAP
  }

  const edges = diagram.edges.map((e) => {
    const s = placed.get(e.source)
    const t = placed.get(e.target)
    if (!s || !t) return e
    const sc = { x: s.x + s.w / 2, y: s.y + s.h / 2 }
    const tc = { x: t.x + t.w / 2, y: t.y + t.h / 2 }
    if (tc.y > sc.y + 1) return { ...e, sourcePort: 'bottom' as PortSide, targetPort: 'top' as PortSide }
    if (tc.y < sc.y - 1) return { ...e, sourcePort: 'right' as PortSide, targetPort: 'right' as PortSide }
    return tc.x >= sc.x
      ? { ...e, sourcePort: 'right' as PortSide, targetPort: 'left' as PortSide }
      : { ...e, sourcePort: 'left' as PortSide, targetPort: 'right' as PortSide }
  })

  return { nodes: nodes.map((n) => placed.get(n.id) ?? n), edges }
}
