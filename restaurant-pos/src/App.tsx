import { useReducer, useState, type ReactNode } from 'react'
import { FloorPlan } from './components/FloorPlan'
import { KitchenView } from './components/KitchenView'
import { OrderView } from './components/OrderView'
import { PaymentView } from './components/PaymentView'
import { SeatPartyModal } from './components/SeatPartyModal'
import { TopBar, type NavView } from './components/TopBar'
import { createSeedState } from './data/seed'
import { nowIso } from './lib/time'
import { reducer } from './state/reducer'
import './App.css'

type Screen =
  | { kind: 'floor' }
  | { kind: 'order'; tableId: string }
  | { kind: 'pay'; tableId: string }
  | { kind: 'kitchen'; from: Screen }

export default function App() {
  const [state, dispatch] = useReducer(reducer, undefined, createSeedState)
  const [screen, setScreen] = useState<Screen>({ kind: 'floor' })
  const [seatingTableId, setSeatingTableId] = useState<string | null>(null)

  const openTickets = state.tickets.filter((t) => !t.bumped).length
  const navView: NavView = screen.kind === 'kitchen' ? 'kitchen' : 'floor'

  const tableFor = (tableId: string) => state.tables.find((t) => t.id === tableId)
  const checkFor = (tableId: string) => {
    const table = tableFor(tableId)
    return table?.checkId ? state.checks[table.checkId] : undefined
  }

  const openTable = (tableId: string) => {
    if (state.editLayout) return
    if (checkFor(tableId)) setScreen({ kind: 'order', tableId })
    else setSeatingTableId(tableId)
  }

  const navigate = (view: NavView) => {
    if (view === 'kitchen') {
      if (screen.kind !== 'kitchen') setScreen({ kind: 'kitchen', from: screen })
    } else {
      setScreen({ kind: 'floor' })
    }
  }

  const floor = (
    <FloorPlan
      tables={state.tables}
      checks={state.checks}
      editLayout={state.editLayout}
      onOpenTable={openTable}
      onMoveTable={(tableId, x, y) => dispatch({ type: 'moveTable', tableId, x, y })}
    />
  )

  let body: ReactNode
  if (screen.kind === 'kitchen') {
    const from = screen.from
    const focusTable = from.kind === 'order' || from.kind === 'pay' ? (tableFor(from.tableId)?.number ?? null) : null
    body = <KitchenView tickets={state.tickets} focusTable={focusTable} dispatch={dispatch} onBack={() => setScreen(from)} />
  } else if (screen.kind === 'order' || screen.kind === 'pay') {
    const table = tableFor(screen.tableId)
    const check = checkFor(screen.tableId)
    if (!table || !check) {
      body = floor
    } else if (screen.kind === 'order') {
      body = (
        <OrderView
          table={table}
          check={check}
          dispatch={dispatch}
          onBack={() => setScreen({ kind: 'floor' })}
          onPay={() => setScreen({ kind: 'pay', tableId: table.id })}
          onKitchen={() => setScreen({ kind: 'kitchen', from: screen })}
        />
      )
    } else {
      body = (
        <PaymentView
          table={table}
          check={check}
          dispatch={dispatch}
          onBack={() => setScreen({ kind: 'order', tableId: table.id })}
          onClosed={() => setScreen({ kind: 'floor' })}
        />
      )
    }
  } else {
    body = floor
  }

  const seatingTable = seatingTableId ? tableFor(seatingTableId) : undefined

  return (
    <div className="app-shell">
      <TopBar
        view={navView}
        onNavigate={navigate}
        openTickets={openTickets}
        editLayout={state.editLayout}
        onToggleEdit={() => dispatch({ type: 'toggleEditLayout' })}
        onReset={() => {
          dispatch({ type: 'reset' })
          setScreen({ kind: 'floor' })
          setSeatingTableId(null)
        }}
        showEdit={screen.kind === 'floor'}
      />
      <main className="app-main">{body}</main>

      {seatingTable && (
        <SeatPartyModal
          table={seatingTable}
          onClose={() => setSeatingTableId(null)}
          onSeat={(partySize) => {
            dispatch({ type: 'seatParty', tableId: seatingTable.id, partySize, openedAt: nowIso() })
            setSeatingTableId(null)
            setScreen({ kind: 'order', tableId: seatingTable.id })
          }}
        />
      )}
    </div>
  )
}
