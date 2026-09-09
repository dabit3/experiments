import type { SceneSpec } from '../lib/scene'

interface Props {
  spec: SceneSpec
  /** Unique prefix for gradient ids (a scene may be rendered several times per page). */
  id: string
}

/** Renders a generated landscape as SVG content (no outer <svg>). */
export function SceneSvg({ spec, id }: Props) {
  const { w, h, robot } = spec
  const skyId = `${id}-sky`
  return (
    <g>
      <defs>
        <linearGradient id={skyId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={spec.skyTop} />
          <stop offset="1" stopColor={spec.skyBottom} />
        </linearGradient>
      </defs>
      <rect width={w} height={h} fill={`url(#${skyId})`} />
      {spec.stars.map((s, i) => (
        <circle key={i} cx={s.x} cy={s.y} r={s.r} fill="#fff" opacity={0.85} />
      ))}
      <circle cx={spec.sun.x} cy={spec.sun.y} r={spec.sun.r + 10} fill={spec.sun.color} opacity={0.25} />
      <circle cx={spec.sun.x} cy={spec.sun.y} r={spec.sun.r} fill={spec.sun.color} />
      {spec.clouds.map((c, i) => (
        <g key={i} transform={`translate(${c.x} ${c.y}) scale(${c.scale})`} fill="#fff" opacity={spec.night ? 0.25 : 0.9}>
          <ellipse cx={0} cy={0} rx={34} ry={14} />
          <ellipse cx={-18} cy={4} rx={20} ry={11} />
          <ellipse cx={20} cy={5} rx={22} ry={12} />
        </g>
      ))}
      {spec.hills.map((hill, i) => (
        <path key={i} d={hill.path} fill={hill.color} />
      ))}
      <rect x={0} y={spec.horizonY + 24} width={w} height={h - spec.horizonY - 24} fill={spec.ground} />
      {spec.trees.map((t, i) => (
        <g key={i} transform={`translate(${t.x} ${t.baseY})`}>
          <rect x={-4} y={-t.height * 0.4} width={8} height={t.height * 0.4} fill="#78350f" />
          <polygon points={`0,${-t.height} ${-t.height * 0.4},${-t.height * 0.35} ${t.height * 0.4},${-t.height * 0.35}`} fill={t.canopy} />
          <polygon points={`0,${-t.height * 0.75} ${-t.height * 0.32},${-t.height * 0.2} ${t.height * 0.32},${-t.height * 0.2}`} fill={t.canopy} />
        </g>
      ))}
      <g transform={`translate(${robot.x} ${robot.baseY}) scale(${robot.scale})`}>
        <ellipse cx={0} cy={2} rx={26} ry={4} fill="#000" opacity={0.3} />
        <rect x={-12} y={-14} width={8} height={14} rx={2} fill="#475569" />
        <rect x={4} y={-14} width={8} height={14} rx={2} fill="#475569" />
        <rect x={-18} y={-50} width={36} height={38} rx={6} fill={robot.body} />
        <rect x={-10} y={-42} width={20} height={12} rx={2} fill={robot.accent} opacity={0.9} />
        <circle cx={-4} cy={-24} r={2.5} fill="#0f172a" />
        <circle cx={4} cy={-24} r={2.5} fill="#0f172a" />
        <rect x={-30} y={-46} width={10} height={24} rx={4} fill="#94a3b8" />
        <rect x={20} y={-46} width={10} height={24} rx={4} fill="#94a3b8" />
        <rect x={-14} y={-78} width={28} height={26} rx={6} fill={robot.body} />
        <rect x={-9} y={-71} width={18} height={10} rx={3} fill="#0f172a" />
        <circle cx={-4} cy={-66} r={2} fill={robot.accent} />
        <circle cx={4} cy={-66} r={2} fill={robot.accent} />
        <line x1={0} y1={-78} x2={0} y2={-92} stroke="#94a3b8" strokeWidth={2} />
        <circle cx={0} cy={-95} r={4} fill={robot.accent} />
      </g>
    </g>
  )
}
