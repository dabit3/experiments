import type { FormEvent, ReactNode } from 'react'
import { Lamp } from './Lamp'

export type ControlStatus = 'pending' | 'live' | 'done'

interface ControlProps {
  step: number
  title: string
  status: ControlStatus
  lampOn: boolean
  lampLabel: string
  lampTone?: 'green' | 'amber' | 'cyan' | 'red'
  /** Shown while pending or done; live controls show their own hint. */
  summary: string
  as?: 'section' | 'form'
  onSubmit?: (event: FormEvent<HTMLFormElement>) => void
  children: ReactNode
}

/**
 * One console instrument. Only the live step is expanded; completed and
 * upcoming steps collapse to a header row so the popup fits on screen.
 */
export function Control({
  step,
  title,
  status,
  lampOn,
  lampLabel,
  lampTone,
  summary,
  as = 'section',
  onSubmit,
  children,
}: ControlProps) {
  const head = (
    <div className="control__head">
      <span className="control__title display">
        <span className="control__step mono">{step}</span>
        {title}
      </span>
      <Lamp on={lampOn} label={lampLabel} tone={lampTone} />
    </div>
  )
  const body =
    status === 'live' ? (
      <div className="control__body">{children}</div>
    ) : (
      <p className="control__summary">{summary}</p>
    )
  const className = `control control--${status}`

  if (as === 'form') {
    return (
      <form className={className} onSubmit={onSubmit} noValidate aria-current={status === 'live' ? 'step' : undefined}>
        {head}
        {body}
      </form>
    )
  }
  return (
    <section className={className} aria-current={status === 'live' ? 'step' : undefined}>
      {head}
      {body}
    </section>
  )
}
