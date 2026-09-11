import { useCallback, useEffect, useRef, useState } from 'react'
import { PaintCanvas } from './components/PaintCanvas'
import { Toolbar } from './components/Toolbar'
import { ToolIcon } from './components/ToolIcon'
import { Icon } from './components/Icon'
import { ColorPanel } from './components/ColorPanel'
import { ReferencePanel } from './components/ReferencePanel'
import { useHistory } from './hooks/useHistory'
import {
  CANVAS_BACKGROUND,
  CANVAS_HEIGHT,
  CANVAS_WIDTH,
  MAX_BRUSH_SIZE,
  MIN_BRUSH_SIZE,
  TOOLS,
  type Point,
  type Tool,
} from './types'
import './App.css'

const TOOL_HINTS: Record<Tool, string> = {
  brush: 'Drag to paint · Hold Shift for a straight stroke',
  eraser: 'Drag to erase · [ and ] to change size',
  line: 'Drag to draw a line · Shift snaps to 45°',
  rect: 'Drag to draw a rectangle · Shift for a square',
  circle: 'Drag to draw an ellipse · Shift for a circle',
  freeform: 'Draw a closed contour · Release to fill',
  fill: 'Click an enclosed area to fill with color',
  eyedropper: 'Click the canvas to sample a color',
}

