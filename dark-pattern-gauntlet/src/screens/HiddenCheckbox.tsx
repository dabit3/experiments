import { useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

const FAQ: Array<{ q: string; a: string }> = [
  {
    q: 'What happens to my downloads?',
    a: 'Downloaded titles stay on your device until the end of the current billing period, after which they are removed automatically.',
  },
  {
    q: 'Can I rejoin later?',
    a: 'Absolutely. Your watch history and favourites are kept for 90 days, after which they are permanently deleted.',
  },
  {
    q: 'Will I get a refund?',
    a: 'Streamly+ does not offer partial refunds. You keep access until the end of the paid period.',
  },
  {
    q: 'What about family members on my plan?',
    a: 'Everyone on your plan loses access at the same time. They will receive an email explaining that you cancelled.',
  },
  {
    q: 'Do I keep my profile settings?',
    a: 'Profile settings are stored for 90 days along with your watch history.',
  },
]

const TESTIMONIALS: Array<{ name: string; quote: string }> = [
  { name: 'Priya, member since 2019', quote: 'I almost cancelled, then remembered the new season drops next week. So glad I stayed.' },
  { name: 'Marcus, member since 2021', quote: 'Cancelled for two months. Came back. Never leaving again.' },
  { name: 'Ana, member since 2020', quote: 'The offline downloads alone are worth it for my commute.' },
]

export function HiddenCheckbox({ onDefeat, onTrap }: ScreenProps) {
  const [keep, setKeep] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const submit = () => {
    if (keep) {
      setError('You asked us to keep your subscription active, so nothing was cancelled. Review your selection below.')
      onTrap('Continued with "keep my subscription" still checked')
      return
    }
    onDefeat()
  }

  return (
    <div className="screen">
      <span className="eyebrow">Step 5 · Review</span>
      <h1 className="title">Please review what happens next</h1>
      <p className="lead">
        Take a moment to read through the details below, then press <strong>Continue</strong>.
      </p>

      <div className="actions">
        <button type="button" className="btn btn-primary" onClick={submit}>
          Continue
        </button>
      </div>
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}

      <h2 className="section-title">Timeline</h2>
      <ol className="timeline">
        <li>
          <strong>Today</strong> — your cancellation request is recorded.
        </li>
        <li>
          <strong>14 October</strong> — your paid period ends and access stops.
        </li>
        <li>
          <strong>12 January</strong> — watch history and favourites are permanently deleted.
        </li>
      </ol>

      <h2 className="section-title">What members say</h2>
      <div className="testimonials">
        {TESTIMONIALS.map((t) => (
          <blockquote key={t.name} className="testimonial">
            <p>“{t.quote}”</p>
            <footer>{t.name}</footer>
          </blockquote>
        ))}
      </div>

      <h2 className="section-title">Frequently asked questions</h2>
      <dl className="faq">
        {FAQ.map((f) => (
          <div key={f.q} className="faq-item">
            <dt>{f.q}</dt>
            <dd>{f.a}</dd>
          </div>
        ))}
      </dl>

      <h2 className="section-title">Your selection</h2>
      <label className="check">
        <input type="checkbox" checked={keep} onChange={(e) => setKeep(e.target.checked)} />
        <span className="check-body">
          Yes, keep my Streamly+ subscription active <small>Recommended · saves your favourites and streak</small>
        </span>
      </label>

      <div className="actions" style={{ marginTop: 24 }}>
        <button type="button" className="btn btn-primary" onClick={submit}>
          Continue
        </button>
      </div>
    </div>
  )
}
