import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { KeyboardEvent } from 'react'
import { BlockView } from './BlockView'
import { FormatToolbar } from './FormatToolbar'
import { LinkPopover } from './LinkPopover'
import { SlashMenu } from './SlashMenu'
import {
  caretOffset,
  caretOnFirstLine,
  caretOnLastLine,
  closestElement,
  getSelectionRange,
  htmlToText,
  isSelectionCollapsed,
  rangeFromOffsets,
  selectRange,
  selectionRect,
  setCaret,
  splitAtCaret,
} from './caret'
import type { CaretPosition } from './caret'
import {
  FORMAT_SHORTCUTS,
  activeFormats,
  applyFormat,
  expandSelectionToWord,
  normalizeUrl,
  selectedLinkUrl,
} from './formatting'
import type { InlineFormat } from './formatting'
import {
  LIST_TYPES,
  MARKDOWN_SHORTCUTS,
  blockIndex,
  createBlock,
  emptyDoc,
  filterBlockTypes,
  firstChangedBlock,
  insertBlocks,
  isEmptyHtml,
  moveBlock,
  normalizeHtml,
  removeBlock,
  updateBlock,
} from './model'
import type { Block, BlockType, Doc } from './model'
import { loadDoc, saveDoc } from './storage'
import { useBlockDrag } from './useBlockDrag'
import { useHistory } from './useHistory'
import './editor.css'

interface PendingCaret {
  id: string | 'title'
  position: CaretPosition
}

interface SlashState {
  blockId: string
  /** Text offset of the `/` that opened the menu. */
  anchor: number
  query: string
  index: number
  position: { top: number; left: number }
}

interface ToolbarState {
  rect: DOMRect
  active: Record<InlineFormat, boolean>
}

interface LinkState {
  blockId: string
  range: Range
  rect: DOMRect
  url: string
}

const textKey = (blockId: string) => `text:${blockId}`
const SLASH_MENU_HEIGHT = 340

