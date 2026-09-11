import type { AppState, Check, ChosenModifier, KitchenTicket, OrderLine, Table } from '../types'
import { MENU_BY_ID } from './menu'

/** Logical floor-plan size; the floor scales to fit the viewport. */
export const FLOOR_W = 1000
export const FLOOR_H = 620

export const SEED_TABLES: Table[] = [
  { id: 't1', number: 1, capacity: 2, shape: 'round', x: 40, y: 40, w: 110, h: 110, checkId: null },
  { id: 't2', number: 2, capacity: 2, shape: 'round', x: 200, y: 40, w: 110, h: 110, checkId: 'c-t2' },
  { id: 't3', number: 3, capacity: 4, shape: 'square', x: 360, y: 30, w: 130, h: 130, checkId: null },
  { id: 't4', number: 4, capacity: 6, shape: 'rect', x: 550, y: 35, w: 210, h: 120, checkId: null },
  { id: 't5', number: 5, capacity: 4, shape: 'square', x: 820, y: 30, w: 130, h: 130, checkId: null },
  { id: 't6', number: 6, capacity: 4, shape: 'round', x: 40, y: 240, w: 130, h: 130, checkId: null },
  { id: 't7', number: 7, capacity: 6, shape: 'rect', x: 230, y: 245, w: 210, h: 120, checkId: 'c-t7' },
  { id: 't8', number: 8, capacity: 4, shape: 'square', x: 500, y: 240, w: 130, h: 130, checkId: null },
  { id: 't9', number: 9, capacity: 2, shape: 'round', x: 690, y: 250, w: 110, h: 110, checkId: null },
  { id: 't10', number: 10, capacity: 8, shape: 'rect', x: 840, y: 220, w: 120, h: 230, checkId: 'c-t10' },
  { id: 't11', number: 11, capacity: 4, shape: 'square', x: 40, y: 450, w: 130, h: 130, checkId: null },
  { id: 't12', number: 12, capacity: 8, shape: 'rect', x: 260, y: 460, w: 280, h: 120, checkId: null },
]

function mods(itemId: string, picks: Array<[groupId: string, optionId: string]>): ChosenModifier[] {
  const item = MENU_BY_ID[itemId]
  return picks.map(([groupId, optionId]) => {
    const group = item.modifierGroups.find((g) => g.id === groupId)!
    const option = group.options.find((o) => o.id === optionId)!
    return { groupId, groupName: group.name, optionId, optionName: option.name, delta: option.delta }
  })
}

function line(
  id: string,
  seat: number,
  itemId: string,
  opts: Partial<Pick<OrderLine, 'modifiers' | 'note' | 'course' | 'status' | 'ticketId'>> = {},
): OrderLine {
  const item = MENU_BY_ID[itemId]
  return {
    id,
    seat,
    menuItemId: itemId,
    name: item.name,
    basePrice: item.price,
    modifiers: opts.modifiers ?? [],
    note: opts.note ?? '',
    course: opts.course ?? item.defaultCourse,
    status: opts.status ?? 'pending',
    ticketId: opts.ticketId,
  }
}

const T2_LINES: OrderLine[] = [
  line('s-1', 1, 'old-fashioned', { status: 'fired', ticketId: 'k-1' }),
  line('s-2', 2, 'house-red', { modifiers: mods('house-red', [['pour', 'glass']]), status: 'fired', ticketId: 'k-1' }),
  line('s-3', 1, 'burrata', { status: 'fired', ticketId: 'k-1' }),
  line('s-4', 1, 'filet', { modifiers: mods('filet', [['temp', 'mr'], ['side', 'mash']]) }),
  line('s-5', 2, 'salmon', { modifiers: mods('salmon', [['salmon-side', 'greens']]) }),
]

