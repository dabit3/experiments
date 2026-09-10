import { useCallback, useEffect, useRef, useState } from 'react'
import { Sidebar } from './components/Sidebar'
import { Toolbar } from './components/Toolbar'
import {
  DEFAULT_CONFIG,
  FINISH_LABELS,
  PART_IDS,
  PART_LABELS,
  VIEWS,
  decodeConfig,
  encodeConfig,
  randomConfig,
  type Finish,
  type PartId,
  type SneakerConfig,
  type ViewId,
} from './config'
import { SneakerViewer, type ViewerApi } from './scene/SneakerViewer'
import './App.css'

function initialConfig(): SneakerConfig {
  return decodeConfig(window.location.hash) ?? structuredClone(DEFAULT_CONFIG)
}

export default function App() {
  const [config, setConfig] = useState<SneakerConfig>(initialConfig)
  const [selected, setSelected] = useState<PartId | null>(null)
  const [hovered, setHovered] = useState<PartId | null>(null)
  const [customView, setCustomView] = useState(false)
  const [seed, setSeed] = useState(0)
  const [toast, setToast] = useState<string | null>(null)
  const [ready, setReady] = useState(false)
  const apiRef = useRef<ViewerApi | null>(null)
  const toastTimer = useRef<number | null>(null)

  const showToast = useCallback((message: string) => {
    setToast(message)
    if (toastTimer.current) window.clearTimeout(toastTimer.current)
    toastTimer.current = window.setTimeout(() => setToast(null), 2600)
  }, [])

  // Keep the URL hash in sync so the address bar is always a share link.
  const shareUrl = `${window.location.origin}${window.location.pathname}${encodeConfig(config)}`
  useEffect(() => {
    window.history.replaceState(null, '', encodeConfig(config))
  }, [config])

  // Jump straight to the saved view on first mount.
  const initialView = useRef(config.view)
  useEffect(() => {
    apiRef.current?.setView(initialView.current, false)
  }, [])

  // React to the hash being edited by hand / pasted while the app is open.
  useEffect(() => {
    const onHash = () => {
      const next = decodeConfig(window.location.hash)
      if (next) {
        setConfig(next)
        setCustomView(false)
        apiRef.current?.setView(next.view, true)
      }
    }
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [])

  const setView = useCallback((view: ViewId) => {
    setCustomView(false)
    apiRef.current?.setView(view, true)
    setConfig((c) => (c.view === view ? c : { ...c, view }))
  }, [])

  const updatePart = useCallback((id: PartId, patch: Partial<{ color: string; finish: Finish }>) => {
    setConfig((c) => ({ ...c, parts: { ...c.parts, [id]: { ...c.parts[id], ...patch } } }))
  }, [])

  const randomise = useCallback(() => {
    const next = seed + 1
    setSeed(next)
    setConfig((c) => randomConfig(next, c))
    showToast(`Randomised — seed #${next}`)
  }, [seed, showToast])

  const reset = useCallback(() => {
    setConfig((c) => ({ ...structuredClone(DEFAULT_CONFIG), view: c.view, spin: c.spin }))
    showToast('Reset to the default colourway')
  }, [showToast])

  const share = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(shareUrl)
      showToast('Share link copied to clipboard')
    } catch {
      showToast('Copy failed — select the link and copy it manually')
    }
  }, [shareUrl, showToast])

  const download = useCallback(() => {
    const api = apiRef.current
    if (!api) return
    const url = api.snapshot()
    const a = document.createElement('a')
    const slug = (config.text || 'custom').toLowerCase().replace(/[^a-z0-9]+/g, '-')
    a.href = url
    a.download = `sneaker-${slug}.png`
    a.click()
    showToast(`Saved ${a.download}`)
  }, [config.text, showToast])

  // Keyboard shortcuts (ignored while typing in a field).
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      if (target && ['INPUT', 'TEXTAREA', 'BUTTON', 'SELECT'].includes(target.tagName)) return
      if (e.ctrlKey || e.metaKey || e.altKey) return
      if (e.key === 'Escape') setSelected(null)
      else if (e.key === ' ') {
        e.preventDefault()
        setConfig((c) => ({ ...c, spin: !c.spin }))
      } else if (e.key.toLowerCase() === 'r') randomise()
      else if (/^[1-4]$/.test(e.key)) setView(VIEWS[Number(e.key) - 1])
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [randomise, setView])

  const status = selected ?? hovered
  const statusStyle = status ? config.parts[status] : null
  const editedParts = PART_IDS.filter(
    (id) => config.parts[id].color !== DEFAULT_CONFIG.parts[id].color || config.parts[id].finish !== DEFAULT_CONFIG.parts[id].finish,
  ).length

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true">
              <path d="M2.5 16.5c5.5-1.2 12.4-4 19-8.3-1.6 3.3-3.4 5.6-5.6 7.2-3.9 2.9-9.1 3.4-13.4 1.1z" fill="currentColor" />
            </svg>
          </span>
          <div>
            <h1>Kicks Lab</h1>
            <p>Sneaker Studio</p>
          </div>
        </div>
        <nav className="topbar-nav" aria-label="Studio">
          <span className="nav-item is-current">Design</span>
          <span className="nav-item">Court Classic Low</span>
          <span className="nav-item nav-count">
            {editedParts}/{PART_IDS.length} parts edited
          </span>
        </nav>
        <div className="topbar-actions">
          <button type="button" className="btn ghost" onClick={reset}>
            Reset
          </button>
          <button type="button" className="btn dark" onClick={randomise} title="Shortcut: R">
            <span aria-hidden="true">⚄</span> Randomise{seed > 0 ? ` · #${seed}` : ''}
          </button>
        </div>
      </header>

      <main className="workspace">
        <section className="viewer" aria-label="3D sneaker viewer">
          <SneakerViewer
            config={config}
            selected={selected}
            onSelect={setSelected}
            onHover={setHovered}
            onOrbit={() => setCustomView(true)}
            onReady={() => setReady(true)}
            apiRef={apiRef}
          />
          <div className="viewer-watermark" aria-hidden="true">
            {config.text || 'CUSTOM'}
          </div>
          <div className="viewer-title">
            <span className="eyebrow">Custom low-top · Season 26</span>
            <h2>Court Classic</h2>
            <p>Eight editable panels, three finishes, engraved heel tab.</p>
          </div>
          <div className={`viewer-loading ${ready ? 'is-hidden' : ''}`} aria-hidden={ready}>
            <span className="spinner" />
            <span>Lacing up the scene…</span>
          </div>
          <div className="viewer-hint">
            <span>Drag to orbit</span>
            <span>Wheel to zoom</span>
            <span>Click a part to select</span>
          </div>
          <div
            className={`viewer-status ${selected ? 'is-selected' : ''} ${status ? 'is-visible' : ''}`}
            data-testid="viewer-status"
          >
            {status && statusStyle ? (
              <>
                <span className="status-swatch" style={{ background: statusStyle.color }} />
                <span className="status-name">{PART_LABELS[status]}</span>
                <span className="status-meta">
                  {statusStyle.color.toUpperCase()} · {FINISH_LABELS[statusStyle.finish]}
                </span>
                <span className="status-kind">{selected === status ? 'Selected' : 'Hover'}</span>
              </>
            ) : null}
          </div>
          <Toolbar
            view={customView ? null : config.view}
            spin={config.spin}
            onView={setView}
            onToggleSpin={() => setConfig((c) => ({ ...c, spin: !c.spin }))}
          />
        </section>

        <Sidebar
          config={config}
          selected={selected}
          onSelect={setSelected}
          onUpdatePart={updatePart}
          onText={(text) => setConfig((c) => ({ ...c, text }))}
          shareUrl={shareUrl}
          onShare={share}
          onDownload={download}
        />
      </main>

      <div className={`toast ${toast ? 'is-visible' : ''}`} role="status" aria-live="polite">
        {toast}
      </div>
    </div>
  )
}
