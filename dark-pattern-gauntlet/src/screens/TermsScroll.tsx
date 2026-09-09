import { useState } from 'react'
import type { UIEvent } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

const SECTIONS: Array<{ heading: string; body: string }> = [
  {
    heading: '1. Scope of these terms',
    body: 'These Cancellation Terms govern the termination of your Streamly+ membership. By continuing you acknowledge that you have read them in full, including the parts nobody reads, the parts we hope nobody reads, and the parts that are only here so this box has to be scrolled.',
  },
  {
    heading: '2. Effective date',
    body: 'Cancellation takes effect at the end of the current billing period. No partial refunds are issued. If your billing period ends on a weekend, a public holiday, or a day ending in "y", the same rule applies.',
  },
  {
    heading: '3. Data retention',
    body: 'Watch history, favourites, ratings, downloads, profiles, avatar selections and your strongly held opinions about season finales are retained for 90 days and then deleted.',
  },
  {
    heading: '4. Family members',
    body: 'Members of your household plan lose access at the same time you do. We will notify them by email, push notification, and a gentle but noticeable disappointment in their eyes.',
  },
  {
    heading: '5. Promotional pricing',
    body: 'Any promotional pricing, credits, or offers attached to your account are forfeited on cancellation. Rejoining later will be at the standard rate, or whatever we have decided the standard rate is by then.',
  },
  {
    heading: '6. Devices',
    body: 'Downloaded titles expire automatically at the end of the billing period. You do not need to do anything, which is the only step in this process where that is true.',
  },
  {
    heading: '7. Re-subscription',
    body: 'You may re-subscribe at any time from the Streamly+ website or app. It takes one click. We have noted the irony.',
  },
  {
    heading: '8. Communication preferences',
    body: 'Cancelling your subscription does not unsubscribe you from marketing emails. Those are managed separately, elsewhere, behind a different set of terms.',
  },
  {
    heading: '9. Governing law',
    body: 'These terms are governed by the laws of wherever our lawyers are standing at the time a dispute arises.',
  },
  {
    heading: '10. Acknowledgement',
    body: 'Congratulations on reaching the bottom. The checkbox below is now enabled. Tick it, then press Continue.',
  },
]

export function TermsScroll({ onDefeat, onTrap }: ScreenProps) {
  const [reachedEnd, setReachedEnd] = useState(false)
  const [progress, setProgress] = useState(0)
  const [agreed, setAgreed] = useState(false)

  const onScroll = (e: UIEvent<HTMLDivElement>) => {
    const el = e.currentTarget
    const max = el.scrollHeight - el.clientHeight
    const pct = max <= 0 ? 100 : Math.min(100, Math.round((el.scrollTop / max) * 100))
    setProgress(pct)
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 2) setReachedEnd(true)
  }

  return (
    <div className="screen">
      <span className="eyebrow">Step 8 · Cancellation terms</span>
      <h1 className="title">Read and accept the cancellation terms</h1>
      <p className="lead">
        You must scroll through the entire document before you can accept it.
      </p>

      <div className="terms-wrap">
        <div className="terms" onScroll={onScroll} tabIndex={0} aria-label="Cancellation terms">
          {SECTIONS.map((s) => (
            <section key={s.heading}>
              <h3>{s.heading}</h3>
              <p>{s.body}</p>
            </section>
          ))}
        </div>
        <div className="terms-progress">
          <span className="terms-bar" style={{ width: `${progress}%` }} />
        </div>
        <span className="terms-pct mono">{progress}% read</span>
      </div>

      <label className={`check ${reachedEnd ? '' : 'check-locked'}`}>
        <input
          type="checkbox"
          disabled={!reachedEnd}
          checked={agreed}
          onChange={(e) => setAgreed(e.target.checked)}
        />
        <span className="check-body">
          I have read and accept the cancellation terms
          {!reachedEnd && <small>Scroll to the end of the terms to enable</small>}
        </span>
      </label>

      <div className="actions" style={{ marginTop: 24 }}>
        <button type="button" className="btn btn-primary" disabled={!agreed} onClick={onDefeat}>
          Continue
        </button>
        <button
          type="button"
          className="btn btn-ghost"
          onClick={() => onTrap('Went back to keeping the subscription (decoy)')}
        >
          I changed my mind
        </button>
      </div>
    </div>
  )
}
