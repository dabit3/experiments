import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Icon } from './Icon'
import type { IconName } from './Icon'
import { Viewport } from './Viewport'
import type { ViewName } from './Viewport'
import { commit, createMuseum, extrudeCurve, freshEntity, loftCurves, parseProject, redo, serializeProject, STORAGE_KEY, undo, updateEntity } from './model'
import type { Entity, History, Layer, Point, Project } from './model'
import { exportOBJ } from './scene'
import type { DisplayMode } from './scene'

const views: ViewName[] = ['Top', 'Perspective', 'Front', 'Right']
type Action = 'new' | 'open' | 'save' | 'undo' | 'redo' | 'select' | 'curve' | 'points' | 'extrude' | 'loft' | 'move' | 'rotate' | 'scale' | 'fit' | 'orbit' | 'grid' | 'cube' | 'layers' | 'export' | 'delete' | 'four' | 'settings' | 'sun' | 'info' | 'copy'
type ToolButton = { action: Action; label: string; icon: IconName; disabled?: boolean }
const tools: ToolButton[] = [
  { action: 'new', label: 'Reset museum', icon: 'new' }, { action: 'open', label: 'Open project', icon: 'open' },
  { action: 'save', label: 'Save project', icon: 'save' }, { action: 'export', label: 'Export geometry (OBJ)', icon: 'export' },
  { action: 'undo', label: 'Undo (Ctrl+Z)', icon: 'undo' }, { action: 'redo', label: 'Redo (Ctrl+Y)', icon: 'redo' },
  { action: 'select', label: 'Select objects', icon: 'select' }, { action: 'fit', label: 'Zoom extents', icon: 'fit' },
  { action: 'orbit', label: 'Perspective view', icon: 'orbit' }, { action: 'four', label: 'Four viewports', icon: 'four' },
  { action: 'curve', label: 'Draw curve', icon: 'curve' }, { action: 'points', label: 'Control points (F10)', icon: 'points' },
  { action: 'extrude', label: 'Extrude curve', icon: 'extrude' }, { action: 'loft', label: 'Loft two curves', icon: 'loft' },
  { action: 'move', label: 'Move object', icon: 'move' }, { action: 'rotate', label: 'Rotate object', icon: 'rotate' },
  { action: 'scale', label: 'Scale object', icon: 'scale' }, { action: 'copy', label: 'Duplicate object', icon: 'copy' },
  { action: 'grid', label: 'Toggle construction grid', icon: 'grid' }, { action: 'cube', label: 'Shaded display', icon: 'cube' },
  { action: 'sun', label: 'Rendered display', icon: 'sun' }, { action: 'layers', label: 'Layers panel', icon: 'layers' },
  { action: 'delete', label: 'Delete selection', icon: 'delete' }, { action: 'info', label: 'Rhova help', icon: 'info' },
]
const menuActions: Record<string, Action[]> = {
  File: ['new', 'open', 'save', 'export'], Edit: ['undo', 'redo', 'copy', 'delete'],
  View: ['fit', 'four', 'orbit', 'grid', 'cube', 'sun'], Curve: ['curve', 'points'],
  Surface: ['loft', 'extrude'], Solid: ['extrude'], Mesh: ['export'],
  Transform: ['move', 'rotate', 'scale', 'copy'], Tools: ['points', 'layers', 'settings'],
  Analyze: ['settings'], Render: ['sun', 'cube'], Window: ['four', 'layers'], Help: ['info'],
}
const tabs = ['Standard', 'CPlanes', 'Set View', 'Display', 'Select', 'Viewport Layout', 'Transform', 'Curve Tools', 'Surface Tools', 'Solid Tools', 'Mesh Tools', 'Render Tools']
const categoryActions: Record<string, Action[]> = {
  CPlanes: ['grid', 'four', 'fit'], 'Set View': ['orbit', 'four', 'fit'],
  Display: ['cube', 'sun', 'grid'], Select: ['select', 'points', 'delete'],
  'Viewport Layout': ['four', 'orbit', 'fit'], Transform: ['move', 'rotate', 'scale', 'copy'],
  'Curve Tools': ['curve', 'points'], 'Surface Tools': ['extrude', 'loft'],
  'Solid Tools': ['extrude'], 'Mesh Tools': ['export'], 'Render Tools': ['sun', 'cube'],
}

