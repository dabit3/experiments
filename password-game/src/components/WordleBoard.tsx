import type { WordleBoardData } from '../data/wordle'

export function WordleBoard({ board }: { board: WordleBoardData }) {
  const rows = [...board.rows]
  while (rows.length < 6) rows.push({ word: '', tiles: [] })
  return (
    <section className="widget widget--wordle" aria-label="Today's Wordle">
      <h2 className="widget__title">
        Today&rsquo;s Wordle <span className="widget__meta">#{board.puzzleNumber}</span>
      </h2>
      <div className="wordle" role="img" aria-label={`Solved Wordle board, answer ${board.answer}`}>
        {rows.map((row, r) => (
          <div className="wordle__row" key={r}>
            {Array.from({ length: 5 }, (_, c) => {
              const letter = row.word[c] ?? ''
              const tile = row.tiles[c] ?? 'empty'
              return (
                <span className={`tile tile--${tile}`} key={c} style={{ animationDelay: `${r * 90 + c * 40}ms` }}>
                  {letter}
                </span>
              )
            })}
          </div>
        ))}
      </div>
      <p className="widget__note">Solved in {board.rows.length}. Rule 12 wants the green row.</p>
    </section>
  )
}