export default function App() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const viewportRef = useRef<HTMLDivElement>(null)
  const coordsRef = useRef<HTMLSpanElement>(null)
  const dialogRef = useRef<HTMLDialogElement>(null)
  const [tool, setTool] = useState<Tool>('brush')
  const [color, setColor] = useState('#ffa940')
  const [size, setSize] = useState(12)
  const [opacity, setOpacity] = useState(100)
  const [smooth, setSmooth] = useState(true)
  const [fillShape, setFillShape] = useState(false)
  const [name, setName] = useState('Untitled-01')
  const [hasMarks, setHasMarks] = useState(false)
  const [zoom, setZoom] = useState<number | 'fit'>('fit')
  const [fitScale, setFitScale] = useState(1)
  const [grid, setGrid] = useState(false)
  const [toast, setToast] = useState('')
  const [help, setHelp] = useState(false)
  const { push, undo: popUndo, redo: popRedo, canUndo, canRedo } = useHistory()
  const scale = zoom === 'fit' ? fitScale : zoom
  const toolLabel = TOOLS.find((t) => t.id === tool)?.label ?? tool
  const shapeTool = tool === 'rect' || tool === 'circle'

  useEffect(() => {
    const viewport = viewportRef.current
    if (!viewport) return
    const observer = new ResizeObserver(([entry]) => {
      setFitScale(
        Math.max(
          0.1,
          Math.min(
            (entry.contentRect.width - 100) / CANVAS_WIDTH,
            (entry.contentRect.height - 104) / CANVAS_HEIGHT,
            1,
          ),
        ),
      )
    })
    observer.observe(viewport)
    return () => observer.disconnect()
  }, [])

  useEffect(() => {
    if (!toast) return
    const timer = window.setTimeout(() => setToast(''), 3000)
    return () => window.clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    if (help) dialogRef.current?.showModal()
    else dialogRef.current?.close()
  }, [help])

  const snapshot = useCallback(
    () =>
      canvasRef.current
        ?.getContext('2d')
        ?.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT) ?? null,
    [],
  )
  const recordHistory = useCallback(() => {
    const current = snapshot()
    if (current) push(current)
    setHasMarks(true)
  }, [push, snapshot])

  const undo = useCallback(() => {
    const ctx = canvasRef.current?.getContext('2d')
    const current = snapshot()
    if (!ctx || !current) return
    const previous = popUndo(current)
    if (previous) {
      ctx.putImageData(previous, 0, 0)
      setToast('Undone')
    }
  }, [popUndo, snapshot])

  const redo = useCallback(() => {
    const ctx = canvasRef.current?.getContext('2d')
    const current = snapshot()
    if (!ctx || !current) return
    const next = popRedo(current)
    if (next) {
      ctx.putImageData(next, 0, 0)
      setToast('Redone')
    }
  }, [popRedo, snapshot])

  const clear = () => {
    const ctx = canvasRef.current?.getContext('2d')
    if (!ctx) return
    recordHistory()
    ctx.save()
    ctx.globalAlpha = 1
    ctx.fillStyle = CANVAS_BACKGROUND
    ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)
    ctx.restore()
    setToast('Canvas cleared · Undo to restore')
  }

  const download = () => {
    canvasRef.current?.toBlob((blob) => {
      if (!blob) {
        setToast('Export failed. Please try again.')
        return
      }
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `${name.trim().replace(/[<>:"/\\|?*]/g, '-') || 'Untitled-01'}.png`
      link.click()
      window.setTimeout(() => URL.revokeObjectURL(url), 1000)
      setToast('PNG exported · 1040 × 680 px')
    }, 'image/png')
  }

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      if (
        help ||
        target?.isContentEditable ||
        (target && ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName))
      )
        return
      const key = e.key.toLowerCase()
      if (e.ctrlKey || e.metaKey) {
        if (key === 'z') {
          e.preventDefault()
          if (e.shiftKey) redo()
          else undo()
        } else if (key === 'y') {
          e.preventDefault()
          redo()
        }
        return
      }
      const hotkeyTool = TOOLS.find((t) => t.hotkey.toLowerCase() === key)
      if (hotkeyTool) setTool(hotkeyTool.id)
      else if (key === '[') setSize((s) => Math.max(MIN_BRUSH_SIZE, s - 2))
      else if (key === ']') setSize((s) => Math.min(MAX_BRUSH_SIZE, s + 2))
      else if (key === '?') setHelp(true)
      else if (key === '0') setZoom('fit')
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [undo, redo, help])

  const showPointer = useCallback((point: Point | null) => {
    if (coordsRef.current)
      coordsRef.current.textContent = point
        ? `X ${Math.round(point.x)}   Y ${Math.round(point.y)}`
        : 'X —   Y —'
  }, [])

  return (
    <div className="app">
      <header className="app-header">
        <a className="brand" href="./" aria-label="Pixel Painter home">
          <span className="brand-mark">
            p<span />
          </span>
          <span>
            pixel<span className="brand-light">painter</span>
            <small>STUDIO</small>
          </span>
        </a>
        <div className="header-divider" />
        <span className="workspace-label">Design workspace</span>
        <div className="document-title">
          <Icon name="file" size={15} />
          <input
            aria-label="Document name"
            value={name}
            maxLength={64}
            onChange={(e) => setName(e.target.value)}
            onBlur={() => {
              if (!name.trim()) setName('Untitled-01')
            }}
          />
          <span
            className="local-dot"
            title="Document stays in this tab; export to save"
          />
        </div>
        <button className="guide-button" onClick={() => setHelp(true)}>
          Quick guide
          <Icon name="help" size={15} />
        </button>
        <button
          className="export-button"
          onClick={download}
          aria-label="Download PNG"
        >
          <Icon name="download" size={16} />
          Export image<span>PNG</span>
        </button>
      </header>

      <div className="context-bar">
        <div className="current-tool">
          <ToolIcon tool={tool} />
          <strong>{toolLabel}</strong>
        </div>
        <span className="control-divider" />
        <label className="compact-control">
          <span>Size</span>
          <input
            aria-label="Brush size value"
            type="number"
            min={1}
            max={120}
            value={size}
            onChange={(e) =>
              setSize(Math.max(1, Math.min(120, Number(e.target.value) || 1)))
            }
          />
          <small>px</small>
        </label>
        <label className="compact-control">
          <span>Opacity</span>
          <input
            aria-label="Opacity"
            type="number"
            min={1}
            max={100}
            value={opacity}
            disabled={tool === 'fill' || tool === 'eyedropper'}
            onChange={(e) =>
              setOpacity(
                Math.max(1, Math.min(100, Number(e.target.value) || 1)),
              )
            }
          />
          <small>%</small>
        </label>
        <span className="control-divider" />
        {shapeTool ? (
          <label className="check-control">
            <input
              type="checkbox"
              checked={fillShape}
              onChange={(e) => setFillShape(e.target.checked)}
            />
            Fill shape
          </label>
        ) : (
          <label className="check-control">
            <input
              type="checkbox"
              checked={smooth}
              onChange={(e) => setSmooth(e.target.checked)}
            />
            Smooth stroke
          </label>
        )}
        <div className="context-actions">
          <button
            className="icon-button"
            aria-label="Undo"
            title="Undo (Ctrl+Z)"
            disabled={!canUndo}
            onClick={undo}
          >
            <Icon name="undo" />
          </button>
          <button
            className="icon-button"
            aria-label="Redo"
            title="Redo (Ctrl+Shift+Z)"
            disabled={!canRedo}
            onClick={redo}
          >
            <Icon name="redo" />
          </button>
          <span className="control-divider" />
          <button className="clear-button" onClick={clear}>
            <Icon name="trash" size={15} />
            Clear canvas
          </button>
        </div>
      </div>

      <div className="studio">
        <Toolbar
          tool={tool}
          color={color}
          onToolChange={setTool}
          onHelp={() => setHelp(true)}
        />
        <main className="workspace">
          <div className="document-tabs">
            <div className="document-tab">
              <span className="tab-dot" />
              <strong>{name || 'Untitled-01'}</strong>
              <span>@ {Math.round(scale * 100)}%</span>
            </div>
            <span className="document-mode">RGB / 8</span>
          </div>
          <div className="canvas-viewport" ref={viewportRef}>
            <div
              className="canvas-stage"
              style={{
                minWidth: CANVAS_WIDTH * scale + 100,
                minHeight: CANVAS_HEIGHT * scale + 104,
              }}
            >
              <div className="artboard" style={{ width: CANVAS_WIDTH * scale }}>
                <div className="artboard-title">
                  <span>
                    01 <strong>ARTBOARD</strong>
                  </span>
                  <span>
                    {CANVAS_WIDTH} × {CANVAS_HEIGHT} px
                  </span>
                </div>
                <div
                  className="ruler ruler-horizontal"
                  aria-hidden="true"
                  style={{
                    backgroundSize: `${10 * scale}px 5px, ${100 * scale}px 10px`,
                  }}
                >
                  {Array.from({ length: 11 }, (_, i) => (
                    <span key={i} style={{ left: i * 100 * scale }}>
                      {i * 100}
                    </span>
                  ))}
                </div>
                <div
                  className="ruler ruler-vertical"
                  aria-hidden="true"
                  style={{
                    backgroundSize: `5px ${10 * scale}px, 10px ${100 * scale}px`,
                  }}
                >
                  {Array.from({ length: 7 }, (_, i) => (
                    <span key={i} style={{ top: i * 100 * scale }}>
                      {i * 100}
                    </span>
                  ))}
                </div>
                <PaintCanvas
                  canvasRef={canvasRef}
                  tool={tool}
                  color={color}
                  size={size}
                  fillShape={fillShape}
                  opacity={opacity / 100}
                  smooth={smooth}
                  scale={scale}
                  grid={grid}
                  onBeforeChange={recordHistory}
                  onPointerPosition={showPointer}
                  onColorPick={(picked) => {
                    setColor(picked)
                    setTool('brush')
                    setToast(`Sampled ${picked.toUpperCase()}`)
                  }}
                />
                {!hasMarks && (
                  <div className="canvas-welcome" aria-hidden="true">
                    <svg viewBox="0 0 100 70" width="90">
                      <path
                        d="M14 50C28 4 45 4 42 32S22 72 55 37s46-6 28 14"
                        fill="none"
                        stroke="#e4b77f"
                        strokeWidth="9"
                        strokeLinecap="round"
                      />
                    </svg>
                    <h1>Make your mark.</h1>
                    <p>Pick a color. Follow your curiosity.</p>
                    <span>
                      BRUSH <kbd>B</kbd>
                      <i />
                      SHAPES <kbd>R</kbd>
                      <kbd>C</kbd>
                    </span>
                  </div>
                )}
              </div>
            </div>
          </div>
          <div className="workspace-bottom">
            <span className="tool-hint">{TOOL_HINTS[tool]}</span>
            <div className="zoom-controls">
              <button
                className={`icon-button ${grid ? 'selected' : ''}`}
                aria-label="Toggle canvas grid"
                aria-pressed={grid}
                title="Canvas grid"
                onClick={() => setGrid(!grid)}
              >
                <Icon name="grid" size={15} />
              </button>
              <span className="control-divider" />
              <button
                className="icon-button"
                aria-label="Zoom out"
                disabled={scale <= 0.25}
                onClick={() => setZoom(Math.max(0.25, scale - 0.25))}
              >
                <Icon name="minus" size={14} />
              </button>
              <span>{Math.round(scale * 100)}%</span>
              <button
                className="icon-button"
                aria-label="Zoom in"
                disabled={scale >= 3}
                onClick={() => setZoom(Math.min(3, scale + 0.25))}
              >
                <Icon name="plus" size={14} />
              </button>
              <button
                className="fit-button"
                title="Fit canvas (0)"
                onClick={() => setZoom('fit')}
              >
                <Icon name="fit" size={14} />
                Fit
              </button>
            </div>
          </div>
        </main>

        <aside className="inspector" aria-label="Drawing properties">
          <div className="inspector-heading">
            <span>PROPERTIES</span>
            <Icon name="sliders" size={15} />
          </div>
          <ColorPanel color={color} onChange={setColor} />
          <section className="inspector-section brush-section">
            <div className="section-heading">
              <h2>Brush</h2>
              <span>Round · {smooth ? 'Smooth' : 'Direct'}</span>
            </div>
            <div className="brush-presets">
              {[
                { size: 4, label: 'Fine' },
                { size: 12, label: 'Ink' },
                { size: 28, label: 'Bold' },
                { size: 60, label: 'Broad' },
              ].map((preset) => (
                <button
                  key={preset.label}
                  className={
                    size === preset.size && tool === 'brush' ? 'selected' : ''
                  }
                  aria-label={`${preset.label} brush`}
                  onClick={() => {
                    setSize(preset.size)
                    setTool('brush')
                  }}
                >
                  <svg viewBox="0 0 46 34">
                    <path
                      d="M8 25C13 8 20 6 22 16S30 26 38 9"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth={preset.size / 10 + 1}
                      strokeLinecap="round"
                    />
                  </svg>
                  <span>{preset.label}</span>
                </button>
              ))}
            </div>
            <div className="size-label">
              <span>Diameter</span>
              <span>
                {size} <small>px</small>
              </span>
            </div>
            <input
              className="size-slider"
              type="range"
              aria-label="Brush size"
              min={MIN_BRUSH_SIZE}
              max={MAX_BRUSH_SIZE}
              value={size}
              onChange={(e) => setSize(Number(e.target.value))}
            />
          </section>
          <ReferencePanel />
          <div className="inspector-footer">
            <span className="local-dot" />
            <span>
              Your space to create.
              <small>Local canvas · Export to keep your work</small>
            </span>
          </div>
        </aside>
      </div>
      <footer className="app-footer">
        <span>
          <span className="connection-dot" />
          All tools ready
        </span>
        <span>
          1040 × 680 px<span className="footer-separator">/</span>RGB color
          <span className="footer-separator">/</span>8 bits per channel
        </span>
        <span ref={coordsRef}>X — Y —</span>
        <span>
          PIXEL PAINTER <small>STUDIO 01</small>
        </span>
      </footer>
      {toast && (
        <div className="toast" role="status">
          <Icon name="check" size={15} />
          {toast}
        </div>
      )}
      <dialog
        ref={dialogRef}
        className="guide-dialog"
        onClose={() => setHelp(false)}
        onClick={(e) => {
          if (e.target === dialogRef.current) setHelp(false)
        }}
      >
        <div className="guide-content">
          <div className="section-heading">
            <span className="eyebrow">THE QUICK GUIDE</span>
            <button
              className="icon-button"
              aria-label="Close guide"
              onClick={() => setHelp(false)}
            >
              <Icon name="close" />
            </button>
          </div>
          <h2>
            A little less clicking.
            <br />A lot more creating.
          </h2>
          <p>Everything you need, a keystroke away.</p>
          <div className="shortcut-grid">
            {TOOLS.map((item) => (
              <div key={item.id}>
                <ToolIcon tool={item.id} />
                <span>{item.label}</span>
                <kbd>{item.hotkey}</kbd>
              </div>
            ))}
          </div>
          <dl>
            <div>
              <dt>Undo / Redo</dt>
              <dd>Ctrl Z / Ctrl Shift Z</dd>
            </div>
            <div>
              <dt>Brush size</dt>
              <dd>[ / ]</dd>
            </div>
            <div>
              <dt>Constrain shapes</dt>
              <dd>Hold Shift</dd>
            </div>
            <div>
              <dt>Fit artboard</dt>
              <dd>0</dd>
            </div>
          </dl>
          <p className="guide-note">
            Load an image in Reference to draw alongside it. Use Freeform fill
            to paint organic silhouettes. Your document lives in this tab —
            export a PNG before leaving.
          </p>
          <button className="export-button" onClick={() => setHelp(false)}>
            Let’s create
            <Icon name="arrow" size={16} />
          </button>
        </div>
      </dialog>
    </div>
  )
}
