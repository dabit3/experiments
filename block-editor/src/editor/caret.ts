export type CaretPosition = 'start' | 'end' | number

export function getSelectionRange(): Range | null {
  const sel = window.getSelection()
  return sel && sel.rangeCount > 0 ? sel.getRangeAt(0) : null
}

export function isSelectionCollapsed(): boolean {
  return window.getSelection()?.isCollapsed ?? true
}

/** Number of characters between the start of `el` and the selection focus. */
export function caretOffset(el: HTMLElement): number {
  const sel = window.getSelection()
  if (!sel || !sel.focusNode || !el.contains(sel.focusNode)) return 0
  const range = document.createRange()
  range.selectNodeContents(el)
  range.setEnd(sel.focusNode, sel.focusOffset)
  return range.toString().length
}

/** Builds a range covering the characters `[start, end)` of `el`'s text. */
export function rangeFromOffsets(el: HTMLElement, start: number, end: number): Range {
  const range = document.createRange()
  const startPoint = pointAtOffset(el, start)
  const endPoint = pointAtOffset(el, end)
  range.setStart(startPoint.node, startPoint.offset)
  range.setEnd(endPoint.node, endPoint.offset)
  return range
}

function pointAtOffset(el: HTMLElement, offset: number): { node: Node; offset: number } {
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT)
  let remaining = offset
  let node = walker.nextNode() as Text | null
  while (node) {
    if (remaining <= node.length) return { node, offset: remaining }
    remaining -= node.length
    node = walker.nextNode() as Text | null
  }
  return { node: el, offset: el.childNodes.length }
}

export function setCaret(el: HTMLElement, position: CaretPosition): void {
  const range = document.createRange()
  if (position === 'end') {
    range.selectNodeContents(el)
    range.collapse(false)
  } else {
    const point = pointAtOffset(el, position === 'start' ? 0 : position)
    range.setStart(point.node, point.offset)
    range.collapse(true)
  }
  const sel = window.getSelection()
  if (!sel) return
  sel.removeAllRanges()
  sel.addRange(range)
}

export function selectRange(range: Range): void {
  const sel = window.getSelection()
  if (!sel) return
  sel.removeAllRanges()
  sel.addRange(range)
}

/** Viewport rectangle of the current selection, or null when the browser can't measure it (e.g. empty block). */
export function selectionRect(): DOMRect | null {
  const range = getSelectionRange()
  if (!range) return null
  const rects = range.getClientRects()
  if (rects.length > 0) return range.collapsed ? rects[0] : range.getBoundingClientRect()
  const rect = range.getBoundingClientRect()
  return rect.height > 0 ? rect : null
}

export function caretOnFirstLine(el: HTMLElement): boolean {
  const rect = selectionRect()
  if (!rect) return true
  const box = el.getBoundingClientRect()
  const paddingTop = parseFloat(getComputedStyle(el).paddingTop) || 0
  return rect.top - (box.top + paddingTop) < rect.height / 2
}

export function caretOnLastLine(el: HTMLElement): boolean {
  const rect = selectionRect()
  if (!rect) return true
  const box = el.getBoundingClientRect()
  const paddingBottom = parseFloat(getComputedStyle(el).paddingBottom) || 0
  return box.bottom - paddingBottom - rect.bottom < rect.height / 2
}

/**
 * Splits the content of `el` at the caret (deleting any selection first).
 * Mutates `el` so that it keeps the "before" part and returns both halves as HTML.
 */
export function splitAtCaret(el: HTMLElement): { before: string; after: string } {
  const range = getSelectionRange()
  if (!range) return { before: el.innerHTML, after: '' }
  if (!range.collapsed) range.deleteContents()
  const tail = range.cloneRange()
  tail.setEnd(el, el.childNodes.length)
  const fragment = tail.extractContents()
  const container = document.createElement('div')
  container.appendChild(fragment)
  return { before: stripEmptyTags(el.innerHTML), after: stripEmptyTags(container.innerHTML) }
}

const EMPTY_TAG = /<(b|i|u|s|em|strong|code|a|span)(\s[^>]*)?><\/\1>/g

/** Removes empty inline wrappers such as `<b></b>` left behind by range splitting. */
export function stripEmptyTags(html: string): string {
  let previous = ''
  let current = html
  while (current !== previous) {
    previous = current
    current = current.replace(EMPTY_TAG, '')
  }
  return current
}

export function htmlToText(html: string): string {
  const container = document.createElement('div')
  container.innerHTML = html
  return container.textContent ?? ''
}

export function closestElement(node: Node | null, selector: string): HTMLElement | null {
  if (!node) return null
  const el = node instanceof Element ? node : node.parentElement
  return el?.closest<HTMLElement>(selector) ?? null
}
