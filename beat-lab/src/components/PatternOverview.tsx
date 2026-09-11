import { STEPS, type PatternId, type Song } from '../types'

interface Props {
  patterns: Song['patterns']
  editing: PatternId
  nowPlaying: PatternId | null
  onSelect: (id: PatternId) => void
}

export function PatternOverview(p: Props) {
  return (
    <section className="pattern-overview" aria-label="Pattern">
      <div className="overview-label">
        <h3>Patterns</h3>
        <span>
          Two ideas.
          <br />
          One sequence.
        </span>
      </div>
      {(['A', 'B'] as const).map((id) => {
        const pattern = p.patterns[id]
        const hits = pattern.drums.flat().filter((v) => v > 0).length
        const notes = pattern.bass.filter((v) => v !== null).length
        return (
          <button
            key={id}
            type="button"
            className={`pattern-card ${p.editing === id ? 'is-active' : ''}`}
            aria-label={`Pattern ${id}`}
            aria-pressed={p.editing === id}
            onClick={() => p.onSelect(id)}
          >
            <span className="pattern-letter">{id}</span>
            <span className="pattern-info">
              <strong>Pattern {id}</strong>
              <small>
                {hits || notes
                  ? `${hits} hit${hits === 1 ? '' : 's'} · ${notes} note${notes === 1 ? '' : 's'}`
                  : 'Empty · click to create'}
              </small>
            </span>
            <span className="pattern-mini" aria-hidden="true">
              {Array.from({ length: STEPS }, (_, step) => {
                const density =
                  pattern.drums.reduce(
                    (n, row) => n + Number(row[step] > 0),
                    0,
                  ) + Number(pattern.bass[step] !== null)
                return (
                  <i
                    key={step}
                    style={{ height: `${Math.max(8, (density / 9) * 100)}%` }}
                    className={density ? 'has-notes' : ''}
                  />
                )
              })}
            </span>
            <span className="pattern-state">
              {p.nowPlaying === id
                ? 'Playing'
                : p.editing === id
                  ? 'Editing'
                  : 'Select'}
            </span>
          </button>
        )
      })}
    </section>
  )
}
