interface GaugeProps {
  /** 0..100 */
  value: number
  label: string
  unit?: string
  size?: number
}

const START = -220
const SWEEP = 260

function polar(cx: number, cy: number, r: number, deg: number): [number, number] {
  const rad = (deg * Math.PI) / 180
  return [cx + r * Math.cos(rad), cy + r * Math.sin(rad)]
}

function arc(cx: number, cy: number, r: number, from: number, to: number): string {
  const [x1, y1] = polar(cx, cy, r, from)
  const [x2, y2] = polar(cx, cy, r, to)
  const large = to - from > 180 ? 1 : 0
  return `M ${x1.toFixed(2)} ${y1.toFixed(2)} A ${r} ${r} 0 ${large} 1 ${x2.toFixed(2)} ${y2.toFixed(2)}`
}

export function Gauge({ value, label, unit = '%', size = 240 }: GaugeProps) {
  const v = Math.max(0, Math.min(100, value))
  const cx = size / 2
  const cy = size / 2
  const r = size / 2 - 18
  const end = START + (SWEEP * v) / 100
  const nominal = v >= 100
  const tone = nominal ? 'var(--green)' : v > 0 ? 'var(--amber)' : 'var(--line-strong)'
  const ticks = Array.from({ length: 11 }, (_, i) => START + (SWEEP * i) / 10)
  const [nx, ny] = polar(cx, cy, r - 6, end)

  return (
    <figure className="gauge" style={{ width: size }}>
      <svg viewBox={`0 0 ${size} ${size}`} width={size} height={size} role="img" aria-label={`${label} ${Math.round(v)}${unit}`}>
        <path d={arc(cx, cy, r, START, START + SWEEP)} fill="none" stroke="var(--line)" strokeWidth={10} strokeLinecap="round" />
        {v > 0 && (
          <path
            d={arc(cx, cy, r, START, Math.max(START + 0.1, end))}
            fill="none"
            stroke={tone}
            strokeWidth={10}
            strokeLinecap="round"
            style={{ filter: `drop-shadow(0 0 8px ${tone})` }}
          />
        )}
        {ticks.map((deg, i) => {
          const [x1, y1] = polar(cx, cy, r - 14, deg)
          const [x2, y2] = polar(cx, cy, r - (i % 5 === 0 ? 26 : 20), deg)
          return <line key={deg} x1={x1} y1={y1} x2={x2} y2={y2} stroke="var(--dim)" strokeWidth={i % 5 === 0 ? 2 : 1} />
        })}
        <line x1={cx} y1={cy} x2={nx} y2={ny} stroke="var(--text)" strokeWidth={3} strokeLinecap="round" />
        <circle cx={cx} cy={cy} r={7} fill="var(--panel-3)" stroke="var(--text)" strokeWidth={2} />
        <text x={cx} y={cy + r * 0.55} textAnchor="middle" fill={tone} fontFamily="var(--font-mono)" fontSize={size * 0.17} fontWeight={600}>
          {Math.round(v)}
          <tspan fontSize={size * 0.08} fill="var(--muted)">
            {unit}
          </tspan>
        </text>
      </svg>
      <figcaption className="caption gauge__label">{label}</figcaption>
    </figure>
  )
}
