export type Category = 'Starters' | 'Mains' | 'Sides' | 'Drinks' | 'Desserts'

export const CATEGORIES: Category[] = ['Starters', 'Mains', 'Sides', 'Drinks', 'Desserts']

export type Course = 1 | 2 | 3

export interface ModifierOption {
  id: string
  name: string
  /** Price delta in cents (may be 0 or negative). */
  delta: number
}

export interface ModifierGroup {
  id: string
  name: string
  required: boolean
  /** Minimum selections (only meaningful when required). */
  min: number
  /** Maximum selections; 1 means single choice. */
  max: number
  options: ModifierOption[]
}

export interface MenuItem {
  id: string
  name: string
  description: string
  /** Base price in cents. */
  price: number
  category: Category
  defaultCourse: Course
  modifierGroups: ModifierGroup[]
}

export interface ChosenModifier {
  groupId: string
  groupName: string
  optionId: string
  optionName: string
  delta: number
}

export type LineStatus = 'pending' | 'fired' | 'voided'

export interface OrderLine {
  id: string
  /** 1-based seat number. */
  seat: number
  menuItemId: string
  name: string
  /** Base price in cents. */
  basePrice: number
  modifiers: ChosenModifier[]
  note: string
  course: Course
  status: LineStatus
  voidReason?: string
  /** Ticket the line was fired on, if any. */
  ticketId?: string
}

export type DiscountKind = 'percent' | 'amount'

export interface Discount {
  kind: DiscountKind
  /** Percent (0-100) or cents depending on kind. */
  value: number
  label: string
}

export type SplitMode = 'none' | 'seat' | 'even' | 'item'

export type PaymentMethod = 'card' | 'cash'

export interface Payment {
  /** Which split this payment settles (see Split.id). */
  splitId: string
  method: PaymentMethod
  /** Additional tip in cents (on top of any auto-gratuity). */
  tip: number
  /** Amount charged in cents including tip. */
  amount: number
  paidAt: string
}

export interface Check {
  id: string
  tableId: string
  partySize: number
  openedAt: string
  lines: OrderLine[]
  discount: Discount | null
  splitMode: SplitMode
  /** For split-by-item: number of splits. */
  itemSplitCount: number
  /** For split-evenly: number of ways. */
  evenSplitCount: number
  /** For split-by-item: lineId -> split index (0-based). */
  itemAssignments: Record<string, number>
  payments: Payment[]
  closed: boolean
}

export type TableShape = 'round' | 'square' | 'rect'

export interface Table {
  id: string
  number: number
  capacity: number
  shape: TableShape
  x: number
  y: number
  w: number
  h: number
  checkId: string | null
}

export interface TicketLine {
  lineId: string
  seat: number
  name: string
  modifiers: string[]
  note: string
}

export interface KitchenTicket {
  id: string
  tableNumber: number
  course: Course
  firedAt: string
  lines: TicketLine[]
  bumped: boolean
}

export interface AppState {
  tables: Table[]
  checks: Record<string, Check>
  tickets: KitchenTicket[]
  editLayout: boolean
  /** Monotonic counter for deterministic ids. */
  seq: number
}

export const TAX_RATE = 0.08875
export const AUTO_GRATUITY_RATE = 0.18
export const AUTO_GRATUITY_MIN_PARTY = 6
