import type { ReactNode } from 'react'
import { ANSWERS, DICTIONARY_SIZE } from '../lib/words'
import { Modal } from './Modal'
import './HelpModal.css'

interface HelpModalProps {
  open: boolean
  onClose: () => void
}

export function HelpModal({ open, onClose }: HelpModalProps) {
  return (
    <Modal open={open} onClose={onClose} title="How to play">
      <p className="help__lead">Guess the word in 6 tries.</p>
      <ul className="help__rules">
        <li>Each guess must be a valid 5-letter word.</li>
        <li>The colour of the tiles shows how close your guess was.</li>
        <li>
          The answer is picked from the <code>?seed=N</code> in the URL, so the same seed always
          gives the same word.
        </li>
        <li>
          <strong>Hard mode</strong>: any revealed hint must be used in your next guess.
        </li>
      </ul>

      <h3 className="help__subtitle">Examples</h3>
      <Example word="weary" highlight={0} state="correct">
        <strong>W</strong> is in the word and in the correct spot.
      </Example>
      <Example word="pills" highlight={1} state="present">
        <strong>I</strong> is in the word but in the wrong spot.
      </Example>
      <Example word="vague" highlight={3} state="absent">
        <strong>U</strong> is not in the word in any spot.
      </Example>

      <p className="help__footnote">
        {ANSWERS.length.toLocaleString()} possible answers · {DICTIONARY_SIZE.toLocaleString()}{' '}
        accepted guesses · everything runs offline in your browser.
      </p>
    </Modal>
  )
}

function Example({
  word,
  highlight,
  state,
  children,
}: {
  word: string
  highlight: number
  state: 'correct' | 'present' | 'absent'
  children: ReactNode
}) {
  return (
    <div className="help__example">
      <div className="help__tiles">
        {word.split('').map((letter, i) => (
          <span key={i} className={`help__tile ${i === highlight ? `help__tile--${state}` : ''}`}>
            {letter}
          </span>
        ))}
      </div>
      <p>{children}</p>
    </div>
  )
}
