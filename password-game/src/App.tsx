import { useEffect, useRef, useState } from 'react'
import { ClockWidget } from './components/ClockWidget'
import { Confetti } from './components/Confetti'
import { RuleCard } from './components/RuleCard'
import { WordleBoard } from './components/WordleBoard'
import { todaysWordle } from './data/wordle'
import { RULES, SPONSORS, evaluate, formatClock } from './rules'
import './App.css'

export default function App() {
  const [password, setPassword] = useState('')
  const [revealed, setRevealed] = useState(0)
  const [now, setNow] = useState(() => new Date())
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), 1000)
    return () => window.clearInterval(id)
  }, [])

  const wordle = todaysWordle(now)

  const { states, nextRevealed } = evaluate(
    { password, time: formatClock(now), wordle: wordle.answer },
    revealed,
  )
  if (nextRevealed !== revealed) setRevealed(nextRevealed)

  useEffect(() => {
    const el = textareaRef.current
    if (!el) return
    el.style.height = '0px'
    el.style.height = `${Math.max(el.scrollHeight, 72)}px`
  }, [password])

  const passed = states.filter((s) => s.result.pass).length
  const won = revealed === RULES.length && passed === RULES.length
  const newest = states[states.length - 1]?.rule.id
  const ordered = [...states].reverse()

  return (
    <div className={`app${won ? ' app--won' : ''}`}>
      <Confetti active={won} />
      <header className="masthead">
        <h1 className="masthead__title">The Password Game</h1>
        <p className="masthead__tag">Rules that stack against you</p>
      </header>

      <main className="layout">
        <section className="entry" aria-labelledby="entry-label">
          <label className="entry__label" id="entry-label" htmlFor="password">
            Please choose a password
          </label>
          <div className={`field${won ? ' field--won' : ''}`}>
            <textarea
              id="password"
              ref={textareaRef}
              className="field__input"
              value={password}
              onChange={(e) => setPassword(e.target.value.replace(/\r?\n/g, ''))}
              autoComplete="off"
              autoCapitalize="off"
              spellCheck={false}
              rows={1}
              autoFocus
            />
            <output className="field__count" htmlFor="password" aria-live="polite" data-testid="char-count">
              {password.length} {password.length === 1 ? 'char' : 'chars'}
            </output>
          </div>

          <div className="progress" aria-label={`${passed} of ${RULES.length} rules passed`}>
            <div className="progress__track">
              <div className="progress__fill" style={{ width: `${(passed / RULES.length) * 100}%` }} />
            </div>
            <span className="progress__text">
              <strong>{passed}</strong> / {RULES.length} rules passed
              {revealed < RULES.length && <span className="progress__hint"> · {RULES.length - revealed} still hidden</span>}
            </span>
          </div>

          {won && (
            <div className="win" role="status">
              <p className="win__eyebrow">Password accepted</p>
              <p className="win__title">All 14 rules satisfied. Confetti for you.</p>
              <code className="win__password">{password}</code>
            </div>
          )}

          <ol className="rules" aria-label="Rules">
            {ordered.map((state) => (
              <RuleCard key={state.rule.id} state={state} isNewest={state.rule.id === newest && !won} />
            ))}
          </ol>
        </section>

        <aside className="sidebar">
          <ClockWidget now={now} />
          <WordleBoard board={wordle} />
          <section className="widget widget--sponsors" aria-label="Sponsors">
            <h2 className="widget__title">Our sponsors</h2>
            <ul className="sponsors">
              {SPONSORS.map((s) => (
                <li key={s} className={`sponsor sponsor--${s}`}>
                  {s}
                </li>
              ))}
            </ul>
            <p className="widget__note">Rule 8 wants one of these names in your password.</p>
          </section>
        </aside>
      </main>
    </div>
  )
}
