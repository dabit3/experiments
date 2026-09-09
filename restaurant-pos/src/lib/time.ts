const timeFmt = new Intl.DateTimeFormat('en-US', { hour: 'numeric', minute: '2-digit' })
const dateFmt = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', year: 'numeric' })

export function fmtTime(iso: string): string {
  return timeFmt.format(new Date(iso))
}

export function fmtDate(iso: string): string {
  return dateFmt.format(new Date(iso))
}

/** Local ISO-ish timestamp without timezone, matching the seed format. */
export function nowIso(): string {
  const d = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}
