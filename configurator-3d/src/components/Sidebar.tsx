import { useState } from 'react'
import {
  FINISHES,
  FINISH_LABELS,
  MAX_TEXT,
  PALETTE,
  PART_IDS,
  PART_LABELS,
  normalizeHex,
  relativeLuminance,
  sanitizeText,
  type Finish,
  type PartId,
  type SneakerConfig,
} from '../config'

interface Props {
  config: SneakerConfig
  selected: PartId | null
  onSelect: (part: PartId | null) => void
  onUpdatePart: (part: PartId, patch: Partial<{ color: string; finish: Finish }>) => void
  onText: (text: string) => void
  shareUrl: string
  onShare: () => void
  onDownload: () => void
}

export function Sidebar({ config, selected, onSelect, onUpdatePart, onText, shareUrl, onShare, onDownload }: Props) {
  const current = selected ? config.parts[selected] : null
  const [hexDraft, setHexDraft] = useState<{ base: string; value: string } | null>(null)
  const currentColor = current?.color ?? ''
  const hexValue = hexDraft && hexDraft.base === currentColor ? hexDraft.value : currentColor

  const commitHex = () => {
    if (!selected) return
    const hex = normalizeHex(hexValue)
    if (hex) onUpdatePart(selected, { color: hex })
    setHexDraft(null)
  }

  return (
    <aside className="sidebar">
      <section className="panel">
        <header className="panel-head">
          <h2>Parts</h2>
          <span className="panel-sub">Click on the shoe or in the list</span>
        </header>
        <ul className="part-list">
          {PART_IDS.map((id) => {
            const style = config.parts[id]
            const active = selected === id
            return (
              <li key={id}>
                <button
                  type="button"
                  className={`part-row ${active ? 'is-active' : ''}`}
                  aria-pressed={active}
                  onClick={() => onSelect(active ? null : id)}
                  data-testid={`part-${id}`}
                >
                  <span className="part-swatch" style={{ background: style.color }} />
                  <span className="part-name">{PART_LABELS[id]}</span>
                  <span className="part-meta">
                    <code>{style.color.toUpperCase()}</code>
                    <span className={`chip chip-${style.finish}`}>{FINISH_LABELS[style.finish]}</span>
                  </span>
                </button>
              </li>
            )
          })}
        </ul>
      </section>

      <section className={`panel ${current ? '' : 'is-disabled'}`} aria-disabled={!current}>
        <header className="panel-head">
          <h2>{selected ? `${PART_LABELS[selected]} colour` : 'Colour'}</h2>
          <span className="panel-sub">{current ? 'Pick a swatch or type a hex' : 'Select a part first'}</span>
        </header>
        <div className="swatch-grid" role="listbox" aria-label="Colour swatches">
          {PALETTE.map((p) => {
            const active = current?.color === p.hex
            return (
              <button
                key={p.hex}
                type="button"
                role="option"
                aria-selected={active}
                className={`swatch ${active ? 'is-active' : ''} ${relativeLuminance(p.hex) > 0.6 ? 'is-light' : ''}`}
                style={{ background: p.hex }}
                title={`${p.name} ${p.hex.toUpperCase()}`}
                disabled={!current}
                onClick={() => selected && onUpdatePart(selected, { color: p.hex })}
                data-testid={`swatch-${p.name.toLowerCase()}`}
              >
                <span className="sr-only">{p.name}</span>
              </button>
            )
          })}
        </div>
        <div className="colour-row">
          <label className="colour-input" title="Custom colour">
            <input
              type="color"
              value={current?.color ?? '#000000'}
              disabled={!current}
              onChange={(e) => selected && onUpdatePart(selected, { color: e.target.value })}
              aria-label="Custom colour picker"
            />
            <span>Custom</span>
          </label>
          <input
            className="hex-input"
            type="text"
            value={hexValue}
            disabled={!current}
            spellCheck={false}
            maxLength={7}
            onChange={(e) => setHexDraft({ base: currentColor, value: e.target.value })}
            onBlur={commitHex}
            onKeyDown={(e) => e.key === 'Enter' && commitHex()}
            aria-label="Hex colour"
            placeholder="#RRGGBB"
            data-testid="hex-input"
          />
        </div>
      </section>

      <section className={`panel ${current ? '' : 'is-disabled'}`} aria-disabled={!current}>
        <header className="panel-head">
          <h2>Finish</h2>
          <span className="panel-sub">{current ? `Applied to the ${PART_LABELS[selected!].toLowerCase()}` : 'Select a part first'}</span>
        </header>
        <div className="segmented full" role="group" aria-label="Material finish">
          {FINISHES.map((f) => (
            <button
              key={f}
              type="button"
              className={`seg ${current?.finish === f ? 'is-active' : ''}`}
              aria-pressed={current?.finish === f}
              disabled={!current}
              onClick={() => selected && onUpdatePart(selected, { finish: f })}
              data-testid={`finish-${f}`}
            >
              <span className={`finish-dot finish-${f}`} aria-hidden="true" />
              {FINISH_LABELS[f]}
            </button>
          ))}
        </div>
      </section>

      <section className="panel">
        <header className="panel-head">
          <h2>Engraving</h2>
          <span className="panel-sub">Stitched onto the heel tab</span>
        </header>
        <div className="engrave-row">
          <input
            className="engrave-input"
            type="text"
            value={config.text}
            maxLength={MAX_TEXT}
            placeholder="YOUR NAME"
            spellCheck={false}
            autoComplete="off"
            onChange={(e) => onText(sanitizeText(e.target.value))}
            aria-label="Engraving text"
            data-testid="engrave-input"
          />
          <span className="counter">
            {config.text.length}/{MAX_TEXT}
          </span>
        </div>
      </section>

      <section className="panel">
        <header className="panel-head">
          <h2>Share</h2>
          <span className="panel-sub">The URL encodes the whole design</span>
        </header>
        <div className="share-row">
          <input
            className="share-url"
            type="text"
            readOnly
            value={shareUrl}
            onFocus={(e) => e.currentTarget.select()}
            aria-label="Share URL"
            data-testid="share-url"
          />
          <button type="button" className="btn" onClick={onShare} data-testid="copy-link">
            Copy
          </button>
        </div>
        <a className="open-link" href={shareUrl} target="_blank" rel="noreferrer" data-testid="open-link">
          Open in a new tab ↗
        </a>
      </section>

      <div className="sidebar-footer">
        <button type="button" className="btn primary large" onClick={onDownload} data-testid="download-png">
          <span aria-hidden="true">⤓</span> Download PNG
        </button>
      </div>
    </aside>
  )
}
