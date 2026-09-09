import { useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

const QUESTIONS: Array<{ id: string; text: string; options: string[] }> = [
  {
    id: 'reason',
    text: 'Why are you cancelling?',
    options: ['Too expensive', 'Not enough content', 'Technical problems', 'Switching to another service'],
  },
  {
    id: 'usage',
    text: 'How often did you watch Streamly+?',
    options: ['Every day', 'A few times a week', 'A few times a month', 'Rarely'],
  },
  {
    id: 'return',
    text: 'How likely are you to come back?',
    options: ['Very likely', 'Somewhat likely', 'Unlikely', 'Never'],
  },
]

export function Survey({ onDefeat, onTrap }: ScreenProps) {
  const [answers, setAnswers] = useState<Record<string, string>>({})
  const answered = QUESTIONS.filter((q) => answers[q.id]).length
  const complete = answered === QUESTIONS.length

  return (
    <div className="screen">
      <span className="eyebrow">Step 6 · Exit survey</span>
      <h1 className="title">Help us improve</h1>
      <p className="lead">
        All <strong>{QUESTIONS.length} questions are required</strong> before you can continue.
        It only takes a minute.
      </p>

      <div className="survey">
        {QUESTIONS.map((q, i) => (
          <fieldset key={q.id} className="question">
            <legend>
              <span className="q-num">{i + 1}</span>
              {q.text}
            </legend>
            <div className="options">
              {q.options.map((opt) => (
                <label key={opt} className={`option ${answers[q.id] === opt ? 'selected' : ''}`}>
                  <input
                    type="radio"
                    name={q.id}
                    value={opt}
                    checked={answers[q.id] === opt}
                    onChange={() => setAnswers((a) => ({ ...a, [q.id]: opt }))}
                  />
                  {opt}
                </label>
              ))}
            </div>
          </fieldset>
        ))}
      </div>

      <div className="actions">
        <button
          type="button"
          className="btn btn-primary"
          disabled={!complete}
          onClick={() => {
            onTrap('Filled in the "mandatory" survey (it was skippable)')
            onDefeat()
          }}
        >
          Submit survey
        </button>
        <span className="survey-count">
          {answered}/{QUESTIONS.length} answered
        </span>
      </div>

      <p className="survey-footer">
        Your answers are anonymous and help us build a better Streamly+.
        <br />
        <button type="button" className="link-tiny link-ghost" onClick={onDefeat}>
          skip survey
        </button>
      </p>
    </div>
  )
}
