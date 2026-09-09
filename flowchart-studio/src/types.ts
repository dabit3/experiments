export type NodeKind = 'start' | 'end' | 'process' | 'decision' | 'data'

export type PortSide = 'top' | 'right' | 'bottom' | 'left'

export const PORT_SIDES: PortSide[] = ['top', 'right', 'bottom', 'left']

export type EdgeStyle = 'orthogonal' | 'straight'

export interface FlowNode {
  id: string
  kind: NodeKind
  x: number
  y: number
  w: number
  h: number
  label: string
}

export interface FlowEdge {
  id: string
  source: string
  sourcePort: PortSide
  target: string
  targetPort: PortSide
  label: string
}

export interface Diagram {
  nodes: FlowNode[]
  edges: FlowEdge[]
}

export interface Viewport {
  x: number
  y: number
  zoom: number
}

export interface Point {
  x: number
  y: number
}

export interface Rect {
  x: number
  y: number
  w: number
  h: number
}

export interface Selection {
  nodes: string[]
  edges: string[]
}

export const EMPTY_SELECTION: Selection = { nodes: [], edges: [] }

export const GRID = 20
export const MIN_ZOOM = 0.2
export const MAX_ZOOM = 3

export interface NodeKindMeta {
  kind: NodeKind
  name: string
  hint: string
  color: string
  defaultLabel: string
  w: number
  h: number
}

export const NODE_KINDS: NodeKindMeta[] = [
  { kind: 'start', name: 'Start', hint: 'Terminal pill', color: '#0f9a6d', defaultLabel: 'Start', w: 140, h: 56 },
  { kind: 'end', name: 'End', hint: 'Terminal pill', color: '#d93a5c', defaultLabel: 'End', w: 140, h: 56 },
  { kind: 'process', name: 'Process', hint: 'Rectangle', color: '#2f5fe3', defaultLabel: 'Process', w: 170, h: 68 },
  { kind: 'decision', name: 'Decision', hint: 'Diamond', color: '#d98a12', defaultLabel: 'Decision?', w: 180, h: 100 },
  { kind: 'data', name: 'Data', hint: 'Parallelogram', color: '#0e8fa8', defaultLabel: 'Data', w: 170, h: 64 },
]

export function kindMeta(kind: NodeKind): NodeKindMeta {
  return NODE_KINDS.find((k) => k.kind === kind) ?? NODE_KINDS[2]
}
