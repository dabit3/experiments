import { cellKey, rangeLabel, rangePositions, rangeSize, type Range } from '../lib/cells'
import { formatNumber } from '../lib/formula'
import type { Values } from '../lib/sheet'

interface Props {
  range: Range
  values: Values
}

const SHORTCUTS = [
  ['Tab / Enter', 'move'],
  ['F2', 'edit'],
  ['Ctrl+D', 'fill down'],
  ['Ctrl+B', 'bold'],
  ['Ctrl+C / V', 'copy / paste'],
  ['Ctrl+Z', 'undo'],
]

export function StatusBar({ range, values }: Props) {
  const numbers: number[] = []
  let filled = 0
  for (const pos of rangePositions(range)) {
    const v = values[cellKey(pos)]
    if (v === null || v === undefined) continue
    filled++
    if (typeof v === 'number') numbers.push(v)
  }
  const sum = numbers.reduce((a, b) => a + b, 0)
  const multi = rangeSize(range) > 1

  return (
    <footer className="status-bar">
      <div className="status-left" data-testid="status-summary">
        {multi ? (
          <>
            <span className="status-range">{rangeLabel(range)}</span>
            <span>
              Sum: <b data-testid="status-sum">{formatNumber(sum)}</b>
            </span>
            <span>
              Average:{' '}
              <b>{numbers.length ? formatNumber(sum / numbers.length) : '–'}</b>
            </span>
            <span>
              Count: <b data-testid="status-count">{filled}</b>
            </span>
          </>
        ) : (
          <span className="status-ready">Ready</span>
        )}
      </div>
      <div className="status-right">
        {SHORTCUTS.map(([keys, label]) => (
          <span key={keys} className="hint">
            <kbd>{keys}</kbd> {label}
          </span>
        ))}
      </div>
    </footer>
  )
}
