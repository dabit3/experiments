import { useState, type FormEvent } from 'react'
import { matchReport, type MatchResult } from '../lib/matcher'
import { TOTAL_BUGS } from '../types'

const BUG_AREAS = [
  'Cart & totals',
  'Sorting & filtering',
  'Search',
  'Pagination',
  'Product card',
  'Coupons & checkout',
  'Buttons & layout',
  'Other',
]

interface Props {
  found: string[]
  onFound: (bugId: string) => void
}

export function BugReporter({ found, onFound }: Props) {
  const [open, setOpen] = useState(false)
  const [area, setArea] = useState(BUG_AREAS[0])
  const [description, setDescription] = useState('')
  const [result, setResult] = useState<MatchResult | null>(null)

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const match = matchReport(area, description, found)
    setResult(match)
    if (match.kind === 'found') {
      onFound(match.bug.id)
      setDescription('')
    }
  }

  const remaining = TOTAL_BUGS - found.length

  return (
    <div className={`reporter ${open ? 'reporter-open' : ''}`}>
      {open && (
        <form className="reporter-panel" onSubmit={submit} aria-label="Report a bug">
          <header className="reporter-header">
            <div>
              <p className="eyebrow">QA · Issue report</p>
              <h2>Report a bug</h2>
              <p className="muted small">
                {remaining === 0 ? 'Every bug has been found.' : `${remaining} still hiding in the store.`}
              </p>
            </div>
            <button type="button" className="icon-btn" onClick={() => setOpen(false)} aria-label="Close bug report">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M5 5l14 14M19 5 5 19" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
              </svg>
            </button>
          </header>
          <label>
            Where is it?
            <select value={area} onChange={(e) => setArea(e.target.value)}>
              {BUG_AREAS.map((a) => (
                <option key={a}>{a}</option>
              ))}
            </select>
          </label>
          <label>
            What went wrong?
            <textarea
              rows={4}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="What you did, what you expected, what actually happened."
              required
            />
          </label>
          {result && (
            <div className={`reporter-result reporter-result-${result.kind}`} role="status">
              {result.kind === 'found' && (
                <>
                  <strong>Confirmed.</strong> {result.bug.title}
                </>
              )}
              {result.kind === 'already' && (
                <>
                  <strong>Already logged.</strong> {result.bug.title}
                </>
              )}
              {result.kind === 'none' && (
                <>
                  <strong>Couldn't reproduce.</strong> Name the feature and exactly what looked wrong.
                </>
              )}
            </div>
          )}
          <button type="submit" className="btn btn-primary btn-block btn-lg" disabled={!description.trim()}>
            Submit report
          </button>
        </form>
      )}
      <button
        type="button"
        className="reporter-fab"
        onClick={() => {
          setOpen((o) => !o)
          setResult(null)
        }}
        aria-expanded={open}
      >
        <span className="reporter-dot" aria-hidden="true" />
        Report a bug
      </button>
    </div>
  )
}