const T7_LINES: OrderLine[] = [
  line('s-6', 1, 'ipa', { status: 'fired', ticketId: 'k-2' }),
  line('s-7', 2, 'ipa', { status: 'fired', ticketId: 'k-2' }),
  line('s-8', 3, 'sparkling', { status: 'fired', ticketId: 'k-2' }),
  line('s-9', 4, 'wings', { modifiers: mods('wings', [['sauce', 'buffalo']]), status: 'fired', ticketId: 'k-2' }),
  line('s-10', 5, 'calamari', { status: 'fired', ticketId: 'k-2' }),
  line('s-11', 1, 'burger', {
    modifiers: mods('burger', [['temp', 'med'], ['side', 'fries'], ['burger-addons', 'bacon']]),
    status: 'fired',
    ticketId: 'k-3',
  }),
  line('s-12', 2, 'chicken', { modifiers: mods('chicken', [['side', 'salad']]), status: 'fired', ticketId: 'k-3' }),
  line('s-13', 3, 'risotto', {
    modifiers: mods('risotto', [['allergy', 'gluten']]),
    note: 'Extra parmesan on the side',
    status: 'fired',
    ticketId: 'k-3',
  }),
  line('s-14', 4, 'pappardelle', { status: 'fired', ticketId: 'k-3' }),
  line('s-15', 5, 'ribeye', {
    modifiers: mods('ribeye', [['temp', 'rare'], ['side', 'asparagus']]),
    status: 'fired',
    ticketId: 'k-3',
  }),
]

const T10_LINES: OrderLine[] = [
  line('s-16', 1, 'house-red', { modifiers: mods('house-red', [['pour', 'bottle']]), status: 'fired', ticketId: 'k-4' }),
  line('s-17', 3, 'sparkling', { status: 'fired', ticketId: 'k-4' }),
  line('s-18', 5, 'old-fashioned', { status: 'fired', ticketId: 'k-4' }),
  line('s-19', 6, 'old-fashioned', { status: 'fired', ticketId: 'k-4' }),
  line('s-20', 2, 'caesar', { modifiers: mods('caesar', [['salad-protein', 'chicken']]) }),
  line('s-21', 4, 'onion-soup', {}),
  line('s-22', 7, 'burrata', { modifiers: mods('burrata', [['allergy', 'nut']]) }),
  line('s-23', 8, 'wings', { modifiers: mods('wings', [['sauce', 'gochujang']]) }),
]

function check(id: string, tableId: string, partySize: number, openedAt: string, lines: OrderLine[]): Check {
  return {
    id,
    tableId,
    partySize,
    openedAt,
    lines,
    discount: null,
    splitMode: 'none',
    itemSplitCount: 2,
    evenSplitCount: partySize,
    itemAssignments: {},
    payments: [],
    closed: false,
  }
}

function ticket(id: string, tableNumber: number, course: 1 | 2 | 3, firedAt: string, lines: OrderLine[]): KitchenTicket {
  return {
    id,
    tableNumber,
    course,
    firedAt,
    bumped: false,
    lines: lines
      .filter((l) => l.ticketId === id)
      .map((l) => ({
        lineId: l.id,
        seat: l.seat,
        name: l.name,
        modifiers: l.modifiers.map((m) => m.optionName),
        note: l.note,
      })),
  }
}

export function createSeedState(): AppState {
  return {
    tables: SEED_TABLES.map((t) => ({ ...t })),
    checks: {
      'c-t2': check('c-t2', 't2', 2, '2026-09-09T18:12:00', T2_LINES),
      'c-t7': check('c-t7', 't7', 5, '2026-09-09T17:48:00', T7_LINES),
      'c-t10': check('c-t10', 't10', 8, '2026-09-09T18:31:00', T10_LINES),
    },
    tickets: [
      ticket('k-1', 2, 1, '2026-09-09T18:15:00', T2_LINES),
      ticket('k-2', 7, 1, '2026-09-09T17:52:00', T7_LINES),
      ticket('k-3', 7, 2, '2026-09-09T18:20:00', T7_LINES),
      ticket('k-4', 10, 1, '2026-09-09T18:34:00', T10_LINES),
    ],
    editLayout: false,
    seq: 100,
  }
}
