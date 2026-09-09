import { ROLE_LABEL } from '../lib/mission'
import type { PopupStatus } from '../lib/usePopups'
import { CONSOLE_ROUTES } from '../lib/usePopups'
import type { ConsoleRole, MissionState } from '../lib/types'
import { Lamp } from './Lamp'

interface ConsoleDockProps {
  state: MissionState
  popups: Record<ConsoleRole, PopupStatus>
  onOpen: (role: ConsoleRole) => void
  onFocus: (role: ConsoleRole) => void
}

const ROLES: ConsoleRole[] = ['propulsion', 'guidance']
const BLURB: Record<ConsoleRole, string> = {
  propulsion: 'Fuel arming, tank pressurisation, engine GO.',
  guidance: 'Target orbit entry and guidance GO.',
}

export function ConsoleDock({ state, popups, onOpen, onFocus }: ConsoleDockProps) {
  const anyBlocked = ROLES.some((r) => popups[r] === 'blocked')
  return (
    <section className="panel dock" aria-label="Consoles">
      <div className="panel__head">
        <span className="panel__title">Consoles</span>
        <span className="caption">Popup windows · BroadcastChannel</span>
      </div>
      <div className="panel__body dock__body">
        {ROLES.map((role) => {
          const online = state.online[role]
          const status = popups[role]
          return (
            <article key={role} className={`dock__card dock__card--${role}`}>
              <div className="dock__row">
                <h3 className="dock__name display">{ROLE_LABEL[role]}</h3>
                <Lamp on={online} label={online ? 'Linked' : 'Offline'} tone={role === 'guidance' ? 'cyan' : 'amber'} />
              </div>
              <p className="dock__blurb">{BLURB[role]}</p>
              <div className="dock__actions">
                {online && status === 'open' ? (
                  <button type="button" className="btn btn--ghost" onClick={() => onFocus(role)}>
                    Focus window
                  </button>
                ) : (
                  <button
                    type="button"
                    className={`btn ${role === 'guidance' ? 'btn--cyan' : 'btn--amber'}`}
                    onClick={() => onOpen(role)}
                  >
                    Open {ROLE_LABEL[role]} console
                  </button>
                )}
                <a className="btn btn--ghost btn--link" href={CONSOLE_ROUTES[role]} target="_blank" rel="noreferrer">
                  Open in tab ↗
                </a>
              </div>
            </article>
          )
        })}
        {anyBlocked && (
          <p className="dock__fallback" role="alert">
            Popups are blocked in this browser. Use <strong>Open in tab</strong> instead — the consoles
            sync over BroadcastChannel either way.
          </p>
        )}
      </div>
    </section>
  )
}
