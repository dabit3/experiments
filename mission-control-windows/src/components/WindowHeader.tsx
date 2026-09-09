import type { ReactNode } from 'react'
import { formatMet } from '../lib/mission'
import type { MissionState, Role } from '../lib/types'

interface WindowHeaderProps {
  role: Role
  title: string
  state: MissionState | null
  children?: ReactNode
}

const PHASE_LABEL: Record<MissionState['phase'], string> = {
  checklist: 'Pre-launch',
  countdown: 'Terminal count',
  aborted: 'Aborted',
  launched: 'In flight',
}

export function WindowHeader({ role, title, state, children }: WindowHeaderProps) {
  const phase = state?.phase ?? 'checklist'
  return (
    <header className={`winhead winhead--${role}`}>
      <div className="winhead__brand">
        <span className="winhead__mark" aria-hidden="true" />
        <div>
          <div className="winhead__title display">{title}</div>
          <div className="winhead__sub caption">
            {state ? `${state.seed} · ${state.vehicle}` : 'Linking to Main…'}
          </div>
        </div>
      </div>
      <div className="winhead__right">
        {children}
        <span className={`phase phase--${phase}`}>{PHASE_LABEL[phase]}</span>
        <span className="met mono" aria-label="Mission elapsed time">
          {formatMet(state?.met ?? 0)}
        </span>
      </div>
    </header>
  )
}
