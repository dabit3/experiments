import type { ReactNode } from 'react'
import type { SlideElement, TextAlign, Theme, ThemeId } from '../types'
import { THEMES } from '../lib/themes'
import { STICKERS, stickerArt } from '../lib/stickers'
import { Icon } from './Icons'

interface Props {
  element: SlideElement | null
  theme: Theme
  onThemeChange: (id: ThemeId) => void
  onPatch: (patch: Partial<SlideElement>) => void
  onDelete: () => void
  onDuplicate: () => void
  onBringForward: () => void
  onSendBackward: () => void
}

const FONT_SIZES = [16, 20, 24, 28, 32, 40, 48, 60, 72, 96]

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="prop-row">
      <div className="prop-label">{label}</div>
      <div className="prop-control">{children}</div>
    </div>
  )
}

function Swatches({ value, palette, onChange, allowNone }: { value: string | undefined; palette: string[]; onChange: (v: string | undefined) => void; allowNone?: boolean }) {
  return (
    <div className="swatches">
      {allowNone && (
        <button
          type="button"
          className={`swatch swatch-none ${value === undefined ? 'is-active' : ''}`}
          title="None"
          onClick={() => onChange(undefined)}
        />
      )}
      {palette.map((c) => (
        <button
          key={c}
          type="button"
          className={`swatch ${value?.toLowerCase() === c.toLowerCase() ? 'is-active' : ''}`}
          style={{ background: c }}
          title={c}
          onClick={() => onChange(c)}
        />
      ))}
      <label className="swatch swatch-custom" title="Custom colour">
        <input type="color" value={value && /^#[0-9a-f]{6}$/i.test(value) ? value : '#888888'} onChange={(e) => onChange(e.target.value)} />
      </label>
    </div>
  )
}

export function PropertiesPanel({ element, theme, onThemeChange, onPatch, onDelete, onDuplicate, onBringForward, onSendBackward }: Props) {
  if (!element) {
    return (
      <aside className="props" aria-label="Slide properties">
        <h2 className="props-title">Theme</h2>
        <p className="props-hint">Applies to every slide in the deck.</p>
        <div className="theme-grid">
          {THEMES.map((t) => (
            <button
              key={t.id}
              type="button"
              className={`theme-card ${t.id === theme.id ? 'is-active' : ''}`}
              onClick={() => onThemeChange(t.id)}
              title={t.name}
            >
              <div className={`theme-preview theme-${t.id}`} style={{ color: t.text, fontFamily: t.headingFont }}>
                <div className="slide-decor" aria-hidden="true" />
                <span className="theme-preview-title">Aa</span>
                <span className="theme-preview-bar" style={{ background: t.accent }} />
              </div>
              <span className="theme-name">
                <span>
                  {t.name}
                  <small>{t.tagline}</small>
                </span>
                {t.id === theme.id && <Icon name="check" size={14} />}
              </span>
            </button>
          ))}
        </div>
        <h2 className="props-title">Tips</h2>
        <ul className="props-tips">
          <li>Double-click text or a shape to edit its text.</li>
          <li>Drag the corner handles to resize, the top knob to rotate.</li>
          <li>Right-click a thumbnail to duplicate or delete it.</li>
          <li>
            <kbd>Ctrl</kbd>+<kbd>Z</kbd> undo · <kbd>Ctrl</kbd>+<kbd>Y</kbd> redo · <kbd>Del</kbd> remove
          </li>
        </ul>
      </aside>
    )
  }

  const kindLabel: Record<SlideElement['kind'], string> = {
    text: 'Text box',
    rect: 'Rectangle',
    ellipse: 'Ellipse',
    arrow: 'Arrow',
    sticker: 'Sticker',
  }

  const fontSize = element.kind === 'sticker' ? undefined : element.fontSize
  const setFontSize = (v: number) => onPatch({ fontSize: Math.max(8, Math.min(200, Math.round(v))) } as Partial<SlideElement>)

  return (
    <aside className="props" aria-label="Element properties">
      <div className="props-heading">
        <span className="props-kind">
          <Icon name={element.kind === 'sticker' ? 'sticker' : element.kind} size={16} />
        </span>
        <h2 className="props-title">{kindLabel[element.kind]}</h2>
      </div>

      {element.kind === 'text' && (
        <>
          <Row label="Font size">
            <div className="stepper">
              <button type="button" className="btn btn-icon" onClick={() => setFontSize(element.fontSize - 4)} aria-label="Smaller">
                −
              </button>
              <input
                type="number"
                className="input input-num"
                value={element.fontSize}
                min={8}
                max={200}
                onChange={(e) => setFontSize(Number(e.target.value) || element.fontSize)}
              />
              <button type="button" className="btn btn-icon" onClick={() => setFontSize(element.fontSize + 4)} aria-label="Larger">
                +
              </button>
            </div>
            <div className="chips">
              {FONT_SIZES.map((s) => (
                <button key={s} type="button" className={`chip ${element.fontSize === s ? 'is-active' : ''}`} onClick={() => setFontSize(s)}>
                  {s}
                </button>
              ))}
            </div>
          </Row>
          <Row label="Alignment">
            <div className="seg">
              {(['left', 'center', 'right'] as TextAlign[]).map((a) => (
                <button
                  key={a}
                  type="button"
                  className={`seg-btn ${element.align === a ? 'is-active' : ''}`}
                  onClick={() => onPatch({ align: a } as Partial<SlideElement>)}
                  title={`Align ${a}`}
                  aria-label={`Align ${a}`}
                >
                  <Icon name={a === 'left' ? 'alignLeft' : a === 'center' ? 'alignCenter' : 'alignRight'} />
                </button>
              ))}
            </div>
          </Row>
          <Row label="Style">
            <div className="seg">
              <button type="button" className={`seg-btn ${element.bold ? 'is-active' : ''}`} onClick={() => onPatch({ bold: !element.bold } as Partial<SlideElement>)} title="Bold">
                <Icon name="bold" /> Bold
              </button>
              <button type="button" className={`seg-btn ${element.bullets ? 'is-active' : ''}`} onClick={() => onPatch({ bullets: !element.bullets } as Partial<SlideElement>)} title="Bulleted list">
                <Icon name="bullets" /> Bullets
              </button>
            </div>
          </Row>
          <Row label="Text colour">
            <Swatches value={element.color} palette={[theme.text, ...theme.palette]} onChange={(v) => onPatch({ color: v } as Partial<SlideElement>)} allowNone />
          </Row>
          <Row label="Fill">
            <Swatches value={element.fill} palette={theme.palette} onChange={(v) => onPatch({ fill: v } as Partial<SlideElement>)} allowNone />
          </Row>
        </>
      )}

      {(element.kind === 'rect' || element.kind === 'ellipse' || element.kind === 'arrow') && (
        <>
          <Row label="Fill">
            <Swatches value={element.fill} palette={theme.palette} onChange={(v) => v && onPatch({ fill: v } as Partial<SlideElement>)} />
          </Row>
          {element.kind !== 'arrow' && fontSize !== undefined && (
            <Row label="Label size">
              <div className="stepper">
                <button type="button" className="btn btn-icon" onClick={() => setFontSize(fontSize - 2)} aria-label="Smaller">
                  −
                </button>
                <input type="number" className="input input-num" value={fontSize} min={8} max={200} onChange={(e) => setFontSize(Number(e.target.value) || fontSize)} />
                <button type="button" className="btn btn-icon" onClick={() => setFontSize(fontSize + 2)} aria-label="Larger">
                  +
                </button>
              </div>
            </Row>
          )}
        </>
      )}

      {element.kind === 'sticker' && (
        <Row label="Emoji">
          <div className="emoji-grid">
            {STICKERS.map((e) => (
              <button key={e} type="button" className={`emoji-btn ${element.emoji === e ? 'is-active' : ''}`} onClick={() => onPatch({ emoji: e } as Partial<SlideElement>)}>
                <img src={stickerArt(e)} alt={e} draggable={false} />
              </button>
            ))}
          </div>
        </Row>
      )}

      <Row label="Position">
        <div className="pos-grid">
          {(['x', 'y', 'w', 'h'] as const).map((k) => (
            <label key={k} className="pos-field">
              <span>{k.toUpperCase()}</span>
              <input type="number" className="input input-num" value={element[k]} onChange={(e) => onPatch({ [k]: Number(e.target.value) || 0 } as Partial<SlideElement>)} />
            </label>
          ))}
          <label className="pos-field">
            <span>Rot</span>
            <input type="number" className="input input-num" value={element.rotation} onChange={(e) => onPatch({ rotation: Number(e.target.value) || 0 })} />
          </label>
        </div>
      </Row>

      <Row label="Arrange">
        <div className="btn-row">
          <button type="button" className="btn" onClick={onBringForward} title="Bring forward">
            <Icon name="front" /> Forward
          </button>
          <button type="button" className="btn" onClick={onSendBackward} title="Send backward">
            <Icon name="back" /> Backward
          </button>
        </div>
        <div className="btn-row">
          <button type="button" className="btn" onClick={onDuplicate} title="Duplicate (Ctrl+D)">
            <Icon name="copy" /> Duplicate
          </button>
          <button type="button" className="btn btn-danger" onClick={onDelete} title="Delete (Del)">
            <Icon name="trash" /> Delete
          </button>
        </div>
      </Row>
    </aside>
  )
}
