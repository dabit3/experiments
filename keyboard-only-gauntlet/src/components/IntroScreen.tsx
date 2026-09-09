import { TASKS } from '../tasks'

interface Props {
  onStart: () => void
  violations: number
}

export function IntroScreen({ onStart, violations }: Props) {
  return (
    <section className="card intro" aria-labelledby="intro-title">
      <p className="eyebrow">Accessibility drill</p>
      <h2 id="intro-title">Six ARIA widgets. No pointer.</h2>
      <p className="lede">
        The mouse is disabled on this page: every element ignores pointer events, the cursor is hidden and any
        click raises a violation. Get through all six widgets with the keyboard alone.
      </p>
      <ol className="intro-tasks">
        {TASKS.map((t, i) => (
          <li key={t.id}>
            <span className="intro-num">{i + 1}</span>
            <span>
              <strong>{t.title}</strong> — {t.goal}
            </span>
          </li>
        ))}
      </ol>
      <div className="intro-actions">
        <button type="button" className="btn btn-primary btn-lg" onClick={onStart} autoFocus>
          Start the gauntlet
          <kbd>Enter</kbd>
        </button>
        <p className="intro-note">
          {violations > 0
            ? `${violations} mouse violation${violations === 1 ? '' : 's'} so far. The counter resets when the timer starts.`
            : 'Try clicking anything to see what happens. The counter resets when the timer starts.'}
        </p>
      </div>
    </section>
  )
}
