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
              <h2>Report a bug</h2>
              <p className="muted small">
                {remaining === 0 ? 'Every bug has been found.' : `${remaining} still hiding in the store.`}
              </p>
            </div>
            <button type="button" className="icon-btn" onClick={() => setOpen(false)} aria-label="Close bug report">
              ×
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
              placeholder="Describe what you did, what you expected and what actually happened."
              required
            />
          </label>
          {result && (
            <div className={`reporter-result reporter-result-${result.kind}`} role="status">
              {result.kind === 'found' && (
                <>
                  <strong>Confirmed!</strong> {result.bug.title}
                </>
              )}
              {result.kind === 'already' && (
                <>
                  <strong>Already logged.</strong> {result.bug.title}
                </>
              )}
              {result.kind === 'none' && (
                <>
                  <strong>Couldn't reproduce.</strong> Try naming the feature and exactly what looked wrong.
                </>
              )}
            </div>
          )}
          <button type="submit" className="btn btn-primary btn-block" disabled={!description.trim()}>
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
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            d="M12 3a4 4 0 0 1 4 4v1h2l2-2 1.4 1.4L19 9.8V12h3v2h-3v1a7 7 0 0 1-.6 2.8l2.4 2.4-1.4 1.4-2.3-2.3A7 7 0 0 1 12 22a7 7 0 0 1-5.1-2.7l-2.3 2.3-1.4-1.4 2.4-2.4A7 7 0 0 1 5 15v-1H2v-2h3V9.8L2.6 7.4 4 6l2 2h2V7a4 4 0 0 1 4-4Zm0 2a2 2 0 0 0-2 2v1h4V7a2 2 0 0 0-2-2Zm-5 9v1a5 5 0 0 0 4 4.9V10H7v4Zm6 5.9A5 5 0 0 0 17 15v-5h-4v9.9Z"
            fill="currentColor"
          />
        </svg>
        Report a bug
      </button>
    </div>
  )
}
