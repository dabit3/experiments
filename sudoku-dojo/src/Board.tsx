import { boxOf, colOf, rowOf, type Grid } from './sudoku'

interface BoardProps {
  givens: Grid
  values: Grid
  notes: number[]
  selected: number | null
  conflicts: Set<number>
  wrong: Set<number>
  hinted: Set<number>
  solved: boolean
  onSelect: (i: number) => void
}

const DIGITS = [1, 2, 3, 4, 5, 6, 7, 8, 9]

export default function Board({
  givens,
  values,
  notes,
  selected,
  conflicts,
  wrong,
  hinted,
  solved,
  onSelect,
}: BoardProps) {
  const selValue = selected === null ? 0 : values[selected]
  const selRow = selected === null ? -1 : rowOf(selected)
  const selCol = selected === null ? -1 : colOf(selected)
  const selBox = selected === null ? -1 : boxOf(selected)

  return (
    <div className={`board${solved ? ' board-solved' : ''}`} role="grid" aria-label="Sudoku grid">
      {values.map((v, i) => {
        const r = rowOf(i)
        const c = colOf(i)
        const given = givens[i] !== 0
        const isSelected = selected === i
        const isPeer = !isSelected && (r === selRow || c === selCol || boxOf(i) === selBox)
        const sameDigit = !isSelected && v !== 0 && v === selValue
        const noteMask = notes[i]
        const classes = ['cell']
        if (given) classes.push('given')
        if (isSelected) classes.push('selected')
        if (isPeer) classes.push('peer')
        if (sameDigit) classes.push('same')
        if (conflicts.has(i)) classes.push('conflict')
        if (wrong.has(i)) classes.push('wrong')
        if (hinted.has(i)) classes.push('hinted')
        if (c % 3 === 2 && c !== 8) classes.push('box-right')
        if (r % 3 === 2 && r !== 8) classes.push('box-bottom')

        const label = `Row ${r + 1}, column ${c + 1}${v ? `, ${given ? 'given' : 'value'} ${v}` : ', empty'}`

        return (
          <button
            key={i}
            type="button"
            role="gridcell"
            className={classes.join(' ')}
            data-index={i}
            aria-label={label}
            aria-selected={isSelected}
            onMouseDown={(e) => e.preventDefault()}
            onClick={() => onSelect(i)}
          >
            {v !== 0 ? (
              <span className="digit">{v}</span>
            ) : noteMask !== 0 ? (
              <span className="notes" aria-label="pencil marks">
                {DIGITS.map((d) => (
                  <span
                    key={d}
                    className={`note${noteMask & (1 << d) ? ' on' : ''}${selValue === d && noteMask & (1 << d) ? ' note-same' : ''}`}
                  >
                    {noteMask & (1 << d) ? d : ''}
                  </span>
                ))}
              </span>
            ) : null}
          </button>
        )
      })}
    </div>
  )
}
