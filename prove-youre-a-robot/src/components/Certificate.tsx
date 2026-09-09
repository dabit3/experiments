import { STAGES } from '../stages/types'
import './Certificate.css'

export interface RunSummary {
  seed: number
  attempts: number[]
  elapsedMs: number
  finishedAt: number
}

interface Props {
  summary: RunSummary
  printable: boolean
  onTogglePrintable: () => void
  onRestart: () => void
}

function formatDuration(ms: number): string {
  const s = Math.round(ms / 1000)
  const m = Math.floor(s / 60)
  return m > 0 ? `${m}m ${String(s % 60).padStart(2, '0')}s` : `${s}s`
}

function checksum(summary: RunSummary): string {
  let h = 0x811c9dc5
  const feed = (n: number) => {
    h ^= n & 0xff
    h = Math.imul(h, 0x01000193) >>> 0
  }
  feed(summary.seed)
  summary.attempts.forEach(feed)
  feed(Math.round(summary.elapsedMs / 1000))
  return h.toString(16).toUpperCase().padStart(8, '0')
}

export function Certificate({ summary, printable, onTogglePrintable, onRestart }: Props) {
  const total = summary.attempts.reduce((a, b) => a + b, 0)
  const retries = total - STAGES.length
  const issued = new Date(summary.finishedAt)

  return (
    <div className={`cert-wrap${printable ? ' is-printable' : ''}`}>
      <article className="cert" aria-label={`Certified Robot #${summary.seed}`}>
        <div className="cert__border" />
        <header className="cert__head">
          <span className="cert__kicker">Bureau of Automated Verification</span>
          <h1 className="cert__title">Certified Robot</h1>
          <div className="cert__id">#{summary.seed}</div>
        </header>

        <p className="cert__body">
          This certifies that the bearer has completed the five-stage reverse-CAPTCHA gauntlet with pixel-precise
          motor control, unwavering rotational judgement and flawless corridor discipline — abilities no human
          could plausibly possess.
        </p>

        <dl className="cert__stats">
          <div>
            <dt>Seed</dt>
            <dd>{summary.seed}</dd>
          </div>
          <div>
            <dt>Elapsed</dt>
            <dd>{formatDuration(summary.elapsedMs)}</dd>
          </div>
          <div>
            <dt>Attempts</dt>
            <dd>
              {total} <small>({retries} {retries === 1 ? 'retry' : 'retries'})</small>
            </dd>
          </div>
          <div>
            <dt>Checksum</dt>
            <dd className="cert__mono">{checksum(summary)}</dd>
          </div>
        </dl>

        <ol className="cert__stages">
          {STAGES.map((s, i) => (
            <li key={s.id}>
              <span className="cert__stage-name">{s.title}</span>
              <span className="cert__stage-attempts">
                {summary.attempts[i]} {summary.attempts[i] === 1 ? 'attempt' : 'attempts'}
              </span>
            </li>
          ))}
        </ol>

        <footer className="cert__foot">
          <div className="cert__seal" aria-hidden="true">
            <svg viewBox="0 0 100 100" width={84} height={84}>
              <circle cx={50} cy={50} r={46} fill="none" stroke="currentColor" strokeWidth={3} />
              <circle cx={50} cy={50} r={38} fill="none" stroke="currentColor" strokeWidth={1} strokeDasharray="3 4" />
              <rect x={32} y={34} width={36} height={30} rx={6} fill="none" stroke="currentColor" strokeWidth={3} />
              <circle cx={43} cy={48} r={4} fill="currentColor" />
              <circle cx={57} cy={48} r={4} fill="currentColor" />
              <path d="M40 58 h20" stroke="currentColor" strokeWidth={3} strokeLinecap="round" />
              <path d="M50 34 v-8" stroke="currentColor" strokeWidth={3} strokeLinecap="round" />
              <circle cx={50} cy={24} r={3} fill="currentColor" />
            </svg>
          </div>
          <div className="cert__issued">
            <span>Issued {issued.toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })}</span>
            <span>Signed: 01001001 00100111 01101101</span>
          </div>
        </footer>
      </article>

      <div className="cert-actions">
        {printable ? (
          <>
            <button className="btn btn--primary btn--lg" onClick={() => window.print()}>
              Print
            </button>
            <button className="btn btn--lg" onClick={onTogglePrintable}>
              Back
            </button>
          </>
        ) : (
          <>
            <button className="btn btn--primary btn--lg" onClick={onTogglePrintable}>
              Printable certificate
            </button>
            <button className="btn btn--lg" onClick={onRestart}>
              Run the gauntlet again
            </button>
          </>
        )}
      </div>
    </div>
  )
}
