import { useEffect, useRef, useState } from 'react'
import type { FormEvent, ReactNode } from 'react'
import { Box, Building2, ChevronDown, CircleHelp, Columns3, Copy, DoorOpen, Eye, File, FileDown, Folder, FolderOpen, Grid2X2, Grid3X3, Hand, Home, Info, Layers, Leaf, Maximize, Minus, MoreHorizontal, MousePointer2, Move, PanelRight, Plus, Redo2, RotateCcw, Ruler, Save, Scissors, Search, Settings2, SlidersHorizontal, Square, SquareDashed, Sun, Trash2, Undo2, Upload, View, X } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { createHistory, commit, deleteElement, doorOnWall, exportPlan, initialProject, MATERIALS, parseProject, redo, slabFromPoints, STORAGE_KEY, STORIES, undo, updateElement, visibleElements, wallFromPoints } from './model'
import type { Combination, Material, Point, Project } from './model'
import Viewport3D from './Viewport3D'
import type { CameraPreset } from './Viewport3D'
import Plan from './Plan'
import type { Tool } from './Plan'

function IconButton({ icon: Icon, label, onClick, active, disabled }: { icon: LucideIcon; label: string; onClick?: () => void; active?: boolean; disabled?: boolean }) {
  return <button className={`icon-button ${active ? 'active' : ''}`} title={disabled ? `${label} — unavailable in browser V1` : label} aria-label={label} onClick={onClick} disabled={disabled}><Icon size={18} strokeWidth={1.5} /></button>
}
function loadProject() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return { project: raw ? parseProject(raw) : initialProject(), error: '' }
  } catch { return { project: initialProject(), error: 'Saved data could not be read. The campus fixture is open; use Save Project to keep a copy.' } }
}
function download(name: string, content: string, type: string) {
  const url = URL.createObjectURL(new Blob([content], { type }))
  const a = document.createElement('a')
  a.href = url; a.download = name; a.click()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
const TOOL_ICONS: Record<Tool, LucideIcon> = { Arrow: MousePointer2, Wall: Columns3, Slab: Layers, Door: DoorOpen, Measure: Ruler }

export default function App() {
  const [loaded] = useState(loadProject)
  const [history, setHistory] = useState(() => createHistory(loaded.project))
  const project = history.present
  const [view, setView] = useState<'3D' | 'Plan'>('3D')
  const [tool, setTool] = useState<Tool>('Arrow')
  const [selected, setSelected] = useState<string | null>(null)
  const [story, setStory] = useState(0)
  const [combination, setCombination] = useState<Combination>('All elements')
  const [cutaway, setCutaway] = useState(false)
  const [appearance, setAppearance] = useState('Surfaces')
  const [sun, setSun] = useState('Afternoon')
  const [camera, setCamera] = useState<CameraPreset>('Axonometry')
  const [fit, setFit] = useState(0)
  const [zoom, setZoom] = useState(1)
  const [grid, setGrid] = useState(false)
  const [anchor, setAnchor] = useState<Point | null>(null)
  const [material, setMaterial] = useState<Material>('limestone')
  const [message, setMessage] = useState(loaded.error || 'Ready')
  const [saveError, setSaveError] = useState('')
  const [menu, setMenu] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [modal, setModal] = useState<'properties' | 'help' | 'reset' | null>(null)
  const [propertyError, setPropertyError] = useState('')
  const [map, setMap] = useState<'Project Map' | 'View Map'>('Project Map')
  const [scale, setScale] = useState('1:200')
  const file = useRef<HTMLInputElement>(null)
  const element = project.elements.find(e => e.id === selected)
  const apply = (next: Project) => setHistory(h => commit(h, next))
  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(project)); setSaveError('') }
    catch { setSaveError('Local saving unavailable. Download Save Project to preserve your work.') }
  }, [project])
  useEffect(() => {
    const handle = (event: KeyboardEvent) => {
      if (event.target instanceof HTMLInputElement || event.target instanceof HTMLSelectElement || event.target instanceof HTMLTextAreaElement) return
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'z') {
        event.preventDefault(); setHistory(h => event.shiftKey ? redo(h) : undo(h)); setAnchor(null)
      } else if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') {
        event.preventDefault(); download('oak-and-light.atrio.json', JSON.stringify(project, null, 2), 'application/json')
      } else if (event.key === 'Escape') { setAnchor(null); setTool('Arrow'); setMenu(null); setModal(null) }
      else if (event.key === 'Delete' && selected && !modal) { apply(deleteElement(project, selected)); setSelected(null) }
    }
    window.addEventListener('keydown', handle)
    return () => window.removeEventListener('keydown', handle)
  })
  useEffect(() => {
    const clear = () => setMenu(null)
    window.addEventListener('click', clear)
    return () => window.removeEventListener('click', clear)
  }, [])
  const chooseTool = (next: Tool) => {
    setTool(next); setAnchor(null)
    if (next !== 'Arrow') {
      setView('Plan')
      if (story === 2) setStory(0)
      setMessage(next === 'Door' ? 'Click a wall to place a hosted door.' : next === 'Measure' ? 'Click two points to measure their distance.' : `Click the ${next === 'Slab' ? 'first corner' : 'start point'}, then the ${next === 'Slab' ? 'opposite corner' : 'end point'}. Grid snap: 0.25 m.`)
    }
  }
  const changeMaterial = (value: Material) => {
    setMaterial(value)
    if (element) apply(updateElement(project, element.id, { material: value }))
  }
  const planPoint = (point: Point, id?: string) => {
    if (tool === 'Arrow') { setSelected(id ?? null); return }
    try {
      if (tool === 'Door') {
        const wall = project.elements.find(e => e.id === id)
        if (!wall) throw new Error('Click directly on a wall to place a door.')
        const door = doorOnWall(crypto.randomUUID(), wall, point, project)
        apply({ ...project, elements: [...project.elements, door] }); setSelected(door.id); setTool('Arrow'); setMessage('Door created with a linked wall opening.'); return
      }
      if (!anchor) { setAnchor(point); return }
      if (tool === 'Measure') {
        setMessage(`Measured distance: ${Math.hypot(point.x - anchor.x, point.z - anchor.z).toFixed(2)} m`); setAnchor(null); return
      }
      const next = tool === 'Wall' ? wallFromPoints(crypto.randomUUID(), anchor, point, story, material) : slabFromPoints(crypto.randomUUID(), anchor, point, story, material)
      apply({ ...project, elements: [...project.elements, next] }); setSelected(next.id); setAnchor(null); setTool('Arrow'); setMessage(`${next.kind === 'wall' ? 'Wall' : 'Slab'} created. Open Element Settings to refine dimensions.`)
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to create element.'); setAnchor(null) }
  }
  const goStory = (n: number) => { setStory(n); setView('Plan'); setSelected(null); setAnchor(null) }
  const fitView = () => { setFit(n => n + 1); setZoom(1) }
  const exportSVG = () => {
    download(`oak-and-light-story-${story}.svg`, exportPlan(project, story, combination, Number(scale.split(':')[1])), 'image/svg+xml')
    setMessage(`Dimensioned ${STORIES[story]} exported as SVG.`)
  }
  const save = () => { download('oak-and-light.atrio.json', JSON.stringify(project, null, 2), 'application/json'); setMessage('Project downloaded. Local changes are also saved automatically.') }
  const openSettings = () => { setPropertyError(''); if (element) setModal('properties'); else setMessage('Select an element in the drawing or 3D view first.') }
  const updateProperties = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!element) return
    const data = new FormData(event.currentTarget)
    const num = (name: string) => Number(data.get(name))
    try {
      apply(updateElement(project, element.id, {
        name: String(data.get('name')), width: num('width'), depth: num('depth'), height: num('height'),
        material: String(data.get('material')) as Material,
        ...(element.kind !== 'door' ? { x: num('x'), z: num('z'), rotation: num('rotation'), elevation: num('elevation'), story: num('story') } : { offset: num('offset') }),
      }))
      setModal(null); setMessage('Element properties updated.')
    } catch (error) { setPropertyError(error instanceof Error ? error.message : 'Invalid properties.') }
  }
  type MenuEntry = { label: string; action: () => void; shortcut?: string; disabled?: boolean }
  const menus: Record<string, MenuEntry[]> = {
    File: [{ label: 'Open project…', action: () => file.current?.click(), shortcut: 'JSON' }, { label: 'Save project…', action: save, shortcut: 'Ctrl+S' }, { label: 'Export dimensioned plan…', action: exportSVG, shortcut: 'SVG' }, { label: 'Reset campus fixture…', action: () => setModal('reset') }],
    Edit: [{ label: 'Undo', action: () => setHistory(undo), shortcut: 'Ctrl+Z', disabled: !history.past.length }, { label: 'Redo', action: () => setHistory(redo), shortcut: 'Ctrl+Shift+Z', disabled: !history.future.length }, { label: 'Delete selected element', action: () => { if (selected) { apply(deleteElement(project, selected)); setSelected(null) } }, shortcut: 'Del', disabled: !element }],
    View: [{ label: 'Ground floor plan', action: () => goStory(0) }, { label: '3D axonometry', action: () => { setView('3D'); setCamera('Axonometry') } }, { label: 'Fit in window', action: fitView }, { label: 'Toggle 3D cutaway', action: () => { setCutaway(!cutaway); setView('3D') } }],
    Design: ['Wall', 'Slab', 'Door'].map(label => ({ label: `Create ${label.toLowerCase()}`, action: () => chooseTool(label as Tool) })),
    Document: [{ label: 'Export dimensioned plan', action: exportSVG }, { label: 'Measure distance', action: () => chooseTool('Measure') }],
    Options: [{ label: 'All elements', action: () => setCombination('All elements') }, { label: 'Architecture only', action: () => setCombination('Architecture') }, { label: 'Structure only', action: () => setCombination('Structure only') }],
    Window: [{ label: 'Element settings…', action: openSettings, disabled: !element }, { label: 'Reset view', action: fitView }],
    Help: [{ label: 'Atrio essentials & shortcuts', action: () => setModal('help') }],
  }
  const NavRow = ({ label, icon: Icon = File, depth = 0, active, action, disabled }: { label: string; icon?: LucideIcon; depth?: number; active?: boolean; action?: () => void; disabled?: boolean }) => {
    if (search && !label.toLowerCase().includes(search.toLowerCase())) return null
    return <button className={`nav-row ${active ? 'selected' : ''}`} style={{ paddingLeft: 11 + depth * 17 }} onClick={action} disabled={disabled} title={disabled ? `${label} — documentation tools outside browser V1` : label}><Icon size={15} strokeWidth={1.35} /><span>{label}</span></button>
  }
  return <div className="app">
    <header className="titlebar"><div className="brand"><span className="brand-mark">a</span><b>atrio</b></div><span className="project-title"><File size={12} /> {project.name}.atrio</span><span className="local-indicator"><span />Local project <ChevronDown size={11} /></span></header>
    <nav className="menubar" aria-label="Main menu">{['File', 'Edit', 'View', 'Design', 'Document', 'Options', 'Teamwork', 'Window', 'Help'].map(name => <div className="menu-anchor" key={name}>
      <button disabled={name === 'Teamwork'} title={name === 'Teamwork' ? 'Teamwork requires a commercial BIM server and is outside browser V1' : undefined} className={menu === name ? 'menu-open' : ''} onClick={event => { event.stopPropagation(); setMenu(menu === name ? null : name) }}>{name}</button>
      {menu === name && <div className="menu-dropdown">{menus[name]?.map(item => <button key={item.label} disabled={item.disabled} onClick={item.action}><span>{item.label}</span><small>{item.shortcut}</small></button>)}</div>}
    </div>)}<span className="workspace-label">Architectural workspace</span></nav>
    <div className="toolbar">
      <IconButton icon={FolderOpen} label="Open project" onClick={() => file.current?.click()} /><IconButton icon={Save} label="Save project" onClick={save} />
      <i /><IconButton icon={Undo2} label="Undo" onClick={() => setHistory(undo)} disabled={!history.past.length} /><IconButton icon={Redo2} label="Redo" onClick={() => setHistory(redo)} disabled={!history.future.length} />
      <i /><IconButton icon={Maximize} label="Fit in window" onClick={fitView} /><IconButton icon={MousePointer2} label="Select elements" onClick={() => chooseTool('Arrow')} active={tool === 'Arrow'} />
      <i /><button className={`tool-label ${grid ? 'active' : ''}`} onClick={() => { setGrid(!grid); setView('Plan') }}><Grid3X3 size={18} />Grids<ChevronDown size={11} /></button>
      <button className={`tool-label ${tool === 'Measure' ? 'active' : ''}`} onClick={() => chooseTool('Measure')}><Ruler size={19} />Measure</button>
      <i /><button className={`tool-label ${cutaway ? 'active' : ''}`} onClick={() => { setCutaway(!cutaway); setView('3D') }}><Scissors size={18} />3D Cutaway</button>
      <button className="tool-label" onClick={() => { setView('3D'); setCamera(camera === 'Axonometry' ? 'Courtyard' : 'Axonometry') }}><RotateCcw size={18} />Orbit view</button>
      <i /><IconButton icon={Settings2} label="Element Settings" onClick={openSettings} disabled={!element} />
      <div className="toolbar-spacer" /><button className="export-button" onClick={exportSVG}><FileDown size={15} />Export plan</button>
    </div>
    <section className="infobox" aria-label="Info Box">
      <div className="info-tool"><span className="info-header">Info Box</span><div><span className="tool-preview">{(() => { const Icon = element ? TOOL_ICONS[element.kind === 'wall' ? 'Wall' : element.kind === 'slab' ? 'Slab' : 'Door'] : TOOL_ICONS[tool]; return <Icon size={24} strokeWidth={1.1} /> })()}</span><span><b>{element ? element.kind[0].toUpperCase() + element.kind.slice(1) : tool}</b><small>{element ? 'Selected: 1 / Editable: 1' : 'Default settings'}</small></span><ChevronDown size={11} /></div></div>
      <div className="info-field layer-field"><span className="info-header">Layer combination</span><div className="select-with-icon"><Layers size={15} /><select aria-label="Layer combination" value={combination} onChange={event => setCombination(event.target.value as Combination)}>{['All elements', 'Architecture', 'Structure only'].map(v => <option key={v}>{v}</option>)}</select></div></div>
      <div className="info-field geometry-field"><span className="info-header">Geometry method</span><div className="geometry-icons"><span className="active"><Move size={20} /></span><span><Square size={19} /></span><span><Box size={21} /></span></div></div>
      <div className="info-field material-field"><span className="info-header">Building material</span><div className="select-with-icon"><span className="swatch" style={{ background: MATERIALS[element?.material ?? material].color }} /><select aria-label="Building material" value={element?.material ?? material} onChange={event => changeMaterial(event.target.value as Material)}>{Object.entries(MATERIALS).map(([key, value]) => <option key={key} value={key}>{value.label}</option>)}</select></div></div>
      <div className="info-field story-field"><span className="info-header">Home story</span><div className="select-with-icon"><Building2 size={15} /><select aria-label="Home story" value={story} onChange={event => goStory(Number(event.target.value))}>{STORIES.map((v, i) => <option key={v} value={i}>{v}</option>)}</select></div></div>
      <div className="info-field dimension-field"><span className="info-header">Height / thickness</span><button onClick={openSettings} disabled={!element} className="height-info"><Ruler size={16} /><span>{element ? `${element.height.toFixed(2)} / ${element.depth.toFixed(2)} m` : '3.60 / 0.25 m'}</span></button></div>
    </section>
    <div className="workspace">
      <aside className="toolbox" aria-label="Toolbox"><div className="palette-grip">Toolbox</div>
        <button className={`toolbox-item ${tool === 'Arrow' ? 'active' : ''}`} onClick={() => chooseTool('Arrow')}><MousePointer2 /><span>Arrow</span></button>
        <button className="toolbox-item" disabled title="Marquee — outside browser V1"><SquareDashed /><span>Marquee</span></button>
        <div className="tool-section">DESIGN</div>
        {(['Wall', 'Slab', 'Door'] as Tool[]).map(t => { const Icon = TOOL_ICONS[t]; return <button key={t} className={`toolbox-item ${tool === t ? 'active' : ''}`} onClick={() => chooseTool(t)}><Icon /><span>{t}</span></button> })}
        {[['Window', Grid2X2], ['Column', Columns3], ['Beam', Minus], ['Roof', Home], ['Object', Box], ['Mesh', Leaf]].map(([name, Icon]) => { const Component = Icon as LucideIcon; return <button key={String(name)} className="toolbox-item" disabled title={`${name} — outside browser V1`}><Component /><span>{String(name)}</span></button> })}
        <div className="tool-section">DOCUMENT</div>
        <button className={`toolbox-item ${tool === 'Measure' ? 'active' : ''}`} onClick={() => chooseTool('Measure')}><Ruler /><span>Measure</span></button>
        <button className="toolbox-item" onClick={exportSVG} title="Export dimensioned SVG"><FileDown /><span>Drawing</span></button>
        <div className="toolbox-bottom"><IconButton icon={CircleHelp} label="Help and shortcuts" onClick={() => setModal('help')} /></div>
      </aside>
      <main className="drawing-workspace">
        <div className="view-tabs">
          <button className={view === 'Plan' ? 'active' : ''} onClick={() => { setView('Plan'); setAnchor(null) }}><File size={15} />{STORIES[story]}<span>×</span></button>
          <button className={view === '3D' ? 'active' : ''} onClick={() => { setView('3D'); setTool('Arrow'); setAnchor(null) }}><Box size={16} />3D / {camera === 'Axonometry' ? 'All' : camera}<span>×</span></button>
          <div className="tab-fill" /><IconButton icon={PanelRight} label="Navigator is docked" disabled />
        </div>
        <div className="drawing-area">
          {view === '3D' ? <Viewport3D project={project} selected={selected} onSelect={setSelected} combination={combination} cutaway={cutaway} appearance={appearance} camera={camera} sun={sun} fit={fit} /> : <Plan project={project} story={story} combination={combination} selected={selected} tool={tool} anchor={anchor} onPoint={planPoint} zoom={zoom} grid={grid} />}
          <div className="viewport-caption"><span className="drawing-kicker">OAK & LIGHT</span><strong>Arts campus</strong><span>{view === '3D' ? `${cutaway ? 'Cutaway · ' : ''}${camera} / ${appearance}` : `${STORIES[story]} / General arrangement`}</span></div>
          <div className="view-compass" aria-label="North arrow"><span>N</span><svg viewBox="0 0 56 58"><path d="M28 5L13 43l15-8 15 8Z" fill="#52655f" /><path d="M28 5v30l15 8Z" fill="#bbc4be" /><circle cx="28" cy="30" r="24" stroke="#aab4ac" fill="none" strokeWidth=".6" /></svg></div>
          <div className="drawing-stamp"><strong>OAK & LIGHT / 01</strong><span>SCHEMATIC DESIGN</span><span>REV 03 · SEPTEMBER 2026</span></div>
          {view === '3D' && <div className="camera-controls">{(['Axonometry', 'Courtyard', 'Top'] as CameraPreset[]).map(c => <button key={c} className={camera === c ? 'active' : ''} onClick={() => setCamera(c)}>{c === 'Axonometry' ? <Box size={14} /> : c === 'Top' ? <Grid2X2 size={14} /> : <View size={14} />}{c}</button>)}</div>}
          {view === 'Plan' && <div className="plan-note"><span>0</span><div /><span>10 m</span></div>}
          {saveError && <div className="save-warning" role="alert">{saveError}</div>}
        </div>
        <div className="quickbar"><IconButton icon={Maximize} label="Fit drawing" onClick={fitView} /><i />
          {view === 'Plan' ? <><IconButton icon={Minus} label="Zoom out" onClick={() => setZoom(z => Math.max(.5, z - .2))} /><span>{Math.round(zoom * 100)}%</span><IconButton icon={Plus} label="Zoom in" onClick={() => setZoom(z => Math.min(3, z + .2))} /></> : <><Hand size={14} /><span>Drag to orbit · Scroll to zoom</span></>}
          <div className="toolbar-spacer" /><span className="quickbar-unit">Metres</span><i /><select aria-label="Drawing export scale" title="Physical scale for exported SVG" value={scale} onChange={event => { setScale(event.target.value); setMessage(`Plan export scale set to ${event.target.value}. SVG physical dimensions will match.`) }}><option>1:100</option><option>1:200</option><option>1:500</option></select><i /><button onClick={() => setCombination(combination === 'All elements' ? 'Structure only' : 'All elements')}><Layers size={14} />{combination}<ChevronDown size={11} /></button>
        </div>
      </main>
      <aside className="right-panels" aria-label="Navigator and Quick Options">
        <div className="panel-title"><span>Navigator</span><MoreHorizontal size={15} /></div>
        <div className="map-tabs"><IconButton icon={Home} label="Project Map" active={map === 'Project Map'} onClick={() => setMap('Project Map')} /><IconButton icon={Eye} label="View Map" active={map === 'View Map'} onClick={() => setMap('View Map')} /><IconButton icon={Copy} label="Layout Book" disabled /><IconButton icon={Upload} label="Publisher" disabled /><span className="toolbar-spacer" /><ChevronDown size={12} /></div>
        <label className="navigator-search"><Search size={13} /><input placeholder={`Search ${map}`} value={search} onChange={event => setSearch(event.target.value)} aria-label="Search navigator" />{search && <button aria-label="Clear search" onClick={() => setSearch('')}><X size={12} /></button>}</label>
        <div className="navigator-tree">
          <div className="project-row"><ChevronDown size={12} /><Home size={14} /><b>Oak & Light Arts Campus</b></div>
          {map === 'Project Map' ? <>
            <div className="folder-row"><ChevronDown size={12} /><FolderOpen size={15} /><span>Stories</span></div>
            {[2, 1, 0].map(n => <NavRow key={n} label={STORIES[n]} depth={2} active={view === 'Plan' && story === n} action={() => goStory(n)} />)}
            {['Sections', 'Elevations', 'Interior Elevations', 'Worksheets', 'Details', '3D Documents'].map(label => <NavRow key={label} label={label} icon={label === '3D Documents' ? Box : Folder} depth={1} disabled />)}
            <div className="folder-row"><ChevronDown size={12} /><Box size={15} /><span>3D</span></div>
            <NavRow label="Generic Perspective" icon={Box} depth={2} active={view === '3D' && camera === 'Courtyard'} action={() => { setView('3D'); setCamera('Courtyard') }} />
            <NavRow label="Generic Axonometry" icon={Box} depth={2} active={view === '3D' && camera === 'Axonometry'} action={() => { setView('3D'); setCamera('Axonometry') }} />
            <NavRow label="Schedules" icon={Folder} depth={1} disabled />
          </> : <><NavRow label="Campus / axonometry" icon={Box} depth={1} action={() => { setView('3D'); setCamera('Axonometry'); setCutaway(false) }} /><NavRow label="Ground / presentation" depth={1} action={() => { goStory(0); setCombination('All elements') }} /><NavRow label="Structure / cutaway" icon={Scissors} depth={1} action={() => { setView('3D'); setCutaway(true); setCombination('Structure only') }} /></>}
        </div>
        <div className="navigator-footer"><span><Box size={13} />{visibleElements(project, combination).length} elements</span><IconButton icon={Info} label="Project information" onClick={() => setModal('help')} /></div>
        <div className="panel-title"><span><ChevronDown size={11} />Properties</span><Settings2 size={13} /></div>
        <div className="properties-panel">
          {element ? <><div className="selection-label"><span />1 element selected</div><b className="element-name">{element.name}</b><dl><dt>Element type</dt><dd>{element.kind}</dd><dt>Home story</dt><dd>{STORIES[element.story]}</dd><dt>Dimensions</dt><dd>{element.width.toFixed(2)} × {element.height.toFixed(2)} m</dd><dt>Material</dt><dd>{element.material}</dd></dl><div className="property-buttons"><button onClick={openSettings}><Settings2 size={13} />Element Settings…</button><IconButton icon={Trash2} label="Delete selected element" onClick={() => { apply(deleteElement(project, element.id)); setSelected(null) }} /></div></> : <><div className="view-property"><Box size={21} /><span><b>{view === '3D' ? `Generic ${camera}` : STORIES[story]}</b><small>{view === '3D' ? '3D model / entire project' : 'Floor plan / active story'}</small></span></div><p>Select an element to inspect its properties.</p></>}
        </div>
        <div className="quick-options">
          <div className="panel-title"><span><ChevronDown size={11} />Quick Options</span><SlidersHorizontal size={13} /></div>
          <label><Layers size={14} /><select aria-label="Quick layer combination" value={combination} onChange={e => setCombination(e.target.value as Combination)}><option>All elements</option><option>Architecture</option><option>Structure only</option></select></label>
          <label><Box size={14} /><select aria-label="Model appearance" value={appearance} onChange={e => setAppearance(e.target.value)}><option>Surfaces</option><option>White model</option><option>Technical</option></select></label>
          <label><Sun size={14} /><select aria-label="Sun preset" value={sun} onChange={e => setSun(e.target.value)}><option>Morning</option><option>Afternoon</option><option>Evening</option></select></label>
          <button className={`cutaway-option ${cutaway ? 'checked' : ''}`} onClick={() => { setCutaway(!cutaway); setView('3D') }}><Scissors size={14} /><span>3D cutaway</span><span className="check-square">{cutaway ? '✓' : ''}</span></button>
        </div>
      </aside>
    </div>
    <footer className="statusbar"><MousePointer2 size={13} /><span role="status">{message}</span><div className="toolbar-spacer" /><span className="status-saved"><span />{saveError ? 'Save unavailable' : 'Saved locally'}</span><i /><span>Atrio 1.0</span></footer>
    <input ref={file} type="file" accept=".json,.atrio" className="hidden" aria-label="Open Atrio project file" onChange={async event => {
      const selectedFile = event.target.files?.[0]
      if (!selectedFile) return
      try {
        if (selectedFile.size > 2_000_000) throw new Error('Project file exceeds 2 MB.')
        const parsed = parseProject(await selectedFile.text())
        apply(parsed); setSelected(null); setMessage(`Opened ${parsed.name}.`)
      } catch (error) { setMessage(`Import failed: ${error instanceof Error ? error.message : 'Invalid project'}`) }
      event.target.value = ''
    }} />
    {modal && <Modal title={modal === 'properties' ? 'Element Settings' : modal === 'reset' ? 'Reset campus fixture' : 'Atrio essentials'} onClose={() => setModal(null)}>
      {modal === 'properties' && element && <form onSubmit={updateProperties}>
        <div className="dialog-heading"><Columns3 size={28} strokeWidth={1.2} /><div><b>{element.name}</b><span>{element.kind} · Geometry and positioning</span></div></div>
        <label className="form-wide">Element name<input name="name" defaultValue={element.name} maxLength={100} required /></label>
        <div className="form-grid">{([{ name: 'width', label: 'Width / length (m)', value: element.width }, { name: 'height', label: 'Height (m)', value: element.height }, { name: 'depth', label: 'Depth / thickness (m)', value: element.depth }, ...(element.kind === 'door' ? [{ name: 'offset', label: 'Offset along host (m)', value: element.offset ?? 0 }] : [{ name: 'elevation', label: 'Base elevation (m)', value: element.elevation }, { name: 'x', label: 'X coordinate (m)', value: element.x }, { name: 'z', label: 'Y coordinate (m)', value: element.z }, { name: 'rotation', label: 'Rotation (degrees)', value: element.rotation }])]).map(field => <label key={field.name}>{field.label}<input name={field.name} type="number" step="any" min={['width', 'height', 'depth'].includes(field.name) ? .05 : -500} max={500} defaultValue={Number(field.value.toFixed(4))} required /></label>)}
          {element.kind !== 'door' && <label>Home story<select name="story" defaultValue={element.story}>{STORIES.map((s, i) => <option value={i} key={s}>{s}</option>)}</select></label>}
        </div>
        <label className="form-wide">Building material<select name="material" defaultValue={element.material}>{Object.entries(MATERIALS).map(([key, value]) => <option key={key} value={key}>{value.label}</option>)}</select></label>
        {element.hostId && <p className="host-note">Hosted by {project.elements.find(e => e.id === element.hostId)?.name}. Position, elevation and story follow the host wall.</p>}
        {propertyError && <p className="form-error" role="alert">{propertyError}</p>}
        <div className="dialog-actions"><button type="button" onClick={() => setModal(null)}>Cancel</button><button className="primary" type="submit">Apply changes</button></div>
      </form>}
      {modal === 'help' && <div className="help-content"><div className="dialog-heading"><span className="brand-mark">a</span><div><b>A place for ideas to take shape.</b><span>Oak & Light / a mid-century arts campus</span></div></div><p>Explore the campus in 3D, or open the ground floor to edit the linked plan.</p><dl><dt>Wall / Slab</dt><dd>Choose a tool, then click two points in plan. Coordinates snap to 0.25 m.</dd><dt>Door</dt><dd>Click a wall to create a real hosted opening. One door per wall.</dd><dt>Select & edit</dt><dd>Click geometry in either view. Element Settings edits its dimensions and material.</dd><dt>Undo / redo</dt><dd>Ctrl+Z / Ctrl+Shift+Z. Escape cancels drawing. Delete removes selection.</dd><dt>Save & export</dt><dd>Auto-saved in this browser. Save Project downloads JSON; Open Project restores it. Export Plan downloads dimensioned SVG.</dd></dl><p className="help-limit">Independent Archicad 28-inspired browser demo. No Graphisoft affiliation. Native BIM, IFC, GDL, Teamwork, layouts and commercial rendering are outside this V1.</p></div>}
      {modal === 'reset' && <><p className="reset-text">Restore the original arts campus? This change can be undone. Save Project first if you want a separate copy.</p><div className="dialog-actions"><button onClick={() => setModal(null)}>Cancel</button><button className="primary" onClick={() => { apply(initialProject()); setSelected(null); setView('3D'); setCutaway(false); setCombination('All elements'); setCamera('Axonometry'); fitView(); setModal(null); setMessage('Original campus restored. Undo is available.') }}>Restore campus</button></div></>}
    </Modal>}
  </div>
}
function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const old = document.activeElement
    ref.current?.querySelector<HTMLElement>('input,button,select')?.focus()
    const handle = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
      if (event.key !== 'Tab') return
      const items = [...(ref.current?.querySelectorAll<HTMLElement>('button,input,select,[tabindex="0"]') ?? [])]
      const first = items[0], last = items[items.length - 1]
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
    }
    document.addEventListener('keydown', handle)
    return () => { document.removeEventListener('keydown', handle); if (old instanceof HTMLElement) old.focus() }
  }, [onClose])
  return <div className="modal-backdrop" onMouseDown={event => { if (event.currentTarget === event.target) onClose() }}><div className="dialog" role="dialog" aria-modal="true" aria-label={title} ref={ref}><div className="dialog-title"><b>{title}</b><IconButton icon={X} label="Close dialog" onClick={onClose} /></div>{children}</div></div>
}
