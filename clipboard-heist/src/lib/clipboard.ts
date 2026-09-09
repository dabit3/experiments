export type CopyMethod = 'clipboard-api' | 'execCommand'

export type CopyOutcome = { ok: true; method: CopyMethod } | { ok: false; reason: string }

export type ReadOutcome = { ok: true; text: string } | { ok: false; reason: string }

function execCopyFrom(prepare: (host: HTMLElement) => void): boolean {
  const host = document.createElement('div')
  host.setAttribute('aria-hidden', 'true')
  host.style.position = 'fixed'
  host.style.left = '-9999px'
  host.style.top = '0'
  document.body.appendChild(host)
  const previous = document.activeElement
  let ok = false
  try {
    prepare(host)
    ok = document.execCommand('copy')
  } catch {
    ok = false
  } finally {
    document.body.removeChild(host)
    if (previous instanceof HTMLElement) previous.focus()
  }
  return ok
}

export async function copyText(text: string): Promise<CopyOutcome> {
  if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
    try {
      await navigator.clipboard.writeText(text)
      return { ok: true, method: 'clipboard-api' }
    } catch {
      // fall through to execCommand
    }
  }
  const ok = execCopyFrom((host) => {
    const ta = document.createElement('textarea')
    ta.value = text
    ta.readOnly = true
    host.appendChild(ta)
    ta.select()
    ta.setSelectionRange(0, text.length)
  })
  return ok ? { ok: true, method: 'execCommand' } : { ok: false, reason: 'Browser refused the copy command.' }
}

export async function copyRich(html: string, text: string): Promise<CopyOutcome> {
  if (
    navigator.clipboard &&
    typeof navigator.clipboard.write === 'function' &&
    typeof ClipboardItem !== 'undefined'
  ) {
    try {
      const item = new ClipboardItem({
        'text/html': new Blob([html], { type: 'text/html' }),
        'text/plain': new Blob([text], { type: 'text/plain' }),
      })
      await navigator.clipboard.write([item])
      return { ok: true, method: 'clipboard-api' }
    } catch {
      // fall through to execCommand
    }
  }
  const ok = execCopyFrom((host) => {
    const box = document.createElement('div')
    box.contentEditable = 'true'
    box.innerHTML = html
    host.appendChild(box)
    const range = document.createRange()
    range.selectNodeContents(box)
    const sel = window.getSelection()
    sel?.removeAllRanges()
    sel?.addRange(range)
  })
  return ok ? { ok: true, method: 'execCommand' } : { ok: false, reason: 'Browser refused the copy command.' }
}

export async function copyEntry(text: string, html?: string): Promise<CopyOutcome> {
  return html ? copyRich(html, text) : copyText(text)
}

export async function readText(): Promise<ReadOutcome> {
  if (!navigator.clipboard || typeof navigator.clipboard.readText !== 'function') {
    return { ok: false, reason: 'This browser does not expose navigator.clipboard.readText to pages.' }
  }
  try {
    const text = await navigator.clipboard.readText()
    return { ok: true, text }
  } catch (err) {
    const name = err instanceof DOMException ? err.name : 'Error'
    if (name === 'NotAllowedError') {
      return { ok: false, reason: 'Clipboard read permission was denied for this site.' }
    }
    return { ok: false, reason: `Clipboard read failed (${name}).` }
  }
}

export function selectNodeContents(node: Node): void {
  const range = document.createRange()
  range.selectNodeContents(node)
  const sel = window.getSelection()
  if (!sel) return
  sel.removeAllRanges()
  sel.addRange(range)
}
