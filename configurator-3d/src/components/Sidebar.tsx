import { useState } from 'react'
import {
  FINISHES,
  FINISH_LABELS,
  MAX_TEXT,
  PALETTE,
  PART_HINTS,
  PART_IDS,
  PART_LABELS,
  normalizeHex,
  relativeLuminance,
  sanitizeText,
  type Finish,
  type PartId,
  type SneakerConfig,
} from '../config'
import { Icon } from './Icon'

type Section = 'materials' | 'personalise' | 'save'

interface Props {
  config: SneakerConfig
  selected: PartId | null
  section: Section
  onSection: (section: Section) => void
  onSelect: (part: PartId | null) => void
  onUpdatePart: (part: PartId, patch: Partial<{ color: string; finish: Finish }>) => void
  onText: (text: string) => void
  shareUrl: string
  onShare: () => void
  onDownload: () => void
}

const SECTIONS = ['materials', 'personalise', 'save'] as const
const SECTION_LABELS = { materials: 'Materials', personalise: 'Personalise', save: 'Your design' }
const FINISH_HINTS = { matte: 'Soft leather', gloss: 'Patent shine', metallic: 'Brushed foil' }

export function Sidebar({
  config,
  selected,
  section,
  onSection,
  onSelect,
  onUpdatePart,
  onText,
  shareUrl,
  onShare,
  onDownload,
}: Props) {
  const id = selected ?? 'upper'
  const current = config.parts[id]
  const [hexDraft, setHexDraft] = useState<{ part: PartId; base: string; value: string } | null>(null)
  const hexValue = hexDraft?.part === id && hexDraft.base === current.color ? hexDraft.value : current.color
  const colorName = PALETTE.find((p) => p.hex === current.color)?.name ?? 'Custom colour'
  const commitHex = () => {
    const hex = normalizeHex(hexValue)
    if (hex) onUpdatePart(id, { color: hex })
    setHexDraft(null)
  }

  return (
    <aside className="sidebar" aria-label="Customise your sneaker">
      <header className="product-intro">
        <div className="product-kicker">
          <span>YOUR ONE OF ONE</span>
          <span>01 / LOW TOP</span>
        </div>
        <h2>
          Court Classic<span>By you.</span>
        </h2>
        <p>An icon is just the beginning. Make it yours.</p>
      </header>
      <div className="studio-tabs" role="tablist" aria-label="Design steps">
        {SECTIONS.map((tab, i) => (
          <button
            key={tab}
            type="button"
            role="tab"
            id={`tab-${tab}`}
            aria-controls={`panel-${tab}`}
            aria-selected={section === tab}
            onClick={() => onSection(tab)}
            className={section === tab ? 'is-active' : ''}
            onKeyDown={(e) => {
              if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return
              e.preventDefault()
              const next = SECTIONS[(i + (e.key === 'ArrowRight' ? 1 : 2)) % SECTIONS.length]
              onSection(next)
              document.getElementById(`tab-${next}`)?.focus()
            }}
            tabIndex={section === tab ? 0 : -1}
          >
            <span>0{i + 1}</span>
            {SECTION_LABELS[tab]}
          </button>
        ))}
      </div>

      <div className="sidebar-content" id={`panel-${section}`} role="tabpanel" aria-labelledby={`tab-${section}`}>
        {section === 'materials' && (
          <>
            <section className="panel">
              <header className="panel-head">
                <h3>Choose your canvas</h3>
                <span>8 panels. No limits.</span>
              </header>
              <ul className="part-list">
                {PART_IDS.map((part) => {
                  const style = config.parts[part]
                  return (
                    <li key={part}>
                      <button
                        type="button"
                        className={`part-row ${id === part ? 'is-active' : ''}`}
                        aria-pressed={id === part}
                        onClick={() => onSelect(part)}
                        data-testid={`part-${part}`}
                        title={`${PART_HINTS[part]} · ${style.color.toUpperCase()} · ${FINISH_LABELS[style.finish]}`}
                      >
                        <span
                          className={`part-swatch finish-${style.finish}`}
                          style={{ backgroundColor: style.color }}
                        />
                        <span className="part-name">{PART_LABELS[part]}</span>
                        {id === part && <Icon name="check" size={14} />}
                      </button>
                    </li>
                  )
                })}
              </ul>
            </section>
            <section className="panel">
              <header className="panel-head">
                <h3>{PART_LABELS[id]} colour</h3>
                <span>{colorName}</span>
              </header>
              <div className="swatch-grid" role="group" aria-label="Colour swatches">
                {PALETTE.map((p) => (
                  <button
                    key={p.hex}
                    type="button"
                    aria-pressed={current.color === p.hex}
                    className={`swatch ${current.color === p.hex ? 'is-active' : ''}`}
                    style={{ backgroundColor: p.hex, color: relativeLuminance(p.hex) > 0.35 ? '#111' : '#fff' }}
                    title={`${p.name} ${p.hex.toUpperCase()}`}
                    onClick={() => onUpdatePart(id, { color: p.hex })}
                    data-testid={`swatch-${p.name.toLowerCase()}`}
                  >
                    {current.color === p.hex && <Icon name="check" size={16} />}
                    <span className="sr-only">{p.name}</span>
                  </button>
                ))}
              </div>
              <div className="colour-row">
                <label className="colour-input">
                  <input
                    type="color"
                    value={current.color}
                    onChange={(e) => onUpdatePart(id, { color: e.target.value })}
                    aria-label="Custom colour picker"
                  />
                  Custom colour
                </label>
                <input
                  className="hex-input"
                  type="text"
                  value={hexValue}
                  spellCheck={false}
                  maxLength={7}
                  onChange={(e) => setHexDraft({ part: id, base: current.color, value: e.target.value })}
                  onBlur={commitHex}
                  onKeyDown={(e) => e.key === 'Enter' && commitHex()}
                  aria-label="Hex colour"
                  data-testid="hex-input"
                />
              </div>
            </section>
            <section className="panel">
              <header className="panel-head">
                <h3>The finishing touch</h3>
                <span>{FINISH_LABELS[current.finish]}</span>
              </header>
              <div className="finish-options" role="group" aria-label="Material finish">
                {FINISHES.map((finish) => (
                  <button
                    key={finish}
                    type="button"
                    className={`finish-option ${current.finish === finish ? 'is-active' : ''}`}
                    aria-pressed={current.finish === finish}
                    onClick={() => onUpdatePart(id, { finish })}
                    data-testid={`finish-${finish}`}
                  >
                    <span className={`material-sphere finish-${finish}`} aria-hidden="true" />
                    <strong>{FINISH_LABELS[finish]}</strong>
                    <small>{FINISH_HINTS[finish]}</small>
                  </button>
                ))}
              </div>
            </section>
          </>
        )}
        {section === 'personalise' && (
          <section className="personalise-panel">
            <span className="eyebrow">THE DETAIL THAT MAKES IT YOURS</span>
            <h3>Leave your mark.</h3>
            <p>
              A name. A number. A little reminder.
              <br />
              Your signature, stitched into the heel.
            </p>
            <div
              className="label-preview"
              style={{
                backgroundColor: config.parts.heel.color,
                color: relativeLuminance(config.parts.heel.color) > 0.35 ? '#252520' : '#f2eee3',
              }}
            >
              <span>COURT / 01</span>
              <strong>{config.text || 'YOUR NAME'}</strong>
              <small>ONE OF ONE</small>
            </div>
            <label className="field-label" htmlFor="engraving">
              Engraving <span>UP TO 8 CHARACTERS</span>
            </label>
            <div className="engrave-row">
              <input
                id="engraving"
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
            <p className="field-help">Letters, numbers, spaces and . - &amp; !</p>
            <button type="button" className="text-button" onClick={() => onSelect('heel')}>
              Change the heel colour <Icon name="arrow" />
            </button>
          </section>
        )}
        {section === 'save' && (
          <section className="save-panel">
            <span className="eyebrow">DESIGNED BY YOU. ONLY YOU.</span>
            <h3>
              One of a kind.
              <br />
              Ready to share.
            </h3>
            <p>
              Every colour. Every finish. Every detail.
              <br />
              Your entire design, saved in a link.
            </p>
            <div className="design-receipt">
              <header>
                <strong>COURT CLASSIC / 01</strong>
                <span>{config.text || 'YOUR EDITION'}</span>
              </header>
              {PART_IDS.map((part) => (
                <div key={part}>
                  <span className="receipt-swatch" style={{ backgroundColor: config.parts[part].color }} />
                  <span>{PART_LABELS[part]}</span>
                  <code>{config.parts[part].color.toUpperCase()}</code>
                  <span>{FINISH_LABELS[config.parts[part].finish]}</span>
                </div>
              ))}
            </div>
            <label className="field-label" htmlFor="share">
              Your share link
            </label>
            <div className="share-row">
              <input
                id="share"
                className="share-url"
                type="text"
                readOnly
                value={shareUrl}
                onFocus={(e) => e.currentTarget.select()}
                aria-label="Share URL"
                data-testid="share-url"
              />
              <button type="button" className="btn outline" onClick={onShare} data-testid="copy-link">
                Copy
              </button>
            </div>
            <a className="open-link" href={shareUrl} target="_blank" rel="noreferrer" data-testid="open-link">
              Open in a new tab <Icon name="arrow" size={16} />
            </a>
          </section>
        )}
      </div>
      <footer className="sidebar-footer">
        <button type="button" className="btn primary large" onClick={onDownload} data-testid="download-png">
          Download PNG <Icon name="download" size={19} />
        </button>
        <span className="footer-note">Your design. High resolution. No sign-up.</span>
      </footer>
    </aside>
  )
}
