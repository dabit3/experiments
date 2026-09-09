import { useRef, useState, type ClipboardEvent } from 'react'
import { SNIPPET_HTML, SNIPPET_TEXT } from '../data'
import type { ClipboardApi } from '../types'
import CopyButton from './CopyButton'
import './StageDeadDrop.css'

interface Props {
  api: ClipboardApi
  completed: boolean
  onComplete: () => void
}

interface Verdict {
  kind: 'rejected' | 'accepted' | 'mismatch'
  tags: string[]
  types: string[]
}

function formattingTags(html: string): string[] {
  const doc = new DOMParser().parseFromString(html, 'text/html')
  const names = new Set<string>()
  doc.body.querySelectorAll('*').forEach((el) => {
    const tag = el.tagName.toLowerCase()
    if (tag === 'meta' || tag === 'html' || tag === 'head' || tag === 'body') return
    if (tag === 'span' && !el.getAttribute('style')) return
    names.add(tag === 'span' ? 'styled span' : tag)
  })
  return Array.from(names)
}

function normalize(text: string): string {
  return text.replace(/\s+/g, ' ').trim()
}

export default function StageDeadDrop({ api, completed, onComplete }: Props) {
  const editorRef = useRef<HTMLDivElement>(null)
  const [verdict, setVerdict] = useState<Verdict | null>(
    completed ? { kind: 'accepted', tags: [], types: ['text/plain'] } : null,
  )
  const [attempts, setAttempts] = useState(0)

  function handlePaste(e: ClipboardEvent<HTMLDivElement>) {
    e.preventDefault()
    if (completed) return
    const types = Array.from(e.clipboardData.types)
    const html = e.clipboardData.getData('text/html')
    const text = e.clipboardData.getData('text/plain')
    setAttempts((n) => n + 1)

    if (html.trim().length > 0) {
      const tags = formattingTags(html)
      setVerdict({ kind: 'rejected', tags, types })
      api.notePaste(false)
      if (editorRef.current) editorRef.current.textContent = ''
      return
    }

    if (editorRef.current) editorRef.current.textContent = text
    if (normalize(text) === normalize(SNIPPET_TEXT)) {
      setVerdict({ kind: 'accepted', tags: [], types })
      api.notePaste(true)
      onComplete()
    } else {
      setVerdict({ kind: 'mismatch', tags: [], types })
      api.notePaste(false)
    }
  }

  return (
    <div className="stage stage-deaddrop">
      <div className="stage__grid">
        <section className="panel">
          <header className="panel__head">
            <h3>Message from the handler</h3>
            <span className="pill pill--amber">RICH TEXT</span>
          </header>
          <div className="snippet-card">
            <div className="snippet" dangerouslySetInnerHTML={{ __html: SNIPPET_HTML }} />
            <div className="snippet-card__meta">
              <span>Carries bold, italic, underline and colour — the drop scanner rejects all of it.</span>
            </div>
          </div>
          <div className="snippet-actions">
            <CopyButton
              label="Copy styled message"
              onCopy={() => api.recordCopy('Handler message (rich text)', SNIPPET_TEXT, SNIPPET_HTML)}
            />
            <span className="hint">…or select it with the mouse and press Ctrl+C.</span>
          </div>
        </section>

        <section className="panel">
          <header className="panel__head">
            <h3>Dead-drop scanner</h3>
            <span className={`pill ${verdict?.kind === 'accepted' ? 'pill--accent' : verdict?.kind === 'rejected' ? 'pill--danger' : ''}`}>
              {verdict?.kind === 'accepted' ? 'ACCEPTED' : verdict?.kind === 'rejected' ? 'REJECTED' : 'PLAIN TEXT ONLY'}
            </span>
          </header>
          <div
            ref={editorRef}
            className={`rich-editor ${verdict ? `rich-editor--${verdict.kind}` : ''}`}
            contentEditable={!completed}
            suppressContentEditableWarning
            role="textbox"
            aria-multiline="true"
            aria-label="Dead-drop scanner. Paste as plain text with Ctrl+Shift+V."
            data-placeholder="Paste the message here as plain text: Ctrl+Shift+V"
            spellCheck={false}
            onPaste={handlePaste}
          >
            {completed ? SNIPPET_TEXT : null}
          </div>

          <div className="scanner-legend">
            <div className={`scanner-legend__item ${verdict?.kind === 'rejected' ? 'is-hot' : ''}`}>
              <span className="scanner-legend__keys">
                <kbd>Ctrl</kbd>+<kbd>V</kbd>
              </span>
              <span>pastes with formatting → rejected</span>
            </div>
            <div className={`scanner-legend__item ${verdict?.kind === 'accepted' ? 'is-ok' : ''}`}>
              <span className="scanner-legend__keys">
                <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>
              </span>
              <span>pastes as plain text → accepted</span>
            </div>
          </div>

          {verdict && (
            <div className={`status status--${verdict.kind === 'accepted' ? 'ok' : 'error'}`} role="status">
              {verdict.kind === 'rejected' && (
                <>
                  <strong>REJECTED</strong> — clipboard carried <code>{verdict.types.join(', ')}</code>; formatting
                  detected: {verdict.tags.length ? verdict.tags.map((t) => <code key={t}>&lt;{t}&gt;</code>) : 'styled markup'}. Buffer
                  wiped. Paste as plain text instead.
                </>
              )}
              {verdict.kind === 'accepted' && (
                <>
                  <strong>ACCEPTED</strong> — clipboard carried <code>{verdict.types.join(', ') || 'text/plain'}</code>{' '}
                  only, zero formatting tags. Message delivered{attempts > 1 ? ` after ${attempts} attempts` : ''}.
                </>
              )}
              {verdict.kind === 'mismatch' && (
                <>
                  <strong>PLAIN TEXT OK</strong>, but the message does not match the handler's. Copy the whole message
                  and try again.
                </>
              )}
            </div>
          )}
        </section>
      </div>
    </div>
  )
}
