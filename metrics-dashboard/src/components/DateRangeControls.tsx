import { DAYS, dateForDay } from '../data/dataset'
import { formatLongDate } from '../utils/format'

interface Props {
  range: [number, number]
  onChange: (range: [number, number]) => void
}

const PRESETS: Array<{ label: string; days: number }> = [
  { label: '7d', days: 7 },
  { label: '30d', days: 30 },
  { label: '90d', days: 90 },
  { label: '1y', days: DAYS },
]

const MIN_SPAN = 6

export function DateRangeControls({ range, onChange }: Props) {
  const [start, end] = range
  const activePreset = PRESETS.find((p) => end === DAYS - 1 && start === DAYS - p.days)?.label

  const startPct = (start / (DAYS - 1)) * 100
  const endPct = (end / (DAYS - 1)) * 100

  return (
    <div className="range-control" data-testid="date-range">
      <div className="range-control__row">
        <div className="segmented" role="group" aria-label="Date range presets">
          {PRESETS.map((p) => (
            <button
              key={p.label}
              type="button"
              className={`segmented__item${activePreset === p.label ? ' segmented__item--active' : ''}`}
              onClick={() => onChange([DAYS - p.days, DAYS - 1])}
              data-testid={`preset-${p.label}`}
            >
              {p.label}
            </button>
          ))}
        </div>
        <span className="range-control__label" data-testid="range-label">
          {formatLongDate(dateForDay(start))} → {formatLongDate(dateForDay(end))}
          <span className="range-control__days">{end - start + 1} days</span>
        </span>
      </div>

      <div className="dual-slider" style={{ ['--lo' as string]: `${startPct}%`, ['--hi' as string]: `${endPct}%` }}>
        <div className="dual-slider__track" />
        <div className="dual-slider__fill" />
        <input
          type="range"
          min={0}
          max={DAYS - 1}
          value={start}
          aria-label="Range start"
          data-testid="slider-start"
          onChange={(e) => onChange([Math.min(Number(e.target.value), end - MIN_SPAN), end])}
        />
        <input
          type="range"
          min={0}
          max={DAYS - 1}
          value={end}
          aria-label="Range end"
          data-testid="slider-end"
          onChange={(e) => onChange([start, Math.max(Number(e.target.value), start + MIN_SPAN)])}
        />
      </div>
    </div>
  )
}
