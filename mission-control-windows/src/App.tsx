import { useEffect } from 'react'
import { DEFAULT_SEED, ROLE_LABEL } from './lib/mission'
import type { Role } from './lib/types'
import { GuidanceConsole } from './views/GuidanceConsole'
import { MainWindow } from './views/MainWindow'
import { PropulsionConsole } from './views/PropulsionConsole'

function roleFromPath(pathname: string): Role {
  const path = pathname.replace(/\/+$/, '')
  if (path === '/propulsion') return 'propulsion'
  if (path === '/guidance') return 'guidance'
  return 'main'
}

export default function App() {
  const role = roleFromPath(window.location.pathname)
  const seed = new URLSearchParams(window.location.search).get('seed') || DEFAULT_SEED

  useEffect(() => {
    document.title = role === 'main' ? 'Mission Control' : `${ROLE_LABEL[role]} · Mission Control`
    document.documentElement.dataset.role = role
  }, [role])

  if (role === 'propulsion') return <PropulsionConsole />
  if (role === 'guidance') return <GuidanceConsole />
  return <MainWindow seed={seed} />
}
