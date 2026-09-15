import { useState } from 'react'
import type { FormEvent } from 'react'

interface Props {
  rect: DOMRect
  initialUrl: string
  onSubmit: (url: string) => void
  onRemove: () => void
  onCancel: () => void
}

export function LinkPopover({ rect, initialUrl, onSubmit, onRemove, onCancel }: Props) {
  const [url, setUrl] = useState(initialUrl)
  const top = rect.bottom + 8
  const left = Math.min(Math.max(8, rect.left), window.innerWidth - 340)

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (url.trim()) onSubmit(url)
    else onCancel()
  }

  return (
    <form className="link-popover" style={{ top, left }} onSubmit={submit} data-testid="link-popover">
      <input
        autoFocus
        type="text"
        value={url}
        placeholder="Paste a link…"
        aria-label="Link URL"
        onChange={(e) => setUrl(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Escape') {
            e.preventDefault()
            onCancel()
          }
        }}
      />
      <button type="submit" className="link-apply">
        Apply
      </button>
      {initialUrl && (
        <button type="button" className="link-remove" onClick={onRemove}>
          Remove
        </button>
      )}
    </form>
  )
}
