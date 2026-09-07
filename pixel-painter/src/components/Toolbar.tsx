import { MAX_BRUSH_SIZE, MIN_BRUSH_SIZE, PALETTE, TOOLS, type Tool } from '../types'
import { ToolIcon } from './ToolIcon'
import './Toolbar.css'

interface Props {
  tool: Tool
  color: string
  size: number
  fillShape: boolean
  canUndo: boolean
  canRedo: boolean
  onToolChange: (tool: Tool) => void
  onColorChange: (color: string) => void
  onSizeChange: (size: number) => void
  onFillShapeChange: (fill: boolean) => void
  onUndo: () => void
  onRedo: () => void
  onClear: () => void
  onDownload: () => void
}

export function Toolbar({
  tool,
  color,
  size,
  fillShape,
  canUndo,
  canRedo,
  onToolChange,
  onColorChange,
  onSizeChange,
  onFillShapeChange,
  onUndo,
  onRedo,
  onClear,
  onDownload,
}: Props) {
  return (
    <aside className="toolbar">
      <header className="toolbar-brand">
        <span className="brand-dot" />
        <h1>Pixel Painter</h1>
      </header>

      <section className="toolbar-section">
        <h2>Tools</h2>
        <div className="tool-grid">
          {TOOLS.map((t) => (
            <button
              key={t.id}
              type="button"
              className={`tool-button${tool === t.id ? ' active' : ''}`}
              onClick={() => onToolChange(t.id)}
              title={`${t.label} (${t.hotkey})`}
              aria-label={t.label}
              aria-pressed={tool === t.id}
              data-tool={t.id}
            >
              <ToolIcon tool={t.id} />
              <span>{t.label}</span>
              <kbd>{t.hotkey}</kbd>
            </button>
          ))}
        </div>
        <label className="fill-toggle">
          <input
            type="checkbox"
            checked={fillShape}
            onChange={(e) => onFillShapeChange(e.target.checked)}
          />
          Fill shapes
        </label>
      </section>

      <section className="toolbar-section">
        <h2>
          Brush size <output>{size}px</output>
        </h2>
        <div className="size-row">
          <input
            type="range"
            min={MIN_BRUSH_SIZE}
            max={MAX_BRUSH_SIZE}
            value={size}
            aria-label="Brush size"
            onChange={(e) => onSizeChange(Number(e.target.value))}
          />
          <span className="size-preview">
            <span
              style={{
                width: Math.min(size, 36),
                height: Math.min(size, 36),
                background: tool === 'eraser' ? '#fff' : color,
              }}
            />
          </span>
        </div>
      </section>

      <section className="toolbar-section">
        <h2>Color</h2>
        <div className="palette">
          {PALETTE.map((swatch) => (
            <button
              key={swatch}
              type="button"
              className={`swatch${color.toLowerCase() === swatch ? ' active' : ''}`}
              style={{ background: swatch }}
              onClick={() => onColorChange(swatch)}
              aria-label={`Color ${swatch}`}
              title={swatch}
            />
          ))}
        </div>
        <label className="custom-color">
          <input
            type="color"
            value={color}
            aria-label="Custom color"
            onChange={(e) => onColorChange(e.target.value)}
          />
          <span className="color-hex">{color.toUpperCase()}</span>
        </label>
      </section>

      <section className="toolbar-section actions">
        <div className="action-row">
          <button type="button" onClick={onUndo} disabled={!canUndo} title="Undo (Ctrl+Z)">
            Undo
          </button>
          <button
            type="button"
            onClick={onRedo}
            disabled={!canRedo}
            title="Redo (Ctrl+Shift+Z)"
          >
            Redo
          </button>
        </div>
        <button type="button" className="danger" onClick={onClear}>
          Clear canvas
        </button>
        <button type="button" className="primary" onClick={onDownload}>
          Download PNG
        </button>
      </section>

      <footer className="toolbar-hint">
        <kbd>Ctrl</kbd>+<kbd>Z</kbd> undo · <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Z</kbd> redo ·{' '}
        <kbd>[</kbd> <kbd>]</kbd> brush size
      </footer>
    </aside>
  )
}
