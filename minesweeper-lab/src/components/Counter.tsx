interface Props {
  value: number
  label: string
  testId: string
}

/** Three-digit LED-style read-out. Negative values show as -NN like the original. */
export function Counter({ value, label, testId }: Props) {
  const clamped = Math.max(-99, Math.min(999, value))
  const text = clamped < 0 ? `-${String(Math.abs(clamped)).padStart(2, '0')}` : String(clamped).padStart(3, '0')
  return (
    <div className="counter" role="status" aria-label={`${label}: ${clamped}`} data-testid={testId}>
      <span className="counter-ghost" aria-hidden="true">
        888
      </span>
      <span className="counter-value">{text}</span>
    </div>
  )
}
