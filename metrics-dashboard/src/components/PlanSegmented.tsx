import { ALL_PLANS, type PlanFilter } from '../data/aggregate'

interface Props {
  value: PlanFilter
  onChange: (plan: PlanFilter) => void
}

const OPTIONS: PlanFilter[] = ['All', ...ALL_PLANS]

export function PlanSegmented({ value, onChange }: Props) {
  return (
    <div className="field">
      <span className="field__label">Plan</span>
      <div className="segmented" role="radiogroup" aria-label="Plan filter" data-testid="plan-filter">
        {OPTIONS.map((plan) => (
          <button
            key={plan}
            type="button"
            role="radio"
            aria-checked={plan === value}
            className={`segmented__item${plan === value ? ' segmented__item--active' : ''}`}
            onClick={() => onChange(plan)}
            data-testid={`plan-${plan}`}
          >
            {plan}
          </button>
        ))}
      </div>
    </div>
  )
}
