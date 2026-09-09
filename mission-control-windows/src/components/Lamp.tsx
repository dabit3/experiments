interface LampProps {
  on: boolean
  label: string
  tone?: 'green' | 'amber' | 'cyan' | 'red'
}

export function Lamp({ on, label, tone = 'green' }: LampProps) {
  const classes = ['lamp']
  if (on) classes.push('lamp--on')
  if (on && tone !== 'green') classes.push(`lamp--${tone}`)
  return (
    <span className={classes.join(' ')} role="status" aria-label={`${label}: ${on ? 'on' : 'off'}`}>
      <span className="lamp__dot" aria-hidden="true" />
      {label}
    </span>
  )
}
