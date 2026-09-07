import { useLayoutEffect, useRef } from 'react'
import type { ClipboardEvent, KeyboardEvent, PointerEvent } from 'react'
import { BLOCK_META, isEmptyHtml } from './model'
import type { Block } from './model'

export interface BlockHandlers {
  onInput: (block: Block, el: HTMLElement) => void
  onKeyDown: (block: Block, el: HTMLElement, e: KeyboardEvent<HTMLElement>) => void
  onToggleChecked: (block: Block) => void
  register: (id: string, el: HTMLElement | null) => void
}

interface Props extends BlockHandlers {
  block: Block
  /** 1-based position within a run of numbered blocks. */
  number: number
  isDragging: boolean
  handleProps: { onPointerDown: (e: PointerEvent<HTMLElement>) => void }
}

export function BlockView({ block, number, isDragging, handleProps, onInput, onKeyDown, onToggleChecked, register }: Props) {
  const contentRef = useRef<HTMLDivElement>(null)
  const meta = BLOCK_META[block.type]
  const isCode = block.type === 'code'

  // The editable node is uncontrolled while typing; only push state into the DOM
  // when they diverge (initial mount, undo/redo, block conversion, reload).
  useLayoutEffect(() => {
    const el = contentRef.current
    if (el && el.innerHTML !== block.html) el.innerHTML = block.html
  }, [block.html])

  const handlePaste = (e: ClipboardEvent<HTMLElement>) => {
    e.preventDefault()
    document.execCommand('insertText', false, e.clipboardData.getData('text/plain'))
  }

  const className = [
    'block',
    `block-${block.type}`,
    block.checked ? 'is-checked' : '',
    isDragging ? 'is-dragging' : '',
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div className={className} data-block-row data-block-type={block.type}>
      <div className="block-gutter">
        <button
          type="button"
          className="drag-handle"
          title="Drag to move"
          aria-label="Drag to move"
          tabIndex={-1}
          {...handleProps}
        >
          <svg width="10" height="16" viewBox="0 0 10 16" aria-hidden="true">
            <circle cx="2" cy="2" r="1.5" />
            <circle cx="8" cy="2" r="1.5" />
            <circle cx="2" cy="8" r="1.5" />
            <circle cx="8" cy="8" r="1.5" />
            <circle cx="2" cy="14" r="1.5" />
            <circle cx="8" cy="14" r="1.5" />
          </svg>
        </button>
      </div>

      <div className="block-body">
        {block.type === 'bullet' && <span className="block-marker bullet-marker" aria-hidden="true" />}
        {block.type === 'numbered' && <span className="block-marker number-marker">{number}.</span>}
        {block.type === 'todo' && (
          <input
            type="checkbox"
            className="todo-checkbox"
            aria-label="Toggle to-do"
            checked={!!block.checked}
            onChange={() => onToggleChecked(block)}
          />
        )}

        {block.type === 'divider' ? (
          <div
            className="block-divider"
            role="separator"
            tabIndex={0}
            data-block-id={block.id}
            ref={(el) => register(block.id, el)}
            onKeyDown={(e) => onKeyDown(block, e.currentTarget, e)}
          >
            <hr />
          </div>
        ) : (
          <div
            ref={(el) => {
              contentRef.current = el
              register(block.id, el)
            }}
            className="block-content"
            contentEditable={isCode ? 'plaintext-only' : true}
            spellCheck={!isCode}
            role={block.type.startsWith('heading') ? 'heading' : undefined}
            aria-level={block.type === 'heading1' ? 1 : block.type === 'heading2' ? 2 : undefined}
            data-block-id={block.id}
            data-block-type={block.type}
            data-placeholder={meta.placeholder}
            data-empty={isEmptyHtml(block.html)}
            onInput={(e) => onInput(block, e.currentTarget)}
            onKeyDown={(e) => onKeyDown(block, e.currentTarget, e)}
            onPaste={handlePaste}
          />
        )}
      </div>
    </div>
  )
}
