import { useCallback, useEffect, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import { ArrowDownToLine, ArrowLeftRight, ArrowUpRight, ChevronDown, ChevronRight, Circle as CircleIcon, Copy, Crosshair, Download, Eraser, Eye, EyeOff, File, FileInput, FileJson, FilePlus2, FileText, FolderOpen, Grid2X2, Grip, Hand, HelpCircle, Layers, Lightbulb, LockKeyhole, Maximize, Menu, MousePointer2, Move, PanelRightClose, Plus, Redo2, RotateCw, Ruler, Save, Search, Settings, Slash, Square, Trash2, Type, Undo2, UnlockKeyhole, X, ZoomIn, ZoomOut } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { anchor, arcPath, commit, controlPoints, createGeometry, distance, exportDxf, exportSvg, fitView, moveEntity, parseDrawing, parsePoint, redo, round, snapPoint, STORAGE_KEY, undo, zoomView } from './model'
import type { Draft, Drawing, Entity, History, Point, View } from './model'
import { createResidence } from './fixture'

const TOOL_NAMES = { line: 'LINE', rect: 'RECTANGLE', circle: 'CIRCLE' }
const INITIAL_NOTICE = 'Draev drafting engine ready. Drawing units: millimeters.'
const COMMAND_HELP = 'LINE · RECTANGLE · CIRCLE · MOVE · COPY · ERASE · UNDO · REDO · ZOOM E · SAVE'

function loadDrawing(): Drawing {
  try { const raw = localStorage.getItem(STORAGE_KEY); return (raw && parseDrawing(raw)) || createResidence() } catch { return createResidence() }
}
function download(content: string, file: string, type: string) {
  const url = URL.createObjectURL(new Blob([content], { type }))
  const a = document.createElement('a')
  a.href = url; a.download = file; a.click()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
function Tool({ icon: Icon, label, onClick, active, disabled, compact = false, hint }: { icon: LucideIcon; label: string; onClick?: () => void; active?: boolean; disabled?: boolean; compact?: boolean; hint?: string }) {
  return <button className={`tool ${compact ? 'compact' : ''} ${active ? 'active' : ''}`} onClick={onClick} disabled={disabled} title={disabled ? `${label} — outside this V1` : (hint || label)} aria-label={label}><Icon size={compact ? 16 : 30} strokeWidth={1.35} /><span>{label}</span></button>
}
function RibbonGroup({ title, children, className = '' }: { title: string; children: ReactNode; className?: string }) {
  return <section className={`ribbon-group ${className}`}><div className="ribbon-content">{children}</div><div className="group-title">{title}<ChevronDown size={10} /></div></section>
}
function Shape({ entity: e }: { entity: Entity }) {
  switch (e.type) {
    case 'line': return <line x1={e.x1} y1={-e.y1} x2={e.x2} y2={-e.y2} />
    case 'rect': return <rect x={e.x} y={-e.y - e.height} width={e.width} height={e.height} fill={e.hatch ? 'url(#wall-hatch)' : undefined} />
    case 'circle': return <circle cx={e.cx} cy={-e.cy} r={e.radius} />
    case 'arc': return <path d={arcPath(e)} />
    case 'polyline': return e.closed ? <polygon points={e.points.map(p => `${p.x},${-p.y}`).join(' ')} /> : <polyline points={e.points.map(p => `${p.x},${-p.y}`).join(' ')} />
    case 'text': return <text x={e.x} y={-e.y} fontSize={e.size} fill="currentColor" stroke="none" textAnchor="middle" fontFamily="Arial, sans-serif" transform={`rotate(${-e.angle} ${e.x} ${-e.y})`}>{e.text}</text>
  }
}
function NumberField({ label, value, onChange, positive = false }: { label: string; value: number; onChange: (n: number) => void; positive?: boolean }) {
  return <label className="property-row"><span>{label}</span><input key={value} aria-label={label} type="number" step="any" defaultValue={round(value)} onKeyDown={event => { if (event.key === 'Enter') event.currentTarget.blur() }} onBlur={event => {
    const n = Number(event.target.value)
    if (event.target.value.trim() && Number.isFinite(n) && Math.abs(n) <= 1e7 && (!positive || n > 0)) onChange(n)
    else event.target.value = String(round(value))
  }} /></label>
}

export default function App() {
  const [history, setHistory] = useState<History>(() => ({ past: [], present: loadDrawing(), future: [] }))
  const drawing = history.present
  const initialEntities = useRef(drawing.entities)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const selected = drawing.entities.find(e => e.id === selectedId)
  const selectedLayer = drawing.layers.find(l => l.id === selected?.layer)
  const currentLayer = drawing.layers.find(l => l.id === drawing.currentLayer)!
  const [ribbonTab, setRibbonTab] = useState('Home')
  const [draft, setDraft] = useState<Draft | null>(null)
  const [panMode, setPanMode] = useState(false)
  const [input, setInput] = useState('')
  const [logs, setLogs] = useState([INITIAL_NOTICE])
  const [commandHistory, setCommandHistory] = useState<string[]>([])
  const [historyIndex, setHistoryIndex] = useState(-1)
  const [pendingMove, setPendingMove] = useState(false)
  const [snap, setSnap] = useState(true)
  const [osnap, setOsnap] = useState(false)
  const [grid, setGrid] = useState(true)
  const [ortho, setOrtho] = useState(false)
  const [lineweights, setLineweights] = useState(true)
  const [layout, setLayout] = useState<'Model' | 'A-101'>('Model')
  const [showPalette, setShowPalette] = useState(true)
  const [layerSearch, setLayerSearch] = useState('')
  const [view, setView] = useState<View>({ x: -1000, y: -23500, width: 33000, height: 24000 })
  const [size, setSize] = useState({ width: 1100, height: 650 })
  const [cursor, setCursor] = useState<Point>({ x: 0, y: 0 })
  const [cursorPixel, setCursorPixel] = useState<Point | null>(null)
  const [dragEntity, setDragEntity] = useState<Entity | null>(null)
  const [saveError, setSaveError] = useState(false)
  const [modal, setModal] = useState<'help' | 'reset' | 'export' | 'text' | null>(null)
  const [noteText, setNoteText] = useState('')
  const [notePosition, setNotePosition] = useState('15000,1200')
  const canvasRef = useRef<SVGSVGElement>(null)
  const viewportRef = useRef<HTMLDivElement>(null)
  const commandRef = useRef<HTMLInputElement>(null)
  const importRef = useRef<HTMLInputElement>(null)
  const dialogRef = useRef<HTMLDialogElement>(null)
  const pan = useRef<{ start: Point; view: View } | null>(null)
  const drag = useRef<{ start: Point; entity: Entity } | null>(null)
  const latestDrag = useRef<Entity | null>(null)
  const ready = useRef(false)

  const log = useCallback((message: string) => setLogs(old => [...old, message].slice(-30)), [])
  const change = useCallback((updater: (d: Drawing) => Drawing) => setHistory(h => commit(h, updater(h.present))), [])
  const fit = useCallback(() => setView(fitView(drawing.entities, size.width / size.height)), [drawing.entities, size])
  const cancel = useCallback(() => { setDraft(null); setPendingMove(false); setInput(''); setPanMode(false); log('Command: *Cancel*') }, [log])

  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(drawing)); setSaveError(false) }
    catch { setSaveError(true) }
  }, [drawing])
  useEffect(() => {
    const element = viewportRef.current
    if (!element) return
    const observer = new ResizeObserver(entries => {
      const { width, height } = entries[0].contentRect
      if (!width || !height) return
      setSize({ width, height })
      setView(old => {
        if (!ready.current) { ready.current = true; return fitView(initialEntities.current, width / height) }
        const newHeight = old.width * height / width
        return { ...old, height: newHeight, y: old.y + (old.height - newHeight) / 2 }
      })
    })
    observer.observe(element)
    return () => observer.disconnect()
  }, [])
  useEffect(() => {
    const dialog = dialogRef.current
    if (modal && dialog && !dialog.open) dialog.showModal()
    if (!modal && dialog?.open) dialog.close()
  }, [modal])

  const updateSelected = (updater: (e: Entity) => Entity) => {
    if (!selected || selectedLayer?.locked) return
    change(d => ({ ...d, entities: d.entities.map(e => e.id === selected.id ? updater(e) : e) }))
  }
  const erase = useCallback(() => {
    if (!selected || selectedLayer?.locked) { log('ERASE: Select an unlocked object first.'); return }
    change(d => ({ ...d, entities: d.entities.filter(e => e.id !== selected.id) }))
    setSelectedId(null); log('ERASE: 1 object erased.')
  }, [change, log, selected, selectedLayer])
  const copy = () => {
    if (!selected) { log('COPY: Select an object first.'); return }
    const e = { ...moveEntity(selected, 500, -500), id: crypto.randomUUID() }
    change(d => ({ ...d, entities: [...d.entities, e] })); setSelectedId(e.id); log('COPY: 1 object copied, displacement 500,-500.')
  }
  const save = useCallback(() => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(drawing)); setSaveError(false); log('SAVE: Drawing saved to this browser.') }
    catch { setSaveError(true); log('Storage unavailable. Export Project JSON to save your work.') }
  }, [drawing, log])
  const startTool = (tool: Draft['tool']) => {
    setDraft({ tool }); setPendingMove(false); setPanMode(false); setSelectedId(null); setInput('')
    log(`${TOOL_NAMES[tool]}: Specify ${tool === 'circle' ? 'center point' : 'first point'}:`)
    commandRef.current?.focus()
  }
  const applyPoint = (next: Point | number, activeDraft = draft): Draft | null => {
    if (!activeDraft) return null
    if (!currentLayer.visible || currentLayer.locked) { log('Current layer is hidden or locked. Choose a visible, unlocked layer.'); return activeDraft }
    if (!activeDraft.first && typeof next !== 'number') {
      const state = { ...activeDraft, first: next }
      setDraft(state); log(`${TOOL_NAMES[activeDraft.tool]}: Specify ${activeDraft.tool === 'circle' ? 'radius' : 'next point'}:`); return state
    }
    const entity = createGeometry(activeDraft, next, drawing.currentLayer, crypto.randomUUID())
    if (!entity) { log('Invalid geometry. Specify a nonzero length, radius, or rectangle.'); return activeDraft }
    change(d => ({ ...d, entities: [...d.entities, entity] }))
    setSelectedId(entity.id); log(`${TOOL_NAMES[activeDraft.tool]}: Object created on ${currentLayer.name}.`)
    const state = activeDraft.tool === 'line' && typeof next !== 'number' ? { ...activeDraft, first: next } : null
    setDraft(state)
    return state
  }
  const exportFile = (type: 'svg' | 'dxf' | 'json') => {
    const filename = drawing.title.replace(/[^a-zA-Z0-9_-]/g, '_')
    if (type === 'svg') download(exportSvg(drawing), `${filename}.svg`, 'image/svg+xml')
    if (type === 'dxf') download(exportDxf(drawing), `${filename}.dxf`, 'application/dxf')
    if (type === 'json') download(JSON.stringify(drawing, null, 2), `${filename}.draev.json`, 'application/json')
    log(`EXPORT: ${type.toUpperCase()} downloaded.`); setModal(null)
  }

  const runCommand = (raw: string) => {
    const value = raw.trim()
    if (!value) { if (draft) { setDraft(null); log('Command completed.') }; return }
    setCommandHistory(old => [value, ...old].slice(0, 30)); setHistoryIndex(-1); setInput('')
    const parts = value.split(/\s+/), first = parts[0].toUpperCase()
    const aliases: Record<string, Draft['tool']> = { L: 'line', LINE: 'line', REC: 'rect', RECT: 'rect', RECTANGLE: 'rect', C: 'circle', CIRCLE: 'circle' }
    if (first in aliases) {
      let active: Draft | null = { tool: aliases[first] }
      startTool(active.tool)
      for (const token of parts.slice(1)) {
        if (!active) break
        const p = parsePoint(token, active.first)
        const next = p || (active.tool === 'circle' && active.first && !token.includes(',') ? Number(token) : null)
        if (next === null || (typeof next === 'number' && !Number.isFinite(next))) { log(`Invalid coordinate: ${token}. Use X,Y in millimeters.`); break }
        active = applyPoint(next, active)
      }
      return
    }
    if (['UNDO', 'U'].includes(first)) { setHistory(undo); setDraft(null); log('UNDO'); return }
    if (first === 'REDO') { setHistory(redo); setDraft(null); log('REDO'); return }
    if (['ERASE', 'E', 'DELETE'].includes(first)) { erase(); return }
    if (first === 'COPY') { copy(); return }
    if (['ZOOM', 'Z', 'EXTENTS'].includes(first)) { fit(); log('ZOOM: Drawing extents.'); return }
    if (['SAVE', 'QSAVE'].includes(first)) { save(); return }
    if (['HELP', '?'].includes(first)) { setModal('help'); return }
    if (first === 'EXPORT') { setModal('export'); return }
    if (first === 'TEXT') { setModal('text'); return }
    if (first === 'MOVE' || first === 'M' || pendingMove) {
      if (!selected || selectedLayer?.locked) { log('MOVE: Select an unlocked object first.'); return }
      const displacement = parsePoint(pendingMove ? value : parts[1] || '')
      if (!displacement) { setPendingMove(true); setDraft(null); log('MOVE: Specify displacement DX,DY:'); return }
      updateSelected(e => moveEntity(e, displacement.x, displacement.y)); setPendingMove(false); log(`MOVE: Displacement ${displacement.x},${displacement.y}.`); return
    }
    if (draft) {
      const p = parsePoint(value, draft.first)
      const next = p || (draft.tool === 'circle' && draft.first && !value.includes(',') ? Number(value) : null)
      if (next === null || (typeof next === 'number' && !Number.isFinite(next))) log('Invalid coordinate. Enter X,Y, @DX,DY, or a circle radius.')
      else applyPoint(next)
      return
    }
    log(`Unknown command "${value}". ${COMMAND_HELP}`)
  }

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      const isField = event.target instanceof HTMLElement && ['INPUT', 'TEXTAREA', 'SELECT'].includes(event.target.tagName)
      if (event.key === 'Escape') { if (modal) setModal(null); else { cancel(); setSelectedId(null) }; return }
      if (modal) return
      if ((event.ctrlKey || event.metaKey) && !isField) {
        if (event.key.toLowerCase() === 'z') { event.preventDefault(); setHistory(event.shiftKey ? redo : undo); setDraft(null) }
        if (event.key.toLowerCase() === 'y') { event.preventDefault(); setHistory(redo); setDraft(null) }
      }
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') { event.preventDefault(); save() }
      if (isField) return
      if (event.key === 'Delete' || event.key === 'Backspace') { event.preventDefault(); erase() }
      if (event.key === 'F3') { event.preventDefault(); setOsnap(s => !s) }
      if (event.key === 'F7') { event.preventDefault(); setGrid(s => !s) }
      if (event.key === 'F8') { event.preventDefault(); setOrtho(s => !s) }
      if (event.key === 'F9') { event.preventDefault(); setSnap(s => !s) }
      if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) { commandRef.current?.focus(); setInput(old => old + event.key); event.preventDefault() }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [cancel, erase, modal, save])

  const worldPoint = (clientX: number, clientY: number, constrain = true): Point => {
    const rect = canvasRef.current!.getBoundingClientRect()
    let point = { x: view.x + (clientX - rect.left) / rect.width * view.width, y: -(view.y + (clientY - rect.top) / rect.height * view.height) }
    if (constrain && snap) point = snapPoint(point)
    if (constrain && osnap) {
      const tolerance = view.width / size.width * 12
      let nearest = tolerance
      for (const e of drawing.entities) {
        if (!drawing.layers.find(l => l.id === e.layer)?.visible) continue
        for (const p of controlPoints(e)) { const d = distance(point, p); if (d < nearest) { point = p; nearest = d } }
      }
    }
    if (constrain && ortho && draft?.first) {
      const a = draft.first
      point = Math.abs(point.x - a.x) > Math.abs(point.y - a.y) ? { x: point.x, y: a.y } : { x: a.x, y: point.y }
    }
    return { x: round(point.x), y: round(point.y) }
  }
  const preview = draft?.first ? createGeometry(draft, cursor, drawing.currentLayer, 'preview') : null
  const zoom = (factor: number) => setView(v => zoomView(v, factor, { x: v.x + v.width / 2, y: v.y + v.height / 2 }))
  const visibleCount = drawing.entities.filter(e => drawing.layers.find(l => l.id === e.layer)?.visible).length
  const selectedAnchor = selected ? anchor(selected) : null
  const prompt = pendingMove ? 'Specify displacement DX,DY:' : draft ? `${TOOL_NAMES[draft.tool]}  ${draft.first ? draft.tool === 'circle' ? 'Specify radius:' : 'Specify next point:' : 'Specify first point:'}` : 'Type a command'

  return <div className="app">
    <header className="titlebar">
      <button className="app-menu" onClick={() => setModal('export')} title="Draev application menu">D<ChevronDown size={10} /></button>
      <div className="quick-access">
        <button title="Reset sample drawing" aria-label="Reset sample drawing" onClick={() => setModal('reset')}><FilePlus2 /></button>
        <button title="Open Draev project" aria-label="Open Draev project" onClick={() => importRef.current?.click()}><FolderOpen /></button>
        <button title="Save locally (Ctrl+S)" aria-label="Save locally" onClick={save}><Save /></button>
        <button title="Undo (Ctrl+Z)" aria-label="Undo" disabled={!history.past.length} onClick={() => { setHistory(undo); setDraft(null) }}><Undo2 /></button>
        <button title="Redo (Ctrl+Y)" aria-label="Redo" disabled={!history.future.length} onClick={() => { setHistory(redo); setDraft(null) }}><Redo2 /></button>
        <span className="quick-separator" /><button title="Export drawing" aria-label="Export drawing" onClick={() => setModal('export')}><ArrowDownToLine /></button>
      </div>
      <div className="window-title">Draev <span>2025</span><i />{drawing.title.replaceAll(' ', '_')}.draev</div>
      <div className="title-right"><span className="local-dot" />Local workspace<button onClick={() => setModal('help')} title="Help" aria-label="Help"><HelpCircle size={15} /></button></div>
    </header>
    <nav className="ribbon-tabs" aria-label="Ribbon tabs">
      {['Home', 'Insert', 'Annotate', 'Parametric', 'View', 'Manage', 'Output', 'Collaborate', 'Express Tools'].map(tab => <button key={tab} className={ribbonTab === tab ? 'active' : ''} disabled={['Parametric', 'Collaborate', 'Express Tools'].includes(tab)} title={['Parametric', 'Collaborate', 'Express Tools'].includes(tab) ? 'Outside this V1' : tab} onClick={() => setRibbonTab(tab)}>{tab}</button>)}
      <span className="ribbon-end">Drafting & Annotation <ChevronDown size={12} /></span>
    </nav>
    <div className="ribbon">
      {ribbonTab === 'Home' && <>
        <RibbonGroup title="Draw">
          <Tool icon={Slash} label="Line" active={draft?.tool === 'line'} onClick={() => startTool('line')} hint="LINE — specify two points (L)" />
          <Tool icon={Square} label="Rectangle" active={draft?.tool === 'rect'} onClick={() => startTool('rect')} />
          <Tool icon={CircleIcon} label="Circle" active={draft?.tool === 'circle'} onClick={() => startTool('circle')} />
          <div className="tool-stack"><Tool icon={RotateCw} label="Arc" compact disabled /><Tool icon={Grid2X2} label="Hatch" compact onClick={() => selected?.type === 'rect' ? updateSelected(e => e.type === 'rect' ? { ...e, hatch: !e.hatch } : e) : log('HATCH: Select a rectangle to toggle its hatch fill.')} /><Tool icon={ChevronDown} label="Polyline" compact disabled /></div>
        </RibbonGroup>
        <RibbonGroup title="Modify">
          <div className="tool-stack"><Tool icon={Move} label="Move" compact onClick={() => { runCommand('MOVE'); commandRef.current?.focus() }} /><Tool icon={Copy} label="Copy" compact onClick={copy} /><Tool icon={Trash2} label="Erase" compact onClick={erase} /></div>
          <div className="tool-stack secondary-tools"><Tool icon={RotateCw} label="Rotate" compact disabled /><Tool icon={ArrowLeftRight} label="Mirror" compact disabled /><Tool icon={Maximize} label="Scale" compact disabled /></div>
        </RibbonGroup>
        <RibbonGroup title="Annotation"><Tool icon={Type} label="Text" onClick={() => setModal('text')} /><Tool icon={Ruler} label="Measure" onClick={() => { if (selected?.type === 'line') log(`DISTANCE: ${round(distance({ x: selected.x1, y: selected.y1 }, { x: selected.x2, y: selected.y2 }))} mm`); else if (selected?.type === 'rect') log(`AREA: ${round(selected.width * selected.height / 1e6)} m²; perimeter ${2 * (selected.width + selected.height)} mm`); else log('MEASURE: Select a line or rectangle; results appear in the command history.') }} /></RibbonGroup>
        <RibbonGroup title="Layers" className="layers-ribbon">
          <Tool icon={Layers} label="Layer Properties" onClick={() => setShowPalette(s => !s)} />
          <div className="layer-ribbon-controls"><label className="ribbon-layer-select"><Lightbulb size={14} /><span style={{ background: currentLayer.color }} /><select aria-label="Current layer" value={drawing.currentLayer} onChange={e => change(d => ({ ...d, currentLayer: e.target.value }))}>{drawing.layers.map(l => <option key={l.id} value={l.id}>{l.name}</option>)}</select></label><div className="layer-tools"><Eye size={15} /><UnlockKeyhole size={14} /><Layers size={14} /><span>ByLayer</span></div><button className="make-current" disabled={!selected} onClick={() => selected && change(d => ({ ...d, currentLayer: selected.layer }))}><ArrowUpRight size={15} />Make Current</button></div>
        </RibbonGroup>
        <RibbonGroup title="Properties" className="properties-ribbon"><div className="bylayer"><span style={{ background: selectedLayer?.color || currentLayer.color }} />ByLayer<ChevronDown size={12} /></div><div className="bylayer"><span className="line-sample" />Continuous<ChevronDown size={12} /></div><div className="bylayer"><span className="line-sample thick" />ByLayer<ChevronDown size={12} /></div></RibbonGroup>
        <RibbonGroup title="Clipboard"><Tool icon={FileJson} label="Project" onClick={() => exportFile('json')} /><Tool icon={Download} label="Export" onClick={() => setModal('export')} /></RibbonGroup>
      </>}
      {ribbonTab === 'View' && <>
        <RibbonGroup title="Navigate"><Tool icon={Hand} label="Pan" onClick={() => { setPanMode(p => !p); setDraft(null) }} active={panMode} /><Tool icon={ZoomIn} label="Zoom In" onClick={() => zoom(.8)} /><Tool icon={ZoomOut} label="Zoom Out" onClick={() => zoom(1.25)} /><Tool icon={Maximize} label="Extents" onClick={fit} /></RibbonGroup>
        <RibbonGroup title="Display"><Tool icon={Grid2X2} label="Grid" active={grid} onClick={() => setGrid(v => !v)} /><Tool icon={Layers} label="Lineweights" active={lineweights} onClick={() => setLineweights(v => !v)} /><Tool icon={PanelRightClose} label="Palettes" active={showPalette} onClick={() => setShowPalette(v => !v)} /></RibbonGroup>
        <RibbonGroup title="Viewports"><Tool icon={Square} label="Model" active={layout === 'Model'} onClick={() => { setLayout('Model'); fit() }} /><Tool icon={FileText} label="A-101" active={layout === 'A-101'} onClick={() => { setLayout('A-101'); fit() }} /></RibbonGroup>
      </>}
      {ribbonTab === 'Insert' && <><RibbonGroup title="Project"><Tool icon={FolderOpen} label="Open project" onClick={() => importRef.current?.click()} /><Tool icon={FileJson} label="Save project" onClick={() => exportFile('json')} /></RibbonGroup><RibbonGroup title="Objects"><Tool icon={Copy} label="Copy selected" onClick={copy} /><Tool icon={Type} label="Text" onClick={() => setModal('text')} /></RibbonGroup><div className="ribbon-note">Import a Draev JSON project.<br />Native DWG, external references and blocks are outside this V1.</div></>}
      {ribbonTab === 'Annotate' && <><RibbonGroup title="Text"><Tool icon={Type} label="Single-line text" onClick={() => setModal('text')} /></RibbonGroup><div className="ribbon-note">Select a line or rectangle to inspect exact dimensions in Properties.<br />The sample’s dimension chains are editable lines and text.</div></>}
      {ribbonTab === 'Manage' && <><RibbonGroup title="Drawing"><Tool icon={Save} label="Save locally" onClick={save} /><Tool icon={FileInput} label="Import project" onClick={() => importRef.current?.click()} /><Tool icon={RotateCw} label="Reset sample" onClick={() => setModal('reset')} /><Tool icon={HelpCircle} label="Command guide" onClick={() => setModal('help')} /></RibbonGroup><div className="ribbon-note">Millimeters · World coordinate system · Local autosave<br />{drawing.entities.length.toLocaleString()} entities across {drawing.layers.length} layers</div></>}
      {ribbonTab === 'Output' && <><RibbonGroup title="Export"><Tool icon={FileText} label="SVG drawing" onClick={() => exportFile('svg')} /><Tool icon={File} label="DXF drawing" onClick={() => exportFile('dxf')} /><Tool icon={FileJson} label="Project JSON" onClick={() => exportFile('json')} /></RibbonGroup><div className="ribbon-note">SVG exports visible layers. DXF exports all supported entities with layer visibility.<br />Project JSON preserves editable geometry, colors and layer state.</div></>}
    </div>
    <div className="document-tabs"><Menu size={15} /><button className="start-tab" onClick={() => setModal('help')}>Start</button><button className="document active" onClick={() => { setLayout('Model'); fit() }}>{drawing.title.replaceAll(' ', '_')}<span className="file-dot" /> <span className="doc-extension">.draev</span></button><button title="Add a text annotation" aria-label="Add a text annotation" className="new-tab" onClick={() => setModal('text')}><Plus size={16} /></button><span className="document-state">{saveError ? 'Storage unavailable — export a backup' : 'All changes saved locally'}</span></div>
    <main className="workspace">
      <div className="drawing-column">
        <div className={`viewport ${panMode ? 'panning' : ''} ${layout === 'A-101' ? 'paper' : ''}`} ref={viewportRef}>
          <div className="viewport-label"><span>[−]</span><button onClick={fit} title="Top view / fit drawing">[Top]</button><span>[2D Wireframe]</span></div>
          <div className="viewcube"><span className="north">N</span><span className="west">W</span><button title="Top view — zoom extents" onClick={fit}>TOP</button><span className="east">E</span><span className="south">S</span><button className="wcs" onClick={fit}>WCS <ChevronDown size={9} /></button></div>
          <div className="navigation-bar"><button aria-label="Zoom extents" title="Zoom extents" onClick={fit}><Maximize /></button><button aria-label="Pan view" title="Pan (or middle-button drag)" className={panMode ? 'active' : ''} onClick={() => { setPanMode(v => !v); setDraft(null) }}><Hand /></button><button aria-label="Zoom in" title="Zoom in" onClick={() => zoom(.8)}><ZoomIn /></button><button aria-label="Zoom out" title="Zoom out" onClick={() => zoom(1.25)}><ZoomOut /></button></div>
          <svg ref={canvasRef} className={`drawing-svg ${draft || panMode ? 'drawing-mode' : ''}`} data-testid="drawing-canvas" aria-label="Courtyard residence drafting canvas" viewBox={`${view.x} ${view.y} ${view.width} ${view.height}`} onWheel={event => {
            const p = worldPoint(event.clientX, event.clientY, false)
            setView(v => zoomView(v, event.deltaY > 0 ? 1.12 : .89, { x: p.x, y: -p.y }))
          }} onPointerDown={event => {
            if (event.button !== 0 && event.button !== 1) return
            const p = worldPoint(event.clientX, event.clientY)
            if (event.button === 1 || panMode) { event.preventDefault(); pan.current = { start: { x: event.clientX, y: event.clientY }, view }; event.currentTarget.setPointerCapture(event.pointerId); return }
            if (draft) { applyPoint(p); return }
            const target = event.target instanceof Element ? event.target.closest('[data-entity]') : null
            const id = target?.getAttribute('data-entity')
            const entity = drawing.entities.find(e => e.id === id)
            if (entity && !drawing.layers.find(l => l.id === entity.layer)?.locked) {
              setSelectedId(entity.id)
              if (event.target instanceof Element && event.target.hasAttribute('data-grip')) {
                drag.current = { start: p, entity }; event.currentTarget.setPointerCapture(event.pointerId)
              }
            } else setSelectedId(null)
            commandRef.current?.blur()
          }} onPointerMove={event => {
            const point = worldPoint(event.clientX, event.clientY)
            setCursor(point)
            const rect = event.currentTarget.getBoundingClientRect()
            setCursorPixel({ x: event.clientX - rect.left, y: event.clientY - rect.top })
            if (pan.current) {
              const { start, view: v } = pan.current
              setView({ ...v, x: v.x - (event.clientX - start.x) / rect.width * v.width, y: v.y - (event.clientY - start.y) / rect.height * v.height })
            }
            if (drag.current) {
              const d = drag.current
              const moved = moveEntity(d.entity, point.x - d.start.x, point.y - d.start.y)
              latestDrag.current = moved; setDragEntity(moved)
            }
          }} onPointerUp={event => {
            pan.current = null
            if (drag.current && latestDrag.current) { const moved = latestDrag.current; change(d => ({ ...d, entities: d.entities.map(e => e.id === moved.id ? moved : e) })); log('MOVE: Object relocated by grip.') }
            drag.current = null; latestDrag.current = null; setDragEntity(null)
            if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId)
          }} onPointerCancel={() => { pan.current = null; drag.current = null; latestDrag.current = null; setDragEntity(null) }} onPointerLeave={() => setCursorPixel(null)} onDoubleClick={event => { if (!(event.target instanceof Element) || !event.target.closest('[data-entity]')) fit() }} onContextMenu={event => { event.preventDefault(); cancel() }}>
            <defs>
              <pattern id="minor-grid" width="250" height="250" patternUnits="userSpaceOnUse"><path d="M250 0H0V250" fill="none" stroke="#2b353e" strokeWidth={view.width / size.width * .5} /></pattern>
              <pattern id="major-grid" width="1000" height="1000" patternUnits="userSpaceOnUse"><path d="M1000 0H0V1000" fill="none" stroke="#35404a" strokeWidth={view.width / size.width * .65} /></pattern>
              <pattern id="wall-hatch" width="140" height="140" patternUnits="userSpaceOnUse"><path d="M0 140L140 0" fill="none" stroke={layout === 'Model' ? '#89979d' : '#78818a'} strokeWidth="12" opacity=".42" /></pattern>
            </defs>
            {grid && layout === 'Model' && <g pointerEvents="none"><rect x={view.x} y={view.y} width={view.width} height={view.height} fill="url(#minor-grid)" /><rect x={view.x} y={view.y} width={view.width} height={view.height} fill="url(#major-grid)" /></g>}
            {layout === 'A-101' && <g pointerEvents="none"><rect x="-750" y="-23250" width="33300" height="24700" fill="#f7f7f4" stroke="#777" strokeWidth="15" /><rect x="-300" y="-22800" width="32400" height="23800" fill="none" stroke="#666" strokeWidth="12" /></g>}
            <g className="entities" fill="none" strokeLinecap="square" strokeLinejoin="miter">
              {drawing.entities.map(e => {
                const layer = drawing.layers.find(l => l.id === e.layer)!
                if (!layer.visible) return null
                const isSelected = e.id === selectedId
                const entity = dragEntity?.id === e.id ? dragEntity : e
                const color = isSelected ? '#63c5ff' : layout === 'A-101' && ['walls', 'text', 'furniture'].includes(layer.id) ? '#3c484d' : layer.color
                return <g key={e.id} data-entity={e.id} data-entity-type={e.type} className={`entity ${isSelected ? 'selected' : ''} ${layer.locked ? 'locked' : ''}`} color={color} stroke={color} strokeWidth={(lineweights ? layer.weight : .6) * view.width / size.width}><Shape entity={entity} /></g>
              })}
            </g>
            {selected && selectedLayer?.visible && !draft && <g data-entity={selected.id} fill="#63baff" stroke="#17232f" strokeWidth={view.width / size.width} className="grips">{controlPoints(dragEntity || selected).slice(0, 20).map((p, i) => <rect key={i} data-grip="true" x={p.x - view.width / size.width * 3.5} y={-p.y - view.width / size.width * 3.5} width={view.width / size.width * 7} height={view.width / size.width * 7} />)}</g>}
            {preview && <g stroke="#76d4ff" fill="none" strokeDasharray={`${view.width / size.width * 6} ${view.width / size.width * 4}`} strokeWidth={view.width / size.width} pointerEvents="none"><Shape entity={preview} /></g>}
            {draft?.first && <circle cx={draft.first.x} cy={-draft.first.y} r={view.width / size.width * 4} fill="none" stroke="#75e9a6" strokeWidth={view.width / size.width} />}
          </svg>
          {cursorPixel && !panMode && !pan.current && <div className="crosshair" style={{ left: cursorPixel.x, top: cursorPixel.y }}><i /><b /><span /></div>}
          {draft && <div className="dynamic-prompt"><Crosshair size={13} />{prompt} <span>{cursor.x.toFixed(0)}, {cursor.y.toFixed(0)}</span></div>}
          <div className="ucs"><svg viewBox="0 0 76 78"><path d="M19 12V60H68" fill="none" stroke="currentColor" /><path d="M15 18L19 12L23 18M62 56L68 60L62 64" fill="none" stroke="currentColor" /><rect x="15" y="56" width="8" height="8" fill="none" stroke="currentColor" /><text x="10" y="9">Y</text><text x="65" y="76">X</text></svg><span>WCS</span></div>
          <div className="drawing-badge"><span />{layout === 'Model' ? 'MODEL SPACE' : 'PAPER SPACE'}<b>1:100</b></div>
        </div>
        <div className="command-area">
          <div className="command-grip"><Grip size={12} /></div>
          <div className="command-main"><div className="command-log" aria-live="polite">{logs.slice(-2).map((message, i) => <div key={`${logs.length}-${i}`}><span>Command:</span> {message}</div>)}</div>
            <form onSubmit={event => { event.preventDefault(); runCommand(input) }}><ChevronRight size={16} /><span className="command-prefix">{draft ? TOOL_NAMES[draft.tool] : 'Command'}</span><input ref={commandRef} aria-label="Command line" autoComplete="off" spellCheck={false} value={input} placeholder={prompt} onChange={e => setInput(e.target.value)} onKeyDown={e => {
              if (e.key === 'ArrowUp') { e.preventDefault(); const next = Math.min(historyIndex + 1, commandHistory.length - 1); setHistoryIndex(next); setInput(commandHistory[next] || '') }
              if (e.key === 'ArrowDown') { e.preventDefault(); const next = Math.max(-1, historyIndex - 1); setHistoryIndex(next); setInput(next < 0 ? '' : commandHistory[next] || '') }
            }} /><button type="button" title="Command guide" onClick={() => setModal('help')}><ChevronDown size={13} /></button></form>
          </div>
        </div>
      </div>
      {showPalette && <aside className="palette">
        <div className="palette-title"><span>PROPERTIES</span><div><button aria-label="Properties help" title="Properties help" onClick={() => setModal('help')}><HelpCircle size={12} /></button><button aria-label="Hide palettes" title="Hide palettes" onClick={() => setShowPalette(false)}><X size={13} /></button></div></div>
        <div className="selection-heading"><span>{selected ? selected.type.charAt(0).toUpperCase() + selected.type.slice(1) : 'No selection'}</span><MousePointer2 size={15} /></div>
        <div className="property-section-title"><ChevronDown size={12} />General</div>
        <label className="property-row"><span>Color</span><span className="property-value"><i style={{ background: selectedLayer?.color || currentLayer.color }} />ByLayer</span></label>
        <label className="property-row"><span>Layer</span><select aria-label="Selected object layer" disabled={!selected || selectedLayer?.locked} value={selected?.layer || drawing.currentLayer} onChange={e => updateSelected(entity => ({ ...entity, layer: e.target.value }))}>{drawing.layers.map(l => <option key={l.id} value={l.id}>{l.name}</option>)}</select></label>
        <div className="property-row"><span>Linetype</span><span className="property-value">Continuous</span></div>
        <div className="property-row"><span>Lineweight</span><span className="property-value">ByLayer</span></div>
        <div className="property-section-title"><ChevronDown size={12} />{selected ? 'Geometry' : 'Drawing'}</div>
        <div className="geometry-fields">
          {selected && selectedAnchor ? <fieldset disabled={selectedLayer?.locked}>
            <NumberField label="Position X" value={selectedAnchor.x} onChange={x => updateSelected(e => moveEntity(e, x - anchor(e).x, 0))} />
            <NumberField label="Position Y" value={selectedAnchor.y} onChange={y => updateSelected(e => moveEntity(e, 0, y - anchor(e).y))} />
            {selected.type === 'rect' && <><NumberField label="Width" positive value={selected.width} onChange={width => updateSelected(e => e.type === 'rect' ? { ...e, width } : e)} /><NumberField label="Height" positive value={selected.height} onChange={height => updateSelected(e => e.type === 'rect' ? { ...e, height } : e)} /><div className="property-row"><span>Area</span><span className="property-value">{round(selected.width * selected.height / 1e6)} m²</span></div></>}
            {selected.type === 'line' && <><NumberField label="End X" value={selected.x2} onChange={x2 => updateSelected(e => e.type === 'line' ? { ...e, x2 } : e)} /><NumberField label="End Y" value={selected.y2} onChange={y2 => updateSelected(e => e.type === 'line' ? { ...e, y2 } : e)} /><div className="property-row"><span>Length</span><span className="property-value">{round(distance({ x: selected.x1, y: selected.y1 }, { x: selected.x2, y: selected.y2 }))} mm</span></div></>}
            {(selected.type === 'circle' || selected.type === 'arc') && <NumberField label="Radius" positive value={selected.radius} onChange={radius => updateSelected(e => e.type === 'circle' || e.type === 'arc' ? { ...e, radius } : e)} />}
            {selected.type === 'text' && <><label className="property-row"><span>Text</span><input key={`${selected.id}-${selected.text}`} aria-label="Text content" defaultValue={selected.text} maxLength={2000} onBlur={event => updateSelected(e => e.type === 'text' ? { ...e, text: event.target.value } : e)} /></label><NumberField label="Text height" positive value={selected.size} onChange={size => updateSelected(e => e.type === 'text' ? { ...e, size } : e)} /></>}
            <div className="selection-actions"><button onClick={copy}><Copy size={12} />Copy</button><button onClick={erase}><Eraser size={12} />Erase</button></div>
          </fieldset> : <><div className="property-row"><span>Units</span><span className="property-value">Millimeters</span></div><div className="property-row"><span>Coordinates</span><span className="property-value">World (WCS)</span></div><div className="property-row"><span>Objects</span><span className="property-value" data-testid="entity-count">{drawing.entities.length.toLocaleString()}</span></div><div className="property-row"><span>View</span><span className="property-value">Top / 2D Wireframe</span></div></>}
        </div>
        <div className="palette-title layer-title"><span>LAYER PROPERTIES</span><Layers size={13} /></div>
        <div className="layer-filter"><Search size={13} /><input placeholder="Search layers" aria-label="Search layers" value={layerSearch} onChange={e => setLayerSearch(e.target.value)} /><span>{drawing.layers.length}</span></div>
        <div className="layer-table-head"><span>On</span><span>Lock</span><span>Color</span><span>Name</span></div>
        <div className="layer-table">{drawing.layers.filter(l => l.name.toLowerCase().includes(layerSearch.toLowerCase())).map(l => <div className={`layer-row ${l.id === drawing.currentLayer ? 'current' : ''} ${!l.visible ? 'hidden-layer' : ''}`} key={l.id}>
          <button aria-label={`${l.visible ? 'Hide' : 'Show'} ${l.name}`} title={`${l.visible ? 'Hide' : 'Show'} ${l.name}`} onClick={() => change(d => ({ ...d, layers: d.layers.map(layer => layer.id === l.id ? { ...layer, visible: !layer.visible } : layer) }))}>{l.visible ? <Lightbulb size={13} /> : <EyeOff size={13} />}</button>
          <button aria-label={`${l.locked ? 'Unlock' : 'Lock'} ${l.name}`} title={`${l.locked ? 'Unlock' : 'Lock'} ${l.name}`} onClick={() => change(d => ({ ...d, layers: d.layers.map(layer => layer.id === l.id ? { ...layer, locked: !layer.locked } : layer) }))}>{l.locked ? <LockKeyhole size={12} /> : <UnlockKeyhole size={12} />}</button>
          <input type="color" aria-label={`${l.name} color`} title={`${l.name} color`} value={l.color} onChange={event => change(d => ({ ...d, layers: d.layers.map(layer => layer.id === l.id ? { ...layer, color: event.target.value } : layer) }))} />
          <button className="layer-name" title={`Set ${l.name} current`} onClick={() => change(d => ({ ...d, currentLayer: l.id }))}>{l.name}{l.id === drawing.currentLayer && <span>✓</span>}</button>
        </div>)}</div>
        <div className="layer-footer"><span>{visibleCount.toLocaleString()} visible objects</span><span>{drawing.layers.filter(l => l.visible).length} / {drawing.layers.length} layers</span></div>
        <div className="project-footer"><span className="project-number">CR—01</span><div>COURTYARD RESIDENCE<small>Architectural · Ground floor</small></div></div>
      </aside>}
    </main>
    <footer className="statusbar">
      <div className="layout-tabs"><Menu size={14} />{(['Model', 'A-101'] as const).map(tab => <button className={layout === tab ? 'active' : ''} key={tab} onClick={() => { setLayout(tab); fit() }}>{tab === 'A-101' ? 'Layout1 · A-101' : tab}</button>)}</div>
      <span className="coordinates">{cursor.x.toFixed(0)}, {cursor.y.toFixed(0)}, 0</span><span className="status-mode">{layout === 'Model' ? 'MODEL' : 'PAPER'}</span>
      <div className="drafting-toggles"><button className={grid ? 'active' : ''} title="Grid display (F7)" aria-label="Grid display" aria-pressed={grid} onClick={() => setGrid(v => !v)}><Grid2X2 /></button><button className={snap ? 'active' : ''} title="Grid snap · 100 mm (F9)" aria-label="Grid snap" aria-pressed={snap} onClick={() => setSnap(v => !v)}><Grip /></button><button className={ortho ? 'active' : ''} title="Ortho mode (F8)" aria-label="Ortho mode" aria-pressed={ortho} onClick={() => setOrtho(v => !v)}><span className="ortho-icon">∟</span></button><button className={osnap ? 'active' : ''} title="Object snap (F3)" aria-label="Object snap" aria-pressed={osnap} onClick={() => setOsnap(v => !v)}><Crosshair /></button><button className={lineweights ? 'active' : ''} title="Display lineweights" aria-label="Display lineweights" aria-pressed={lineweights} onClick={() => setLineweights(v => !v)}><Layers /></button></div>
      <span className="status-scale">1:100 <ChevronDown size={10} /></span><button className={showPalette ? 'active' : ''} title="Toggle palettes" aria-label="Toggle palettes" onClick={() => setShowPalette(v => !v)}><PanelRightClose size={15} /></button><button title="Drafting settings / help" aria-label="Drafting settings" onClick={() => setModal('help')}><Settings size={15} /></button><span className="status-unit">mm</span>
    </footer>
    <input ref={importRef} type="file" hidden accept=".json,application/json" onChange={async event => {
      const file = event.target.files?.[0]
      if (!file) return
      if (file.size > 6_000_000) log('OPEN: Project exceeds the 6 MB limit.')
      else {
        try { const parsed = parseDrawing(await file.text()); if (parsed) { change(() => parsed); setSelectedId(null); setDraft(null); setView(fitView(parsed.entities, size.width / size.height)); log(`OPEN: ${parsed.title}, ${parsed.entities.length} objects loaded.`) } else log('OPEN: Invalid Draev project. Current drawing was not changed.') }
        catch { log('OPEN: Could not read the file. Current drawing was not changed.') }
      }
      event.target.value = ''
    }} />
    <dialog ref={dialogRef} className="dialog" onCancel={() => setModal(null)} onClick={event => { if (event.target === event.currentTarget) setModal(null) }}>
      <div className="dialog-title"><span>{modal === 'help' ? 'Draev · Drafting reference' : modal === 'reset' ? 'Restore courtyard residence' : modal === 'text' ? 'Single-line text' : 'Export drawing'}</span><button aria-label="Close dialog" onClick={() => setModal(null)}><X size={17} /></button></div>
      {modal === 'help' && <div className="dialog-body help-body"><div className="help-brand">D<span>DRAEV<small>PRECISION, IN EVERY LINE.</small></span></div><p>A local drafting workspace. Draw in millimeters; X increases right, Y increases up. Every element of the residence is editable vector geometry.</p><table><tbody><tr><td>LINE 1000,1000 5000,1000</td><td>Draw a line; Enter ends it</td></tr><tr><td>RECTANGLE 1000,2000 4000,4000</td><td>Opposite corners</td></tr><tr><td>CIRCLE 8000,8000 750</td><td>Center, radius</td></tr><tr><td>@500,0</td><td>Relative to previous point</td></tr><tr><td>MOVE 500,0 / COPY / ERASE</td><td>Modify the selection</td></tr><tr><td>Wheel / middle-button drag</td><td>Zoom / pan</td></tr><tr><td>F3 / F7 / F8 / F9</td><td>Object snap / grid / ortho / grid snap</td></tr><tr><td>Ctrl+Z / Ctrl+Y / Ctrl+S</td><td>Undo / redo / save</td></tr></tbody></table><p>Select an object to edit Properties. Drag a blue grip to move it. Layer bulbs toggle visibility, locks prevent editing, and swatches change color. Changes save locally; export Project JSON for a portable copy.</p><p className="muted">AutoCAD-inspired browser V1. Native DWG, 3D solids, parametric constraints, blocks and collaboration are unavailable. Source: Autodesk’s official desktop UI tour. Not affiliated with Autodesk.</p></div>}
      {modal === 'reset' && <div className="dialog-body"><p>Replace the current drawing with the original courtyard residence?</p><p className="muted">You can undo this action. Export a Project JSON first if you want to keep a separate copy.</p><div className="dialog-actions"><button onClick={() => setModal(null)}>Cancel</button><button className="primary" onClick={() => { const d = createResidence(); change(() => d); setDraft(null); setSelectedId(null); setLayout('Model'); setView(fitView(d.entities, size.width / size.height)); setModal(null); log('Sample restored. Undo is available.') }}>Restore sample</button></div></div>}
      {modal === 'export' && <div className="dialog-body"><p className="muted">{drawing.title} · {drawing.entities.length.toLocaleString()} objects</p><button className="export-option" onClick={() => exportFile('svg')}><FileText /><span>SVG drawing<small>Visible layers · editable vector artwork</small></span><Download size={17} /></button><button className="export-option" onClick={() => exportFile('dxf')}><File /><span>DXF drawing<small>ASCII geometry · millimeters · all layers</small></span><Download size={17} /></button><button className="export-option" onClick={() => exportFile('json')}><FileJson /><span>Draev project<small>Lossless JSON · geometry, colors and layer state</small></span><Download size={17} /></button></div>}
      {modal === 'text' && <form className="dialog-body" onSubmit={event => {
        event.preventDefault()
        const p = parsePoint(notePosition)
        if (!p) return
        if (!currentLayer.visible || currentLayer.locked) { log('TEXT: Choose a visible, unlocked current layer.'); return }
        const entity: Entity = { id: crypto.randomUUID(), type: 'text', layer: drawing.currentLayer, ...p, text: noteText, size: 250, angle: 0 }
        change(d => ({ ...d, entities: [...d.entities, entity] })); setSelectedId(entity.id); setModal(null); setNoteText(''); log('TEXT: Annotation created.')
      }}><label className="form-label">Text<input autoFocus required maxLength={2000} aria-label="Annotation text" value={noteText} onChange={e => setNoteText(e.target.value)} /></label><label className="form-label">Insertion point (X,Y mm)<input required aria-label="Text insertion point" value={notePosition} onChange={e => setNotePosition(e.target.value)} /></label>{!parsePoint(notePosition) && <p className="error">Enter a coordinate such as 15000,1200.</p>}<div className="dialog-actions"><button type="button" onClick={() => setModal(null)}>Cancel</button><button className="primary" disabled={!parsePoint(notePosition)}>Place text</button></div></form>}
    </dialog>
  </div>
}