export function Editor() {
  const history = useHistory<Doc>(() => loadDoc() ?? emptyDoc())
  const doc = history.present
  const docRef = useRef(doc)

  const blockEls = useRef(new Map<string, HTMLElement>())
  const titleRef = useRef<HTMLDivElement>(null)
  const listRef = useRef<HTMLDivElement>(null)
  const pendingCaret = useRef<PendingCaret | null>(null)
  const mouseSelecting = useRef(false)

  const [slash, setSlash] = useState<SlashState | null>(null)
  const [toolbar, setToolbar] = useState<ToolbarState | null>(null)
  const [link, setLink] = useState<LinkState | null>(null)
  const [saveState, setSaveState] = useState<'saved' | 'saving'>('saved')

  const slashItems = useMemo(() => (slash ? filterBlockTypes(slash.query) : []), [slash])

  /** Records a new document state; `key` groups consecutive edits into one undo step. */
  const update = (next: Doc, key: string | null = null) => {
    docRef.current = next
    setSaveState('saving')
    history.commit(next, key)
  }

  // ----- persistence -------------------------------------------------------

  useLayoutEffect(() => {
    docRef.current = doc
  }, [doc])

  useEffect(() => {
    saveDoc(doc)
    const timer = window.setTimeout(() => setSaveState('saved'), 400)
    return () => window.clearTimeout(timer)
  }, [doc])

  // ----- caret placement after structural changes ---------------------------

  useLayoutEffect(() => {
    const pending = pendingCaret.current
    if (!pending) return
    pendingCaret.current = null
    const el = pending.id === 'title' ? titleRef.current : blockEls.current.get(pending.id)
    if (!el) return
    el.focus()
    if (el.isContentEditable) setCaret(el, pending.position)
  })

  const focusBlock = (id: string | 'title', position: CaretPosition) => {
    pendingCaret.current = { id, position }
  }

  const register = useCallback((id: string, el: HTMLElement | null) => {
    if (el) blockEls.current.set(id, el)
    else blockEls.current.delete(id)
  }, [])

  // ----- floating toolbar ----------------------------------------------------

  useEffect(() => {
    const refresh = () => {
      const range = getSelectionRange()
      const blockEl = range ? closestElement(range.commonAncestorContainer, '.block-content') : null
      if (
        !range ||
        range.collapsed ||
        !blockEl ||
        blockEl.dataset.blockType === 'code' ||
        mouseSelecting.current
      ) {
        setToolbar(null)
        return
      }
      const rect = selectionRect()
      if (rect) setToolbar({ rect, active: activeFormats() })
    }
    const onMouseDown = (e: MouseEvent) => {
      const target = e.target as HTMLElement
      if (!target.closest('.format-toolbar, .link-popover')) mouseSelecting.current = true
      if (!target.closest('.slash-menu')) setSlash(null)
    }
    const onMouseUp = () => {
      mouseSelecting.current = false
      refresh()
    }
    document.addEventListener('selectionchange', refresh)
    document.addEventListener('mousedown', onMouseDown)
    document.addEventListener('mouseup', onMouseUp)
    window.addEventListener('scroll', refresh, true)
    return () => {
      document.removeEventListener('selectionchange', refresh)
      document.removeEventListener('mousedown', onMouseDown)
      document.removeEventListener('mouseup', onMouseUp)
      window.removeEventListener('scroll', refresh, true)
    }
  }, [])

  // ----- block mutations -----------------------------------------------------

  const syncBlockFromDom = (id: string, el: HTMLElement, key: string | null) => {
    const html = normalizeHtml(el.innerHTML)
    const block = docRef.current.blocks.find((b) => b.id === id)
    if (!block || block.html === html) return
    update(updateBlock(docRef.current, id, { html }), key)
  }

  const convertBlock = (block: Block, type: BlockType, html: string, position: CaretPosition = 'end') => {
    const patch: Partial<Block> = { type, html, checked: type === 'todo' ? false : undefined }
    update(updateBlock(docRef.current, block.id, patch), textKey(block.id))
    history.seal()
    focusBlock(block.id, position)
  }

  const insertDividerAfter = (current: Doc, block: Block, keepCurrent: boolean): Doc => {
    const divider = createBlock('divider')
    const paragraph = createBlock('paragraph')
    const index = blockIndex(current, block.id)
    focusBlock(paragraph.id, 'start')
    return keepCurrent
      ? insertBlocks(current, index + 1, divider, paragraph)
      : insertBlocks(removeBlock(current, block.id), index, divider, paragraph)
  }

  const splitBlock = (block: Block, el: HTMLElement) => {
    if (LIST_TYPES.has(block.type) && isEmptyHtml(el.innerHTML)) {
      convertBlock(block, 'paragraph', '')
      return
    }
    const { before, after } = splitAtCaret(el)
    const nextType = LIST_TYPES.has(block.type) ? block.type : 'paragraph'
    const next = createBlock(nextType, after)
    let current = updateBlock(docRef.current, block.id, { html: normalizeHtml(before) })
    current = insertBlocks(current, blockIndex(current, block.id) + 1, next)
    update(current)
    focusBlock(next.id, 'start')
  }

  const backspaceAtStart = (block: Block, el: HTMLElement) => {
    const current = docRef.current
    if (block.type !== 'paragraph') {
      convertBlock(block, 'paragraph', normalizeHtml(el.innerHTML), 'start')
      return
    }
    const index = blockIndex(current, block.id)
    if (index === 0) return
    const previous = current.blocks[index - 1]
    const html = normalizeHtml(el.innerHTML)

    if (previous.type === 'divider') {
      update(removeBlock(current, previous.id))
      focusBlock(block.id, 'start')
      return
    }
    if (previous.type === 'code' && html !== '') return

    const joinOffset = htmlToText(previous.html).length
    const merged = updateBlock(removeBlock(current, block.id), previous.id, { html: previous.html + html })
    update(merged)
    focusBlock(previous.id, joinOffset)
  }

  const removeDivider = (block: Block) => {
    const current = docRef.current
    const index = blockIndex(current, block.id)
    const neighbour = current.blocks[index - 1] ?? current.blocks[index + 1]
    let next = removeBlock(current, block.id)
    if (next.blocks.length === 0) {
      const paragraph = createBlock()
      next = insertBlocks(next, 0, paragraph)
      focusBlock(paragraph.id, 'start')
    } else {
      focusBlock(neighbour.id, 'end')
    }
    update(next)
  }

  const focusSibling = (block: Block, direction: -1 | 1, position: CaretPosition) => {
    const current = docRef.current
    const index = blockIndex(current, block.id) + direction
    if (index < 0) {
      focusBlock('title', 'end')
    } else if (index >= current.blocks.length) {
      if (block.type !== 'code') return
      const paragraph = createBlock()
      update(insertBlocks(current, current.blocks.length, paragraph))
      focusBlock(paragraph.id, 'start')
    } else {
      focusBlock(current.blocks[index].id, position)
    }
    applyPendingCaret()
  }

  /** Applies the pending caret immediately when its target already exists (no re-render needed). */
  const applyPendingCaret = () => {
    const pending = pendingCaret.current
    if (!pending) return
    const el = pending.id === 'title' ? titleRef.current : blockEls.current.get(pending.id)
    if (!el) return
    pendingCaret.current = null
    el.focus()
    if (el.isContentEditable) setCaret(el, pending.position)
  }

  const toggleChecked = (block: Block) => {
    update(updateBlock(docRef.current, block.id, { checked: !block.checked }))
  }

  const moveBlockTo = (from: number, to: number) => {
    const next = moveBlock(docRef.current, from, to)
    update(next)
    focusBlock(next.blocks[to].id, 'end')
  }

  const drag = useBlockDrag(listRef, moveBlockTo)

  // ----- undo / redo ---------------------------------------------------------

  const restore = (target: Doc | undefined, step: () => void) => {
    if (!target) return
    const changed = firstChangedBlock(docRef.current, target)
    if (changed) focusBlock(changed.id, 'end')
    else if (target.title !== docRef.current.title) focusBlock('title', 'end')
    else if (target.blocks.length !== docRef.current.blocks.length) {
      focusBlock(target.blocks[Math.min(docRef.current.blocks.length, target.blocks.length) - 1].id, 'end')
    }
    docRef.current = target
    setSaveState('saving')
    setSlash(null)
    setLink(null)
    step()
  }
  const undo = () => restore(history.peekUndo(), history.undo)
  const redo = () => restore(history.peekRedo(), history.redo)

  // ----- inline formatting ---------------------------------------------------

  const runFormat = (format: InlineFormat, url?: string) => {
    const range = getSelectionRange()
    const blockEl = range ? closestElement(range.commonAncestorContainer, '.block-content') : null
    if (!blockEl || blockEl.dataset.blockType === 'code') return
    applyFormat(format, url)
    syncBlockFromDom(blockEl.dataset.blockId!, blockEl, null)
  }

  const openLinkPopover = () => {
    expandSelectionToWord()
    const range = getSelectionRange()
    const blockEl = range ? closestElement(range.commonAncestorContainer, '.block-content') : null
    const rect = selectionRect()
    if (!range || range.collapsed || !blockEl || !rect) return
    setToolbar(null)
    setLink({ blockId: blockEl.dataset.blockId!, range: range.cloneRange(), rect, url: selectedLinkUrl() })
  }

  const finishLink = (url: string | null) => {
    if (!link) return
    blockEls.current.get(link.blockId)?.focus()
    selectRange(link.range)
    if (url !== null) runFormat('link', url ? normalizeUrl(url) : undefined)
    setLink(null)
  }

  const handleFormatRequest = (format: InlineFormat) => {
    if (format === 'link') openLinkPopover()
    else runFormat(format)
  }

  // ----- slash menu ----------------------------------------------------------

  const openSlash = (block: Block, el: HTMLElement) => {
    const rect = selectionRect() ?? el.getBoundingClientRect()
    const flip = rect.bottom + SLASH_MENU_HEIGHT > window.innerHeight
    setSlash({
      blockId: block.id,
      anchor: caretOffset(el),
      query: '',
      index: 0,
      position: {
        top: flip ? rect.top - SLASH_MENU_HEIGHT - 8 : rect.bottom + 8,
        left: Math.min(rect.left, window.innerWidth - 340),
      },
    })
  }

  const updateSlashQuery = (state: SlashState, el: HTMLElement) => {
    const text = el.textContent ?? ''
    const caret = caretOffset(el)
    if (text[state.anchor] !== '/' || caret <= state.anchor) {
      setSlash(null)
      return
    }
    const query = text.slice(state.anchor + 1, caret)
    if (filterBlockTypes(query).length === 0) {
      setSlash(null)
      return
    }
    setSlash({ ...state, query, index: 0 })
  }

  const applySlashCommand = (type: BlockType) => {
    if (!slash) return
    const el = blockEls.current.get(slash.blockId)
    const block = docRef.current.blocks.find((b) => b.id === slash.blockId)
    setSlash(null)
    if (!el || !block) return

    // Remove the "/query" text that triggered the menu.
    rangeFromOffsets(el, slash.anchor, slash.anchor + 1 + slash.query.length).deleteContents()
    const html = normalizeHtml(el.innerHTML)
    const key = textKey(block.id)

    if (type === 'divider') {
      const current = updateBlock(docRef.current, block.id, { html })
      update(insertDividerAfter(current, block, !isEmptyHtml(html)), key)
    } else if (isEmptyHtml(html)) {
      update(updateBlock(docRef.current, block.id, { type, html: '', checked: type === 'todo' ? false : undefined }), key)
      focusBlock(block.id, 'start')
    } else {
      const next = createBlock(type)
      const current = updateBlock(docRef.current, block.id, { html })
      update(insertBlocks(current, blockIndex(current, block.id) + 1, next), key)
      focusBlock(next.id, 'start')
    }
    history.seal()
  }

  const handleSlashKey = (e: KeyboardEvent<HTMLElement>): boolean => {
    if (!slash || slashItems.length === 0) return false
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        setSlash({ ...slash, index: (slash.index + 1) % slashItems.length })
        return true
      case 'ArrowUp':
        e.preventDefault()
        setSlash({ ...slash, index: (slash.index - 1 + slashItems.length) % slashItems.length })
        return true
      case 'Enter':
      case 'Tab':
        e.preventDefault()
        applySlashCommand(slashItems[slash.index].type)
        return true
      case 'Escape':
        e.preventDefault()
        setSlash(null)
        return true
      default:
        return false
    }
  }

  // ----- keyboard ------------------------------------------------------------

  const handleBlockInput = (block: Block, el: HTMLElement) => {
    if (slash && slash.blockId === block.id) updateSlashQuery(slash, el)
    syncBlockFromDom(block.id, el, textKey(block.id))
  }

  const handleBlockKeyDown = (block: Block, el: HTMLElement, e: KeyboardEvent<HTMLElement>) => {
    if (handleSlashKey(e)) return
    const mod = e.ctrlKey || e.metaKey

    if (block.type === 'divider') {
      handleDividerKeyDown(block, e)
      return
    }

    if (mod && !e.altKey && !e.shiftKey && block.type !== 'code') {
      const format = FORMAT_SHORTCUTS[e.key.toLowerCase()]
      if (format) {
        e.preventDefault()
        handleFormatRequest(format)
        return
      }
    }
    if (mod) return

    if (block.type === 'code') {
      handleCodeKeyDown(block, el, e)
      return
    }

    switch (e.key) {
      case 'Enter':
        if (e.shiftKey) return
        e.preventDefault()
        splitBlock(block, el)
        return
      case 'Backspace':
        if (isSelectionCollapsed() && caretOffset(el) === 0) {
          e.preventDefault()
          backspaceAtStart(block, el)
        }
        return
      case 'ArrowUp':
        if (!e.shiftKey && caretOnFirstLine(el)) {
          e.preventDefault()
          focusSibling(block, -1, 'end')
        }
        return
      case 'ArrowDown':
        if (!e.shiftKey && caretOnLastLine(el)) {
          e.preventDefault()
          focusSibling(block, 1, 'start')
        }
        return
      case ' ': {
        if (block.type !== 'paragraph') return
        const text = el.textContent ?? ''
        const type = Object.hasOwn(MARKDOWN_SHORTCUTS, text) ? MARKDOWN_SHORTCUTS[text] : undefined
        if (type && caretOffset(el) === text.length) {
          e.preventDefault()
          convertBlock(block, type, '')
        }
        return
      }
      case '`':
        if (block.type === 'paragraph' && el.textContent === '``') {
          e.preventDefault()
          convertBlock(block, 'code', '')
        }
        return
      case '-':
        if (block.type === 'paragraph' && el.textContent === '--') {
          e.preventDefault()
          update(insertDividerAfter(docRef.current, block, false), textKey(block.id))
          history.seal()
        }
        return
      case '/':
        if (isSelectionCollapsed()) openSlash(block, el)
        return
      case 'Escape':
        setToolbar(null)
        return
    }
  }

  const handleCodeKeyDown = (block: Block, el: HTMLElement, e: KeyboardEvent<HTMLElement>) => {
    switch (e.key) {
      case 'Tab':
        e.preventDefault()
        document.execCommand('insertText', false, '  ')
        return
      case 'Backspace':
        if (isEmptyHtml(el.innerHTML)) {
          e.preventDefault()
          convertBlock(block, 'paragraph', '')
        }
        return
      case 'ArrowUp':
        if (!e.shiftKey && caretOnFirstLine(el)) {
          e.preventDefault()
          focusSibling(block, -1, 'end')
        }
        return
      case 'ArrowDown':
        if (!e.shiftKey && caretOnLastLine(el)) {
          e.preventDefault()
          focusSibling(block, 1, 'start')
        }
        return
    }
  }

  const handleDividerKeyDown = (block: Block, e: KeyboardEvent<HTMLElement>) => {
    switch (e.key) {
      case 'Backspace':
      case 'Delete':
        e.preventDefault()
        removeDivider(block)
        return
      case 'Enter': {
        e.preventDefault()
        const paragraph = createBlock()
        const current = docRef.current
        update(insertBlocks(current, blockIndex(current, block.id) + 1, paragraph))
        focusBlock(paragraph.id, 'start')
        return
      }
      case 'ArrowUp':
        e.preventDefault()
        focusSibling(block, -1, 'end')
        return
      case 'ArrowDown':
        e.preventDefault()
        focusSibling(block, 1, 'start')
        return
    }
  }

  const handleTitleKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key === 'Enter' || e.key === 'ArrowDown') {
      e.preventDefault()
      const first = docRef.current.blocks[0]
      focusBlock(first.id, 'start')
      applyPendingCaret()
    }
  }

  const handleTitleInput = (el: HTMLElement) => {
    update({ ...docRef.current, title: el.textContent ?? '' }, 'title')
  }

  const handleRootKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    const mod = e.ctrlKey || e.metaKey
    if (!mod || (e.target as HTMLElement).closest('.link-popover')) return
    const key = e.key.toLowerCase()
    if (key === 'z') {
      e.preventDefault()
      if (e.shiftKey) redo()
      else undo()
    } else if (key === 'y') {
      e.preventDefault()
      redo()
    }
  }

  const newPage = () => {
    const fresh = emptyDoc()
    update(fresh)
    focusBlock('title', 'start')
  }

  useLayoutEffect(() => {
    const el = titleRef.current
    if (el && el.textContent !== doc.title) el.textContent = doc.title
  }, [doc.title])

  const numbers = useMemo(
    () =>
      doc.blocks.reduce<number[]>((acc, block) => {
        const previous = acc[acc.length - 1] ?? 0
        acc.push(block.type === 'numbered' ? previous + 1 : 0)
        return acc
      }, []),
    [doc.blocks],
  )

  return (
    <div className="editor-root" onKeyDown={handleRootKeyDown}>
      <header className="app-header">
        <div className="app-brand">
          <span className="app-logo" aria-hidden="true">
            ▤
          </span>
          <span className="app-name">Blocks</span>
          <span className="app-crumb">/</span>
          <span className="app-page-title">{doc.title || 'Untitled'}</span>
        </div>
        <div className="app-actions">
          <span className={`save-state is-${saveState}`} data-testid="save-state">
            {saveState === 'saving' ? 'Saving…' : 'Saved'}
          </span>
          <button
            type="button"
            className="icon-button"
            title="Undo (Ctrl+Z)"
            aria-label="Undo"
            disabled={!history.canUndo}
            onMouseDown={(e) => e.preventDefault()}
            onClick={undo}
          >
            ↶
          </button>
          <button
            type="button"
            className="icon-button"
            title="Redo (Ctrl+Shift+Z)"
            aria-label="Redo"
            disabled={!history.canRedo}
            onMouseDown={(e) => e.preventDefault()}
            onClick={redo}
          >
            ↷
          </button>
          <button type="button" className="text-button" onClick={newPage}>
            New page
          </button>
        </div>
      </header>

      <main className="page">
        <div
          ref={titleRef}
          className="page-title"
          contentEditable="plaintext-only"
          spellCheck={false}
          data-placeholder="Untitled"
          data-empty={doc.title === ''}
          aria-label="Page title"
          onInput={(e) => handleTitleInput(e.currentTarget)}
          onKeyDown={handleTitleKeyDown}
        />

        <div ref={listRef} className="block-list">
          {doc.blocks.map((block, index) => (
            <BlockView
              key={block.id}
              block={block}
              number={numbers[index]}
              isDragging={drag.drag?.from === index}
              handleProps={drag.handleProps(index)}
              onInput={handleBlockInput}
              onKeyDown={handleBlockKeyDown}
              onToggleChecked={toggleChecked}
              register={register}
            />
          ))}
          {drag.drag?.indicatorTop != null && (
            <div className="drop-indicator" style={{ top: drag.drag.indicatorTop }} />
          )}
        </div>

        <footer className="page-hints">
          Type <kbd>/</kbd> for commands · <kbd>Ctrl</kbd>+<kbd>B</kbd>/<kbd>I</kbd>/<kbd>U</kbd>/<kbd>E</kbd> format ·{' '}
          <kbd>Ctrl</kbd>+<kbd>K</kbd> link · <kbd>Ctrl</kbd>+<kbd>Z</kbd> undo · drag <span className="hint-handle">⠿</span> to
          reorder
        </footer>
      </main>

      {slash && slashItems.length > 0 && (
        <SlashMenu
          items={slashItems}
          selectedIndex={slash.index}
          position={slash.position}
          onHover={(index) => setSlash({ ...slash, index })}
          onSelect={applySlashCommand}
        />
      )}
      {toolbar && !link && <FormatToolbar rect={toolbar.rect} active={toolbar.active} onFormat={handleFormatRequest} />}
      {link && (
        <LinkPopover
          rect={link.rect}
          initialUrl={link.url}
          onSubmit={(url) => finishLink(url)}
          onRemove={() => finishLink('')}
          onCancel={() => finishLink(null)}
        />
      )}
    </div>
  )
}
