import { useRef, useState } from 'react'
import type { KeyboardEvent } from 'react'
import type { WidgetProps } from './types'

interface TabDef {
  id: string
  label: string
  heading: string
  body: string
  hidden?: boolean
}

const TABS: TabDef[] = [
  {
    id: 'overview',
    label: 'Overview',
    heading: 'Project overview',
    body: 'Gauntlet is a six-widget accessibility drill. Every control on this page is reachable with the keyboard alone.',
  },
  {
    id: 'activity',
    label: 'Activity',
    heading: 'Recent activity',
    body: '14 commits this week · 3 pull requests merged · 0 pointer events handled.',
  },
  {
    id: 'members',
    label: 'Members',
    heading: 'Team members',
    body: 'Ada, Grace, Linus and Margaret have access. All four navigate by keyboard.',
  },
  {
    id: 'billing',
    label: 'Billing',
    heading: 'Billing',
    body: 'Free tier. Unlimited keystrokes, zero clicks included.',
  },
  {
    id: 'integrations',
    label: 'Integrations',
    heading: 'Integrations',
    body: 'Connected: screen readers, switch access, voice control.',
  },
  {
    id: 'hidden',
    label: 'Hidden',
    heading: 'You found the hidden tab',
    body: 'This tab sits at the end of the list and is greyed out until it is selected. Press Tab to reach the button below and claim it.',
    hidden: true,
  },
]

export function TabsTask({ onComplete }: WidgetProps) {
  const [selected, setSelected] = useState(0)
  const [claimed, setClaimed] = useState(false)
  const tabRefs = useRef<(HTMLButtonElement | null)[]>([])

  const focusTab = (i: number) => {
    setSelected(i)
    tabRefs.current[i]?.focus()
  }

  const onKeyDown = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const n = TABS.length
    switch (e.key) {
      case 'ArrowRight':
        focusTab((i + 1) % n)
        break
      case 'ArrowLeft':
        focusTab((i - 1 + n) % n)
        break
      case 'Home':
        focusTab(0)
        break
      case 'End':
        focusTab(n - 1)
        break
      default:
        return
    }
    e.preventDefault()
  }

  const tab = TABS[selected]

  return (
    <div className="tabs-shell">
      <div role="tablist" aria-label="Project settings" className="tablist">
        {TABS.map((t, i) => (
          <button
            key={t.id}
            type="button"
            role="tab"
            id={`tab-${t.id}`}
            aria-selected={i === selected}
            aria-controls={`panel-${t.id}`}
            tabIndex={i === selected ? 0 : -1}
            className={`tab${t.hidden ? ' ghost' : ''}${i === selected ? ' selected' : ''}`}
            ref={(el) => {
              tabRefs.current[i] = el
            }}
            onKeyDown={(e) => onKeyDown(e, i)}
            onFocus={() => setSelected(i)}
          >
            {t.label}
          </button>
        ))}
      </div>
      <div
        role="tabpanel"
        id={`panel-${tab.id}`}
        aria-labelledby={`tab-${tab.id}`}
        tabIndex={tab.hidden ? undefined : 0}
        className={`tabpanel${tab.hidden ? ' hidden-panel' : ''}`}
      >
        <h3>{tab.heading}</h3>
        <p>{tab.body}</p>
        {tab.hidden && (
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => {
              setClaimed(true)
              onComplete()
            }}
          >
            {claimed ? 'Claimed' : 'Claim the hidden tab'}
          </button>
        )}
      </div>
      <p className="widget-status" aria-live="polite">
        Tab {selected + 1} of {TABS.length} selected: <strong>{tab.label}</strong>
      </p>
    </div>
  )
}
