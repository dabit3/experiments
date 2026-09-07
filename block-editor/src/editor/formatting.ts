import { closestElement, getSelectionRange, selectRange } from './caret'

export type InlineFormat = 'bold' | 'italic' | 'underline' | 'code' | 'link'

export const FORMAT_SHORTCUTS: Record<string, InlineFormat> = {
  b: 'bold',
  i: 'italic',
  u: 'underline',
  e: 'code',
  k: 'link',
}

/** Applies an inline format to the current selection inside a contentEditable block. */
export function applyFormat(format: InlineFormat, url?: string): void {
  switch (format) {
    case 'bold':
    case 'italic':
    case 'underline':
      document.execCommand(format)
      break
    case 'code':
      toggleInlineCode()
      break
    case 'link':
      if (url) document.execCommand('createLink', false, url)
      else document.execCommand('unlink')
      break
  }
}

export function activeFormats(): Record<InlineFormat, boolean> {
  const range = getSelectionRange()
  return {
    bold: document.queryCommandState('bold'),
    italic: document.queryCommandState('italic'),
    underline: document.queryCommandState('underline'),
    code: !!closestElement(range?.startContainer ?? null, 'code'),
    link: !!closestElement(range?.startContainer ?? null, 'a'),
  }
}

export function selectedLinkUrl(): string {
  const anchor = closestElement(getSelectionRange()?.startContainer ?? null, 'a')
  return anchor?.getAttribute('href') ?? ''
}

/** Expands a collapsed selection to the word under the caret (so Ctrl+K etc. have something to work on). */
export function expandSelectionToWord(): void {
  const sel = window.getSelection()
  if (!sel || !sel.isCollapsed) return
  sel.modify('move', 'backward', 'word')
  sel.modify('extend', 'forward', 'word')
}

export function normalizeUrl(input: string): string {
  const trimmed = input.trim()
  if (!trimmed) return ''
  return /^[a-z][a-z0-9+.-]*:/i.test(trimmed) ? trimmed : `https://${trimmed}`
}

function toggleInlineCode(): void {
  const range = getSelectionRange()
  if (!range || range.collapsed) return

  const existing = closestElement(range.commonAncestorContainer, 'code')
  if (existing) {
    const restored = document.createRange()
    restored.selectNodeContents(existing)
    unwrap(existing)
    selectRange(restored)
    return
  }

  const fragment = range.extractContents()
  fragment.querySelectorAll('code').forEach(unwrap)
  const code = document.createElement('code')
  code.appendChild(fragment)
  range.insertNode(code)

  const selection = document.createRange()
  selection.selectNodeContents(code)
  selectRange(selection)
}

function unwrap(el: Element): void {
  const parent = el.parentNode
  if (!parent) return
  while (el.firstChild) parent.insertBefore(el.firstChild, el)
  parent.removeChild(el)
}
