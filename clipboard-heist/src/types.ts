export interface HistoryEntry {
  id: number
  label: string
  text: string
  html?: string
  objective: number
  at: string
}

export interface Stats {
  copies: number
  pastes: number
  rejected: number
}

export interface ClipboardApi {
  /** Copies via the app and records the entry in the clipboard history. */
  recordCopy: (label: string, text: string, html?: string) => Promise<boolean>
  /** Counts a paste that reached one of the app's targets. */
  notePaste: (accepted: boolean) => void
}
