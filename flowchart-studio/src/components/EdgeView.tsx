import { memo } from 'react'
import type { EdgeStyle, FlowEdge, FlowNode } from '../types'
import { arrowHead, polylineMidpoint, polylinePath, routeEdge, trimForArrow } from '../lib/geometry'

interface EdgeViewProps {
  edge: FlowEdge
  source: FlowNode
  target: FlowNode
  style: EdgeStyle
  selected: boolean
  editing: boolean
}

export const EdgeView = memo(function EdgeView({ edge, source, target, style, selected, editing }: EdgeViewProps) {
  const points = routeEdge(source, edge.sourcePort, target, edge.targetPort, style)
  const d = polylinePath(trimForArrow(points))
  const mid = polylineMidpoint(points)
  const labelW = edge.label.length * 7.5 + 16
  return (
    <g className={`edge${selected ? ' is-selected' : ''}`} data-edge-id={edge.id}>
      <path className="edge-hit" d={polylinePath(points)} />
      <path className="edge-line" d={d} />
      <polygon className="edge-arrow" points={arrowHead(points)} />
      {edge.label && !editing && (
        <g className="edge-label" transform={`translate(${mid.x} ${mid.y})`}>
          <rect x={-labelW / 2} y={-11} width={labelW} height={22} rx={6} />
          <text textAnchor="middle" dominantBaseline="central">
            {edge.label}
          </text>
        </g>
      )}
      {!edge.label && selected && !editing && (
        <g className="edge-label edge-label-empty" transform={`translate(${mid.x} ${mid.y})`}>
          <rect x={-40} y={-11} width={80} height={22} rx={6} />
          <text textAnchor="middle" dominantBaseline="central">
            + label
          </text>
        </g>
      )}
    </g>
  )
})
