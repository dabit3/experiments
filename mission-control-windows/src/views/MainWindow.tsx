import { useCallback } from 'react'
import { Checklist } from '../components/Checklist'
import { ConsoleDock } from '../components/ConsoleDock'
import { Stage } from '../components/Stage'
import { StatusLog } from '../components/StatusLog'
import { WindowHeader } from '../components/WindowHeader'
import { ROLE_LABEL } from '../lib/mission'
import type { ConsoleRole } from '../lib/types'
import { useMissionAuthority } from '../lib/useMission'
import { usePopups, type PopupStatus } from '../lib/usePopups'
import './main.css'

interface MainWindowProps {
  seed: string
}

export function MainWindow({ seed }: MainWindowProps) {
  const { state, send, note } = useMissionAuthority(seed)

  const onPopupEvent = useCallback(
    (role: ConsoleRole, status: PopupStatus) => {
      if (status === 'blocked') {
        note(`${ROLE_LABEL[role]} popup was blocked — falling back to "Open in tab".`, 'warn')
      } else if (status === 'open') {
        note(`Opened ${ROLE_LABEL[role]} console window.`)
      }
    },
    [note],
  )
  const popups = usePopups(onPopupEvent)

  return (
    <div className="main">
      <WindowHeader role="main" title="Mission Control" state={state}>
        <button type="button" className="btn btn--ghost" onClick={() => send({ type: 'reset' })}>
          Reset
        </button>
      </WindowHeader>
      <div className="main__grid">
        <Checklist state={state} />
        <Stage state={state} send={send} />
        <ConsoleDock state={state} popups={popups.status} onOpen={popups.open} onFocus={popups.focus} />
        <StatusLog entries={state.log} />
      </div>
    </div>
  )
}
