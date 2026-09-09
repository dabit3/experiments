import type { ReactNode } from 'react'
import { CLIENT } from '../types'
import type { SignatureImage } from '../types'
import { SignaturePad } from './SignaturePad'

interface PaperProps {
  page: 1 | 2
  documentId: string
  children: ReactNode
  initials: SignatureImage | null
  initialsError?: string
  onInitials: (img: SignatureImage | null, reason: 'stroke' | 'undo' | 'clear' | 'typed') => void
}

export function Paper({ page, documentId, children, initials, initialsError, onInitials }: PaperProps) {
  const key = page === 1 ? 'initialsPage1' : 'initialsPage2'
  return (
    <article className="paper" aria-label={`Contractor Agreement page ${page} of 2`}>
      <header className="paper__head">
        <div>
          <h1 className="paper__title">Contractor Agreement</h1>
          <p className="paper__subtitle">Independent contractor services agreement · {CLIENT.name}</p>
        </div>
        <div className="paper__meta">
          <strong>Document</strong>
          {documentId}
          <br />
          Page {page} of 2
        </div>
      </header>

      {children}

      <footer className="paper__foot">
        <div className="paper__pageno">
          Contractor Agreement · {documentId} · Page {page} of 2
        </div>
        <div className="initials-block" data-field={key}>
          <div className="initials-block__label">
            Contractor initials <span className="req">*</span>
          </div>
          <SignaturePad
            id={key}
            width={240}
            height={90}
            value={initials}
            onChange={onInitials}
            lineWidth={2.2}
            placeholder="Initial here"
            invalid={!!initialsError}
            compact
          />
          {initialsError && <div className="initials-block__error">{initialsError}</div>}
        </div>
      </footer>
    </article>
  )
}

export function Clause({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="clause">
      <h2 className="clause__title">{title}</h2>
      {children}
    </section>
  )
}

export function Fill({ value, placeholder }: { value: string; placeholder: string }) {
  return value ? <span className="fill">{value}</span> : <span className="fill is-empty">{placeholder}</span>
}
