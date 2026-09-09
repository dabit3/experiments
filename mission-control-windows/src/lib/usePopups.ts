import { useCallback, useEffect, useRef, useState } from 'react'
import type { ConsoleRole } from './types'

export const CONSOLE_ROUTES: Record<ConsoleRole, string> = {
  propulsion: '/propulsion',
  guidance: '/guidance',
}

const POPUP_WIDTH = 680
const POPUP_MAX_HEIGHT = 560
const POPUP_GAP = 16
const TITLEBAR_ALLOWANCE = 44

export type PopupStatus = 'closed' | 'open' | 'blocked'

/** Two popups stacked down the right edge of the screen, sized so both fit. */
function popupFeatures(index: number): string {
  const { availWidth, availHeight } = window.screen
  const height = Math.min(
    POPUP_MAX_HEIGHT,
    Math.floor((availHeight - POPUP_GAP * 3) / 2) - TITLEBAR_ALLOWANCE,
  )
  const left = Math.max(0, availWidth - POPUP_WIDTH - POPUP_GAP)
  const top = POPUP_GAP + index * (height + TITLEBAR_ALLOWANCE + POPUP_GAP)
  return [
    'popup=yes',
    `width=${POPUP_WIDTH}`,
    `height=${height}`,
    `left=${left}`,
    `top=${top}`,
    'resizable=yes',
  ].join(',')
}

/**
 * Opens and tracks the two console popups. `window.open` returning null means
 * the browser blocked it, which flips that console into the tab fallback.
 */
export function usePopups(onEvent: (role: ConsoleRole, status: PopupStatus) => void) {
  const windows = useRef<Partial<Record<ConsoleRole, Window>>>({})
  const [status, setStatus] = useState<Record<ConsoleRole, PopupStatus>>({
    propulsion: 'closed',
    guidance: 'closed',
  })

  const update = useCallback(
    (role: ConsoleRole, next: PopupStatus) => {
      setStatus((prev) => (prev[role] === next ? prev : { ...prev, [role]: next }))
      onEvent(role, next)
    },
    [onEvent],
  )

  const open = useCallback(
    (role: ConsoleRole) => {
      const existing = windows.current[role]
      if (existing && !existing.closed) {
        existing.focus()
        return
      }
      const index = role === 'propulsion' ? 0 : 1
      const win = window.open(CONSOLE_ROUTES[role], `mission-control-${role}`, popupFeatures(index))
      if (!win) {
        update(role, 'blocked')
        return
      }
      windows.current[role] = win
      win.focus()
      update(role, 'open')
    },
    [update],
  )

  const focus = useCallback((role: ConsoleRole) => {
    const win = windows.current[role]
    if (win && !win.closed) win.focus()
  }, [])

  useEffect(() => {
    const id = window.setInterval(() => {
      for (const role of Object.keys(windows.current) as ConsoleRole[]) {
        const win = windows.current[role]
        if (win && win.closed) {
          delete windows.current[role]
          update(role, 'closed')
        }
      }
    }, 500)
    return () => window.clearInterval(id)
  }, [update])

  return { status, open, focus }
}
