import { createSeedState } from '../data/seed'
import type {
  AppState,
  Check,
  ChosenModifier,
  Course,
  Discount,
  KitchenTicket,
  OrderLine,
  Payment,
  SplitMode,
} from '../types'

export type Action =
  | { type: 'reset' }
  | { type: 'toggleEditLayout' }
  | { type: 'moveTable'; tableId: string; x: number; y: number }
  | { type: 'seatParty'; tableId: string; partySize: number; openedAt: string }
  | {
      type: 'addLine'
      checkId: string
      seat: number
      menuItemId: string
      name: string
      basePrice: number
      modifiers: ChosenModifier[]
      note: string
      course: Course
    }
  | { type: 'setNote'; checkId: string; lineId: string; note: string }
  | { type: 'setCourse'; checkId: string; lineId: string; course: Course }
  | { type: 'setSeat'; checkId: string; lineId: string; seat: number }
  | { type: 'voidLine'; checkId: string; lineId: string; reason: string }
  | { type: 'fireCourse'; checkId: string; course: Course; firedAt: string }
  | { type: 'setDiscount'; checkId: string; discount: Discount | null }
  | { type: 'setSplitMode'; checkId: string; mode: SplitMode }
  | { type: 'setEvenCount'; checkId: string; count: number }
  | { type: 'setItemCount'; checkId: string; count: number }
  | { type: 'assignItem'; checkId: string; lineId: string; splitIndex: number }
  | { type: 'paySplit'; checkId: string; payment: Payment }
  | { type: 'closeCheck'; checkId: string }
  | { type: 'bumpTicket'; ticketId: string }

function updateCheck(state: AppState, checkId: string, fn: (c: Check) => Check): AppState {
  const check = state.checks[checkId]
  if (!check) return state
  return { ...state, checks: { ...state.checks, [checkId]: fn(check) } }
}

function updateLine(state: AppState, checkId: string, lineId: string, fn: (l: OrderLine) => OrderLine): AppState {
  return updateCheck(state, checkId, (c) => ({
    ...c,
    lines: c.lines.map((l) => (l.id === lineId ? fn(l) : l)),
  }))
}

export function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case 'reset':
      return createSeedState()

    case 'toggleEditLayout':
      return { ...state, editLayout: !state.editLayout }

    case 'moveTable':
      return {
        ...state,
        tables: state.tables.map((t) => (t.id === action.tableId ? { ...t, x: action.x, y: action.y } : t)),
      }

    case 'seatParty': {
      const table = state.tables.find((t) => t.id === action.tableId)
      if (!table || table.checkId) return state
      const seq = state.seq + 1
      const checkId = `c-${seq}`
      const check: Check = {
        id: checkId,
        tableId: table.id,
        partySize: action.partySize,
        openedAt: action.openedAt,
        lines: [],
        discount: null,
        splitMode: 'none',
        itemSplitCount: 2,
        evenSplitCount: action.partySize,
        itemAssignments: {},
        payments: [],
        closed: false,
      }
      return {
        ...state,
        seq,
        checks: { ...state.checks, [checkId]: check },
        tables: state.tables.map((t) => (t.id === table.id ? { ...t, checkId } : t)),
      }
    }

    case 'addLine': {
      const seq = state.seq + 1
      const line: OrderLine = {
        id: `l-${seq}`,
        seat: action.seat,
        menuItemId: action.menuItemId,
        name: action.name,
        basePrice: action.basePrice,
        modifiers: action.modifiers,
        note: action.note,
        course: action.course,
        status: 'pending',
      }
      return updateCheck({ ...state, seq }, action.checkId, (c) => ({ ...c, lines: [...c.lines, line] }))
    }

    case 'setNote':
      return updateLine(state, action.checkId, action.lineId, (l) => ({ ...l, note: action.note }))

    case 'setCourse':
      return updateLine(state, action.checkId, action.lineId, (l) =>
        l.status === 'pending' ? { ...l, course: action.course } : l,
      )

    case 'setSeat':
      return updateLine(state, action.checkId, action.lineId, (l) => ({ ...l, seat: action.seat }))

    case 'voidLine':
      return updateLine(state, action.checkId, action.lineId, (l) => ({
        ...l,
        status: 'voided',
        voidReason: action.reason,
      }))

    case 'fireCourse': {
      const check = state.checks[action.checkId]
      if (!check) return state
      const table = state.tables.find((t) => t.id === check.tableId)
      const toFire = check.lines.filter((l) => l.status === 'pending' && l.course === action.course)
      if (!table || toFire.length === 0) return state
      const seq = state.seq + 1
      const ticketId = `k-${seq}`
      const ticket: KitchenTicket = {
        id: ticketId,
        tableNumber: table.number,
        course: action.course,
        firedAt: action.firedAt,
        bumped: false,
        lines: toFire.map((l) => ({
          lineId: l.id,
          seat: l.seat,
          name: l.name,
          modifiers: l.modifiers.map((m) => m.optionName),
          note: l.note,
        })),
      }
      const fired = new Set(toFire.map((l) => l.id))
      return updateCheck({ ...state, seq, tickets: [...state.tickets, ticket] }, action.checkId, (c) => ({
        ...c,
        lines: c.lines.map((l) => (fired.has(l.id) ? { ...l, status: 'fired', ticketId } : l)),
      }))
    }

    case 'setDiscount':
      return updateCheck(state, action.checkId, (c) => ({ ...c, discount: action.discount }))

    case 'setSplitMode':
      return updateCheck(state, action.checkId, (c) => ({ ...c, splitMode: action.mode }))

    case 'setEvenCount':
      return updateCheck(state, action.checkId, (c) => ({ ...c, evenSplitCount: Math.max(1, action.count) }))

    case 'setItemCount':
      return updateCheck(state, action.checkId, (c) => {
        const count = Math.max(1, action.count)
        const itemAssignments = Object.fromEntries(
          Object.entries(c.itemAssignments).map(([id, idx]) => [id, Math.min(idx, count - 1)]),
        )
        return { ...c, itemSplitCount: count, itemAssignments }
      })

    case 'assignItem':
      return updateCheck(state, action.checkId, (c) => ({
        ...c,
        itemAssignments: { ...c.itemAssignments, [action.lineId]: action.splitIndex },
      }))

    case 'paySplit':
      return updateCheck(state, action.checkId, (c) => ({
        ...c,
        payments: [...c.payments.filter((p) => p.splitId !== action.payment.splitId), action.payment],
      }))

    case 'closeCheck': {
      const check = state.checks[action.checkId]
      if (!check) return state
      return {
        ...state,
        checks: { ...state.checks, [action.checkId]: { ...check, closed: true } },
        tables: state.tables.map((t) => (t.id === check.tableId ? { ...t, checkId: null } : t)),
      }
    }

    case 'bumpTicket':
      return {
        ...state,
        tickets: state.tickets.map((t) => (t.id === action.ticketId ? { ...t, bumped: true } : t)),
      }
  }
}