function Numeric({ label, value, onChange, min = -1000, max = 1000, step = 0.5, disabled = false }: { label: string; value: number; onChange: (value: number) => void; min?: number; max?: number; step?: number; disabled?: boolean }) {
  return <label className="numeric"><span>{label}</span><input key={value} aria-label={label} type="number" min={min} max={max} step={step} defaultValue={Number(value.toFixed(3))} disabled={disabled} onBlur={event => {
    const next = event.currentTarget.valueAsNumber
    if (Number.isFinite(next) && next >= min && next <= max) onChange(next)
    else event.currentTarget.value = String(value)
  }} onKeyDown={event => { if (event.key === 'Enter') event.currentTarget.blur() }} /></label>
}
function download(name: string, text: string, mime: string) {
  const url = URL.createObjectURL(new Blob([text], { type: mime }))
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = name
  anchor.click()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
function initialHistory(): History {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    return { past: [], present: saved ? parseProject(saved) : createMuseum(), future: [] }
  } catch { return { past: [], present: createMuseum(), future: [] } }
}

export function App() {
  const [history, setHistory] = useState(initialHistory)
  const project = history.present
  const [selection, setSelection] = useState<string[]>([])
  const selected = useMemo(() => selection.filter(id => project.objects.some(object => object.id === id)), [selection, project])
  const object = project.objects.find(object => object.id === selected[0])
  const locked = project.layers.find(layer => layer.id === object?.layerId)?.locked ?? false
  const [activeView, setActiveView] = useState<ViewName>('Perspective')
  const [maximized, setMaximized] = useState<ViewName | null>(null)
  const [modes, setModes] = useState<Record<ViewName, DisplayMode>>({ Top: 'Wireframe', Perspective: 'Rendered', Front: 'Wireframe', Right: 'Wireframe' })
  const [toolbar, setToolbar] = useState('Standard')
  const [tool, setTool] = useState<'select' | 'curve'>('select')
  const [draft, setDraft] = useState<Point[]>([])
  const [showPoints, setShowPoints] = useState(false)
  const [pointIndex, setPointIndex] = useState<number | null>(null)
  const [fit, setFit] = useState(0)
  const [grid, setGrid] = useState(true)
  const [snap, setSnap] = useState(false)
  const [cursor, setCursor] = useState<Point>([0, 0, 0])
  const [commands, setCommands] = useState(['Aurelian Museum.3dm — concept study / 01', 'Model loaded. 6 objects · 6 layers · units: meters'])
  const [command, setCommand] = useState('')
  const [saveStatus, setSaveStatus] = useState('Saved locally')
  const [panel, setPanel] = useState<'Layers' | 'Properties'>('Layers')
  const [help, setHelp] = useState(false)
  const [resetPrompt, setResetPrompt] = useState(false)
  const [layerFilter, setLayerFilter] = useState('')
  const [extrusionHeight, setExtrusionHeight] = useState(5)
  const fileInput = useRef<HTMLInputElement>(null)
  const transformSection = useRef<HTMLDivElement>(null)
  const announce = useCallback((text: string) => setCommands(lines => [...lines.slice(-18), text]), [])
  const apply = useCallback((next: Project, description: string) => {
    setHistory(current => commit(current, next))
    announce(description)
  }, [announce])
  const editObject = (patch: Partial<Entity>, description = 'Object properties updated.') => {
    if (object && !locked) apply(updateEntity(project, object.id, patch), description)
  }
  const changeLayer = (id: string, patch: Partial<Layer>) => {
    apply({ ...project, layers: project.layers.map(layer => layer.id === id ? { ...layer, ...patch } : layer) }, 'Layer properties updated.')
  }
  const selectObject = (id: string | null, shift = false) => {
    setSelection(current => id === null ? [] : shift ? current.includes(id) ? current.filter(item => item !== id) : [...current, id] : [id])
    setPointIndex(null)
    if (id) announce(`Selected: ${project.objects.find(object => object.id === id)?.name}.`)
  }
  const finishCurve = () => {
    if (draft.length < 2) { announce('Curve requires at least two points. Click in an orthographic viewport.'); return }
    const newCurve = { ...freshEntity('curve', crypto.randomUUID(), 'design', `Curve ${project.objects.filter(object => object.kind === 'curve').length + 1}`), points: draft }
    const layer = project.layers.find(layer => layer.id === 'design') ?? project.layers[0]
    newCurve.layerId = layer.id
    if (layer.locked || !layer.visible) { announce('Unlock and show the design layer before creating a curve.'); return }
    apply({ ...project, objects: [...project.objects, newCurve] }, `Curve created with ${draft.length} control points.`)
    setSelection([newCurve.id]); setDraft([]); setTool('select'); setShowPoints(true)
  }
  const undoAction = () => { setHistory(undo); announce('Undo.'); setPointIndex(null) }
  const redoAction = () => { setHistory(redo); announce('Redo.'); setPointIndex(null) }
  const execute = (action: Action) => {
    if (action === 'new') setResetPrompt(true)
    if (action === 'open') fileInput.current?.click()
    if (action === 'save') {
      download(`${project.name}.rhova.json`, serializeProject(project), 'application/json')
      announce('Project saved as a Rhova JSON file.')
    }
    if (action === 'export') {
      download(`${project.name}.obj`, exportOBJ(project), 'text/plain')
      announce('Visible geometry exported as Wavefront OBJ. Units: meters.')
    }
    if (action === 'undo') undoAction()
    if (action === 'redo') redoAction()
    if (action === 'select') { setTool('select'); setDraft([]) }
    if (action === 'curve') {
      setTool('curve'); setDraft([]); setActiveView('Top'); if (maximized) setMaximized('Top')
      announce('Curve: click points in Top, Front or Right. Enter to finish · Esc to cancel.')
    }
    if (action === 'points') { setShowPoints(value => !value); setPanel('Properties'); announce('Control points: select a curve, then drag a point or edit its coordinates.') }
    if (action === 'extrude' || action === 'loft') {
      try {
        if (locked) throw new Error('Unlock the selected layer before editing.')
        const id = crypto.randomUUID()
        const surface = action === 'extrude' ? extrudeCurve(object ?? freshEntity('site', '', '', ''), extrusionHeight, id) : loftCurves(project.objects.filter(object => selected.includes(object.id)), id)
        surface.layerId = project.layers.find(layer => layer.id === 'design')?.id ?? project.layers[0].id
        const targetLayer = project.layers.find(layer => layer.id === surface.layerId)
        if (!targetLayer?.visible || targetLayer.locked) throw new Error('Show and unlock the design layer first.')
        apply({ ...project, objects: [...project.objects, surface] }, `${action === 'loft' ? 'Loft' : 'Extrusion'} created.`)
        setSelection([id]); setPanel('Properties'); setShowPoints(false)
      } catch (error) { announce(error instanceof Error ? error.message : 'Surface creation failed.') }
    }
    if (['move', 'rotate', 'scale'].includes(action)) {
      setPanel('Properties')
      announce(object ? 'Edit numeric transform values in Object properties.' : 'Select an object to transform.')
      setTimeout(() => { transformSection.current?.scrollIntoView({ block: 'nearest' }); transformSection.current?.querySelector('input')?.focus() }, 0)
    }
    if (action === 'copy' && object && !locked) {
      const copy = { ...object, id: crypto.randomUUID(), name: `${object.name.slice(0, 110)} copy`, position: [object.position[0] + 3, object.position[1], object.position[2]] as Point }
      apply({ ...project, objects: [...project.objects, copy] }, 'Object duplicated with a 3 m X offset.'); setSelection([copy.id])
    }
    if (action === 'delete') {
      const deletable = selected.filter(id => {
        const item = project.objects.find(object => object.id === id)
        return !project.layers.find(layer => layer.id === item?.layerId)?.locked
      })
      if (deletable.length) apply({ ...project, objects: project.objects.filter(object => !deletable.includes(object.id)) }, `${deletable.length} object(s) deleted.`)
      setSelection([])
    }
    if (action === 'grid') setGrid(value => !value)
    if (action === 'fit') setFit(value => value + 1)
    if (action === 'four') setMaximized(null)
    if (action === 'orbit') { setActiveView('Perspective'); setMaximized('Perspective') }
    if (action === 'cube' || action === 'sun') setModes(value => ({ ...value, [activeView]: action === 'cube' ? 'Shaded' : 'Rendered' }))
    if (action === 'layers') setPanel('Layers')
    if (action === 'settings') setPanel('Properties')
    if (action === 'info') setHelp(true)
  }

  const runCommand = () => {
    const [name, ...args] = command.trim().toLowerCase().split(/\s+/)
    const aliases: Record<string, Action> = { curve: 'curve', interpcrv: 'curve', pointson: 'points', extrudecrv: 'extrude', extrude: 'extrude', loft: 'loft', undo: 'undo', redo: 'redo', save: 'save', export: 'export', delete: 'delete', zoom: 'fit', '4view': 'four', help: 'info' }
    announce(`Command: ${command}`)
    if (name === 'move' && object && !locked && args.length === 3 && args.every(value => Number.isFinite(Number(value)) && Math.abs(Number(value)) <= 1000)) editObject({ position: object.position.map((value, i) => value + Number(args[i])) as Point }, 'Move complete.')
    else if (name === 'rotate' && object && !locked && args.length === 1 && Number.isFinite(Number(args[0]))) editObject({ rotation: Number(args[0]) % 360 }, 'Rotation complete.')
    else if (name === 'scale' && object && !locked && args.length === 1 && Number(args[0]) > 0 && Number(args[0]) <= 20) editObject({ scale: Number(args[0]) }, 'Scale complete.')
    else if (aliases[name]) execute(aliases[name])
    else announce('Supported: Curve, PointsOn, Extrude, Loft, Move x y z, Rotate degrees, Scale factor, Undo, Redo, Save, Export, 4View.')
    setCommand('')
  }
  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, serializeProject(project)); setSaveStatus('Saved locally') }
    catch { setSaveStatus('Local save unavailable — export your project') }
  }, [project])
  useEffect(() => {
    const handler = (event: KeyboardEvent) => {
      if (event.key === 'Escape') { setTool('select'); setDraft([]); setHelp(false); setResetPrompt(false); return }
      if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement || event.target instanceof HTMLSelectElement) return
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'z') { event.preventDefault(); if (event.shiftKey) redoAction(); else undoAction() }
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'y') { event.preventDefault(); redoAction() }
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') { event.preventDefault(); execute('save') }
      if (event.key === 'Enter' && tool === 'curve') { event.preventDefault(); finishCurve() }
      if (event.key === 'F10') { event.preventDefault(); execute('points') }
      if (event.key === 'Delete') execute('delete')
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  })
  const toolButton = (item: ToolButton, compact = false) => <button key={item.action} aria-label={item.label} title={item.label} className={`tool-button ${compact ? 'compact' : ''} ${(item.action === tool || (item.action === 'points' && showPoints)) ? 'chosen' : ''} icon-${item.icon}`} disabled={item.disabled || (item.action === 'undo' && !history.past.length) || (item.action === 'redo' && !history.future.length)} onClick={() => execute(item.action)}><Icon name={item.icon} size={compact ? 20 : 22} /><span className="tool-corner" /></button>
  const activePoint = object?.kind === 'curve' && pointIndex !== null ? object.points[pointIndex] : null

  return <main className="rhova">
    <header className="titlebar"><div className="brandmark">R</div><strong>Rhova <span>8</span></strong><i /><span>{project.name}.rhova</span><span className="title-detail">Architectural concept / 01</span><div className="local-status"><b />{saveStatus}</div><button className="title-help" onClick={() => setHelp(true)}>?</button></header>
    <nav className="menubar" aria-label="Application menu">{Object.entries(menuActions).map(([name, actions]) => <details key={name} className="app-menu"><summary>{name}</summary><div className="menu-popover">{actions.map(action => {
      const item = tools.find(tool => tool.action === action) ?? { label: 'Document properties', icon: 'settings' as IconName }
      return <button key={action} onClick={event => { execute(action); event.currentTarget.closest('details')?.removeAttribute('open') }}><Icon name={item.icon} size={15} />{item.label}</button>
    })}</div></details>)}<span className="workspace-name">Modeling workspace <span>⌄</span></span></nav>
    <section className="command-area" aria-label="Command history"><div className="command-history" aria-live="polite">{commands.slice(-2).map((line, i) => <div key={`${commands.length}-${i}`}>{line}</div>)}</div><div className="command-input"><strong>Command:</strong><input aria-label="Command" value={command} placeholder={tool === 'curve' ? 'Click to place control points. Enter to finish.' : 'Type a command…'} onChange={event => setCommand(event.target.value)} onKeyDown={event => { if (event.key === 'Enter') { if (!command && tool === 'curve') finishCurve(); else runCommand() } }} /><span>{tool === 'curve' ? `${draft.length} points` : 'Ready'}</span></div></section>
    <div className="toolbar-tabs" role="tablist" aria-label="Tool categories">{tabs.map(tab => <button key={tab} role="tab" aria-selected={toolbar === tab} className={toolbar === tab ? 'selected' : ''} onClick={() => setToolbar(tab)}>{tab}</button>)}</div>
    <div className="main-toolbar"><span className="grip">⠿</span>{tools.filter(tool => toolbar === 'Standard' || categoryActions[toolbar]?.includes(tool.action)).map(item => toolButton(item))}<div className="toolbar-end"><span>MODEL</span><b>▱</b></div></div>
    <div className="modeling-workspace">
      <aside className="left-tools" aria-label="Modeling tools"><span className="left-grip">••••</span><div className="tool-grid">{tools.slice(6, 24).map(item => toolButton(item, true))}{tools.slice(0, 6).map(item => toolButton(item, true))}</div><div className="sidebar-label">Osnap</div><div className="snap-list">{['End', 'Near', 'Point', 'Mid', 'Cen', 'Int', 'Perp', 'Tan', 'Quad', 'Knot', 'Vertex'].map((label, index) => <label key={label} title={index < 3 ? 'Round construction and drag coordinates to 0.5 m' : 'Native geometric snap mode — outside browser V1'}><input type="checkbox" checked={index < 3 && snap} onChange={() => setSnap(!snap)} disabled={index >= 3} />{label}</label>)}</div><div className="left-bottom"><Icon name="settings" size={16} /><span>V1</span></div></aside>
      <div className="viewport-area"><div className={`viewport-grid ${maximized ? 'single' : ''}`}>
        {views.filter(view => !maximized || maximized === view).map(view => <Viewport key={view} view={view} active={activeView === view} project={project} selected={selected} mode={modes[view]} showPoints={showPoints} pointIndex={pointIndex} tool={tool} draft={draft} grid={grid} snap={snap} fit={fit} maximized={maximized !== null} onActive={() => setActiveView(view)} onSelect={selectObject} onPoint={setPointIndex} onPointMove={(id, index, point) => {
          const item = project.objects.find(object => object.id === id)
          if (item && !project.layers.find(layer => layer.id === item.layerId)?.locked) apply(updateEntity(project, id, { points: item.points.map((old, i) => i === index ? point : old) }), `Control point ${index + 1} moved.`)
        }} onDraw={point => setDraft(current => [...current, point])} onCursor={setCursor} onMaximize={() => { setActiveView(view); setMaximized(maximized ? null : view) }} onMode={mode => setModes(current => ({ ...current, [view]: mode }))} />)}
      </div><div className="viewport-tabs"><button onClick={() => setMaximized(null)} className={!maximized ? 'tab-active' : ''}>▦ <span>4 Views</span></button>{(['Perspective', 'Top', 'Front', 'Right'] as ViewName[]).map(view => <button key={view} className={maximized === view ? 'tab-active' : ''} onClick={() => { setActiveView(view); setMaximized(view) }}>{view}</button>)}<span className="model-units">Absolute tolerance: 0.001 m</span></div></div>
      <aside className="right-panel" aria-label="Layers and properties"><div className="right-panel-tabs">{(['Layers', 'Properties'] as const).map(name => <button key={name} className={panel === name ? 'selected' : ''} onClick={() => setPanel(name)}><Icon name={name === 'Layers' ? 'layers' : 'settings'} size={16} />{name}</button>)}<button className="panel-help" title="Workspace help" onClick={() => setHelp(true)}>⋮</button></div>
        <div className="right-scroll">
          {panel === 'Layers' && <section className="layers-section"><div className="panel-toolbar"><strong>Layers</strong><span>{project.layers.length}</span><button title="Show all layers" aria-label="Show all layers" onClick={() => apply({ ...project, layers: project.layers.map(layer => ({ ...layer, visible: true })) }, 'All layers shown.')}><Icon name="eye" size={16} /></button></div><div className="layer-search"><span>⌕</span><input aria-label="Filter layers" placeholder="Filter layers" value={layerFilter} onChange={event => setLayerFilter(event.target.value)} /></div><div className="layer-table-header"><span>Name</span><Icon name="eye" size={12} /><Icon name="lock" size={12} /><span>Color</span></div><div className="layer-rows">{project.layers.filter(layer => layer.name.toLowerCase().includes(layerFilter.toLowerCase())).map(layer => <div className={`layer-row ${object?.layerId === layer.id ? 'selected' : ''} ${!layer.visible ? 'hidden-layer' : ''}`} key={layer.id}><button className="layer-name" onClick={() => { const first = project.objects.find(object => object.layerId === layer.id); if (first) selectObject(first.id) }}><span className="layer-tree">◇</span>{layer.name}</button><button className="layer-visibility" title={`${layer.visible ? 'Hide' : 'Show'} ${layer.name}`} aria-label={`${layer.visible ? 'Hide' : 'Show'} ${layer.name}`} onClick={() => changeLayer(layer.id, { visible: !layer.visible })}>{layer.visible ? <Icon name="eye" size={14} /> : '–'}</button><button className={`layer-lock ${layer.locked ? 'locked' : ''}`} title={`${layer.locked ? 'Unlock' : 'Lock'} ${layer.name}`} aria-label={`${layer.locked ? 'Unlock' : 'Lock'} ${layer.name}`} onClick={() => changeLayer(layer.id, { locked: !layer.locked })}>{layer.locked ? <Icon name="lock" size={13} /> : '·'}</button><input type="color" aria-label={`${layer.name} color`} value={layer.color} onChange={event => changeLayer(layer.id, { color: event.target.value })} /></div>)}</div><div className="layer-hint">Click an object to inspect · Shift to multi-select</div></section>}
          <section className="properties-section"><div className="section-heading"><Icon name="settings" size={15} /><strong>{object ? 'Object properties' : 'Document properties'}</strong><span>{object ? '⌄' : '▾'}</span></div>
            {object ? <><div className="object-heading"><span className={`object-badge ${object.kind}`}><Icon name={object.kind === 'curve' ? 'curve' : 'cube'} size={24} /></span><div><strong>{selected.length > 1 ? `${selected.length} objects selected` : object.name}</strong><small>{object.kind === 'canopy' ? 'Parametric ribbed shell' : object.kind === 'curve' ? 'Interpolated control curve' : object.kind === 'loft' ? 'Ruled polygon surface' : object.kind === 'extrusion' ? 'Open extruded surface' : 'Procedural geometry'}</small></div></div>
            <label className="property-row"><span>Name</span><input key={object.id + object.name} aria-label="Object name" defaultValue={object.name} maxLength={120} disabled={locked} onBlur={event => { if (event.target.value.trim()) editObject({ name: event.target.value.trim() }) }} /></label><label className="property-row"><span>Layer</span><select aria-label="Object layer" value={object.layerId} disabled={locked} onChange={event => editObject({ layerId: event.target.value })}>{project.layers.map(layer => <option key={layer.id} value={layer.id} disabled={layer.locked}>{layer.name}</option>)}</select></label>
            {locked && <p className="inline-warning">Layer locked. Unlock it to edit geometry.</p>}
            <div ref={transformSection} className="property-group"><h3>Transform <small>World coordinates</small></h3>{(['X', 'Y', 'Z'] as const).map((axis, index) => <Numeric key={`${object.id}-${axis}`} label={`Position ${axis}`} value={object.position[index]} disabled={locked} onChange={value => editObject({ position: object.position.map((old, i) => i === index ? value : old) as Point }, `Position ${axis} set to ${value} m.`)} />)}<Numeric label="Rotation Z" value={object.rotation} min={-360} max={360} step={5} disabled={locked} onChange={value => editObject({ rotation: value })} /><Numeric label="Scale" value={object.scale} min={0.01} max={20} step={0.1} disabled={locked} onChange={value => editObject({ scale: value })} /></div>
            {object.kind === 'canopy' && <div className="property-group"><h3>Canopy definition <small>Parametric</small></h3><Numeric label="Canopy rise" value={object.height} min={2} max={24} disabled={locked} onChange={value => editObject({ height: value }, `Canopy rise set to ${value} m.`)} /><Numeric label="Rib count" value={object.ribs} min={8} max={64} step={1} disabled={locked} onChange={value => editObject({ ribs: Math.round(value) }, 'Canopy rib distribution updated.')} /><div className="definition-note">39.00 m span / 23.40 m depth<br />Swept profiles · open ribbon mesh</div></div>}
            {object.kind === 'curve' && <div className="property-group"><h3>Control points <small>{object.points.length} points</small></h3><button className={`wide-button ${showPoints ? 'on' : ''}`} onClick={() => setShowPoints(!showPoints)}><Icon name="points" size={16} />{showPoints ? 'Hide control points' : 'Show control points'}<kbd>F10</kbd></button><div className="point-selector">{object.points.map((_, index) => <button key={index} className={pointIndex === index ? 'selected' : ''} onClick={() => { setPointIndex(index); setShowPoints(true) }}>P{index + 1}</button>)}</div>{activePoint && (['X', 'Y', 'Z'] as const).map((axis, index) => <Numeric key={`${object.id}-point-${pointIndex}-${axis}`} label={`Point ${axis}`} value={activePoint[index]} disabled={locked} onChange={value => editObject({ points: object.points.map((point, i) => i === pointIndex ? point.map((old, j) => j === index ? value : old) as Point : point) }, `Control point ${(pointIndex ?? 0) + 1} updated.`)} />)}<Numeric label="Extrusion height" value={extrusionHeight} min={0.1} max={100} onChange={setExtrusionHeight} /><div className="button-pair"><button disabled={locked} onClick={() => execute('extrude')}><Icon name="extrude" size={16} />Extrude</button><button disabled={locked} onClick={() => execute('loft')}><Icon name="loft" size={16} />Loft 2 curves</button></div></div>}
            {object.kind === 'extrusion' && <div className="property-group"><h3>Extrusion</h3><Numeric label="Surface height" value={object.height} min={0.1} max={100} disabled={locked} onChange={value => editObject({ height: value })} /></div>}
            </> : <><div className="document-title"><small>CONCEPT DESIGN / 01</small><h2>Aurelian<br />Museum</h2><p>A study in structure, light & landscape.</p></div><dl className="document-stats"><div><dt>Model units</dt><dd>Meters</dd></div><div><dt>Objects</dt><dd>{project.objects.length}</dd></div><div><dt>Layers</dt><dd>{project.layers.length}</dd></div><div><dt>Canopy span</dt><dd>39.00 m</dd></div><div><dt>Display precision</dt><dd>0.001</dd></div></dl><div className="document-note"><span>01</span><p>Select the canopy to adjust its rise and ribs. Select a profile to explore its control points.</p></div></>}
          </section>
          <section className="objects-section"><div className="section-heading"><Icon name="cube" size={15} /><strong>Objects</strong><span>{project.objects.length}</span></div><div className="objects-list">{project.objects.map(item => <button key={item.id} className={selected.includes(item.id) ? 'selected' : ''} onClick={event => { selectObject(item.id, event.shiftKey); setPanel('Properties') }}><Icon name={item.kind === 'curve' ? 'curve' : item.kind === 'loft' ? 'loft' : 'cube'} size={14} /><span>{item.name}</span><i style={{ background: project.layers.find(layer => layer.id === item.layerId)?.color }} /></button>)}</div></section>
        </div><div className="panel-footer"><span className="status-dot" />Local project <span>No account required</span></div>
      </aside>
    </div>
    {tool === 'curve' && <div className="drawing-bar"><Icon name="curve" size={18} /><strong>Curve</strong><span>Click points in an orthographic viewport</span><button onClick={finishCurve}>Finish curve <kbd>Enter</kbd></button><button onClick={() => { setTool('select'); setDraft([]) }}>Cancel <kbd>Esc</kbd></button></div>}
    <footer className="statusbar"><span className="cplane">CPlane</span><div className="coordinates">{(['X', 'Y', 'Z'] as const).map((axis, i) => <span key={axis}><b>{axis}</b>{cursor[i].toFixed(3)}</span>)}</div><span className="units">Meters</span><span className="current-layer"><i style={{ background: project.layers.find(layer => layer.id === object?.layerId)?.color ?? '#bb995d' }} />{object ? project.layers.find(layer => layer.id === object.layerId)?.name : 'Canopy · structure'}</span><div className="status-toggles"><button className={snap ? 'on' : ''} onClick={() => setSnap(!snap)}>Grid Snap</button><button disabled title="Ortho constraint is outside V1">Ortho</button><button disabled title="Planar constraint is outside V1">Planar</button><button className={snap ? 'on' : ''} onClick={() => setSnap(!snap)}>Osnap</button><button className={showPoints ? 'on' : ''} onClick={() => setShowPoints(!showPoints)}>Points</button><button className={grid ? 'on' : ''} onClick={() => setGrid(!grid)}>Grid</button></div><span className="selection-status">{selected.length ? `${selected.length} selected` : 'No selection'}</span></footer>
    <input ref={fileInput} type="file" accept=".json,.rhova" hidden onChange={async event => {
      const file = event.target.files?.[0]
      if (file) try {
        if (file.size > 2_000_000) throw new Error('Project exceeds the 2 MB limit.')
        const imported = parseProject(await file.text())
        apply(imported, `Opened ${file.name}.`); setSelection([]); setTool('select'); setDraft([])
      } catch (error) { announce(`Open failed: ${error instanceof Error ? error.message : 'Invalid project'}`) }
      event.target.value = ''
    }} />
    {help && <div className="modal-backdrop" onClick={() => setHelp(false)}><section className="dialog help-dialog" role="dialog" aria-modal="true" aria-label="Rhova help" onClick={event => event.stopPropagation()}><header><div className="brandmark">R</div><h2>Rhova / modeling notes</h2><button aria-label="Close help" onClick={() => setHelp(false)}>×</button></header><p>A browser modeling study of the Rhino 8 workspace. Built around a procedural museum and an editable polygon geometry workflow.</p><dl><dt>Select</dt><dd>Click geometry or the object list. Hold Shift to select two curves.</dd><dt>Navigate</dt><dd>Drag to orbit perspective; drag to pan orthographic views. Scroll to zoom. Double-click a viewport title to maximize.</dd><dt>Create</dt><dd>Draw curve → click 2+ points → Enter. Extrude one curve or loft two curves.</dd><dt>Edit</dt><dd>F10 shows control points. Drag handles or edit point coordinates. Numeric transforms and canopy parameters are in Properties.</dd><dt>History & files</dt><dd>Ctrl+Z / Ctrl+Y. Local autosave. Save exports JSON; Open restores it. OBJ exports visible geometry.</dd><dt>Coordinates</dt><dd>Meters, Z up. Grid Snap and Osnap round to 0.5 m. Native End/Near semantics are not implemented.</dd></dl><div className="help-boundary">V1 boundary: Catmull–Rom curves and polygon surfaces. No NURBS kernel, .3dm support, booleans, native rendering engine or plug-ins. Rhino is a trademark of Robert McNeel & Associates. Rhova is an independent UI study.</div></section></div>}
    {resetPrompt && <div className="modal-backdrop"><section className="dialog" role="dialog" aria-modal="true" aria-label="Reset museum"><header><h2>Reset the museum?</h2></header><p>Restore the built-in Aurelian Museum. Your current edits remain available through Undo.</p><div className="dialog-actions"><button onClick={() => setResetPrompt(false)}>Cancel</button><button className="primary" onClick={() => { apply(createMuseum(), 'Museum reset to the original study.'); setSelection([]); setPointIndex(null); setShowPoints(false); setDraft([]); setTool('select'); setResetPrompt(false); setMaximized(null); setFit(value => value + 1) }}>Reset museum</button></div></section></div>}
  </main>
}
