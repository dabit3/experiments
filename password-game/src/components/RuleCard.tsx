import type { RuleState } from '../rules'

export function RuleCard({ state, isNewest }: { state: RuleState; isNewest: boolean }) {
  const { rule, result } = state
  const status = result.pass ? 'pass' : 'fail'
  return (
    <li
      className={`rule rule--${status}${isNewest ? ' rule--newest' : ''}`}
      data-rule={rule.id}
      data-status={status}
      aria-label={`Rule ${rule.id}: ${result.pass ? 'passed' : 'failing'}`}
    >
      <div className="rule__status" aria-hidden="true">
        {result.pass ? (
          <svg viewBox="0 0 24 24" width="22" height="22">
            <path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        ) : (
          <svg viewBox="0 0 24 24" width="22" height="22">
            <path d="M7 7l10 10M17 7L7 17" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
          </svg>
        )}
      </div>
      <div className="rule__body">
        <div className="rule__head">
          <span className="rule__num">Rule {rule.id}</span>
          <span className="rule__verdict">{result.pass ? 'Passed' : 'Failing'}</span>
        </div>
        <p className="rule__title">{rule.title}</p>
        {result.detail && <p className="rule__detail">{result.detail}</p>}
      </div>
    </li>
  )
}
