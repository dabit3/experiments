import { useCallback, useEffect, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import { categories, commit, createProject, exportPlan, exportSchedule, materials, parseProject, placeDoor, redo, removeElement, serializeProject, snap, STORAGE_KEY, undo, updateElement, wallFromPoints } from './model'
import type { Element, History, Material, Point, Project, View } from './model'
import { Scene } from './Scene'
import type { CameraAction } from './Scene'
import { Drawing } from './Drawing'
import { Icon } from './Icon'

const viewLabels: Record<View, string> = { '3D': '{3D}', 'Level 1': 'Level 1', South: 'South' }
const viewIcons: Record<View, string> = { '3D': 'home', 'Level 1': 'plan', South: 'elevation' }
const categoryIcons: Record<string, string> = { Wall: 'wall', 'Curtain Wall': 'window', Floor: 'floor', Roof: 'roof', Door: 'door', Furniture: 'furniture', 'Timber Fins': 'column', Landscape: 'tree' }

function Tool({ icon, children, onClick, disabled = false, active = false, small = false, title }: { icon: string; children?: ReactNode; onClick?: () => void; disabled?: boolean; active?: boolean; small?: boolean; title?: string }) {
  return <button className={`tool ${small ? 'small' : ''} ${active ? 'active' : ''}`} disabled={disabled} onClick={onClick} title={disabled ? 'Outside the browser V1 scope' : title} aria-label={title || (typeof children === 'string' ? children : icon)}><Icon name={icon} size={small ? 17 : 30}/>{children && <span>{children}</span>}</button>
}
function RibbonGroup({ title, children }: { title: string; children: ReactNode }) {
  return <section className="ribbon-group"><div className="ribbon-tools">{children}</div><div className="ribbon-caption">{title}</div></section>
}
function PropertyRow({ label, children }: { label: string; children: ReactNode }) {
  return <div className="property-row"><span>{label}</span><div>{children}</div></div>
}
function PropertySection({ children, title }: { children: ReactNode; title: string }) {
  return <div className="property-section"><div className="section-heading">{title}<span>⌃</span></div>{children}</div>
}
function ElementProperties({ element, apply, clear }: { element: Element; apply: (element: Element) => void; clear: () => void }) {
  const [draft, setDraft] = useState(element)
  const fixedSite = element.category === 'Landscape'
  useEffect(() => setDraft(element), [element])
  const field = (key: 'x' | 'z' | 'y' | 'w' | 'd' | 'h', label: string, disabled = false) => <PropertyRow label={label}><input aria-label={label} type="number" step=".1" disabled={disabled || fixedSite} value={Number.isNaN(draft[key]) ? '' : draft[key]} onChange={e => setDraft({ ...draft, [key]: e.target.value === '' ? NaN : Number(e.target.value) })}/></PropertyRow>
  return <>
    <div className="type-selector"><div className="type-thumbnail"><Icon name={categoryIcons[element.category]} size={42}/></div><div><span>{element.category}</span><strong>{element.category === 'Wall' ? 'Basic Wall' : element.category === 'Door' ? 'Single / Double Flush' : element.category}</strong><small>{element.material} · {Math.round(element.d * 1000)} mm</small></div><span className="down">⌄</span></div>
    <div className="type-description"><span>{element.category} (1)</span><button onClick={clear}>Deselect</button></div>
    <form className="property-form" onSubmit={e => { e.preventDefault(); apply(draft) }}>
      <PropertySection title="Constraints">
        <PropertyRow label="Base Constraint"><select aria-label="Base Constraint" value={draft.y} disabled={Boolean(element.hostId) || fixedSite} onChange={e => setDraft({ ...draft, y: Number(e.target.value) })}>{![0, 4.42].includes(draft.y) && <option value={draft.y}>Offset {draft.y.toFixed(3)} m</option>}<option value="0">Level 1</option><option value="4.42">Level 2</option></select></PropertyRow>
        {field('h', 'Unconnected Height')}
        {field('w', 'Length')}
        {field('d', 'Thickness')}
      </PropertySection>
      <PropertySection title="Materials and Finishes"><PropertyRow label="Material"><select aria-label="Material" disabled={fixedSite} value={draft.material} onChange={e => setDraft({ ...draft, material: e.target.value as Material })}>{materials.map(m => <option key={m}>{m}</option>)}</select></PropertyRow></PropertySection>
      <PropertySection title="Identity Data"><PropertyRow label="Name"><input aria-label="Element name" value={draft.name} maxLength={120} onChange={e => setDraft({ ...draft, name: e.target.value })}/></PropertyRow><PropertyRow label="Mark"><span className="readonly">{element.id}</span></PropertyRow></PropertySection>
      <PropertySection title="Location (metres)">{field('x', 'Position X', Boolean(element.hostId))}{field('z', 'Position Y', Boolean(element.hostId))}<PropertyRow label="Host"><span className="readonly">{element.hostId || '—'}</span></PropertyRow></PropertySection>
      <div className="apply-row"><span>Dimensions in metres</span><button type="submit">Apply</button></div>
    </form>
  </>
}
function App() {
  const [load] = useState(() => {
    try {
      const text = localStorage.getItem(STORAGE_KEY)
      return { project: text ? parseProject(text) : createProject(), error: '' }
    } catch { return { project: createProject(), error: 'The saved project could not be read. A sample is displayed; use Save to replace the invalid save.' } }
  })
  const [history, setHistory] = useState<History>({ past: [], present: load.project, future: [] })
  const project = history.present
  const [selected, setSelected] = useState<string | null>(null)
  const element = project.elements.find(e => e.id === selected)
  const [view, setView] = useState<View>('3D')
  const [tab, setTab] = useState('Architecture')
  const [tool, setTool] = useState('select')
  const [start, setStart] = useState<Point | null>(null)
  const [message, setMessage] = useState(load.error)
  const [saveState, setSaveState] = useState('Saved locally')
  const [allowSave, setAllowSave] = useState(!load.error)
  const [menu, setMenu] = useState(false)
  const [dialog, setDialog] = useState<'visibility' | 'reset' | 'export' | 'about' | null>(null)
  const [shadows, setShadows] = useState(true)
  const [wireframe, setWireframe] = useState(false)
  const [dimensions, setDimensions] = useState(true)
  const [cameraAction, setCameraAction] = useState<CameraAction>({ type: 'home', tick: 0 })
  const [zoom, setZoom] = useState(1)
  const [search, setSearch] = useState('')
  const [expanded, setExpanded] = useState<Record<string, boolean>>({ Views: true, 'Floor Plans': true, '3D Views': true, Elevations: true })
  const fileInput = useRef<HTMLInputElement>(null)
  const dialogRef = useRef<HTMLDialogElement>(null)
  const update = useCallback((next: Project) => { setHistory(h => commit(h, next)); setMessage('') }, [])
  const select = (id: string | null) => { setSelected(id); setMessage('') }
  const changeView = (next: View) => { setView(next); setTool('select'); setStart(null); setMessage(''); setZoom(1) }
  const chooseTool = (next: string) => {
    setTool(next); setStart(null); setSelected(null); setMessage('')
    if (next !== 'select') setView('Level 1')
  }
  const orient = (type: CameraAction['type']) => {
    if (view !== '3D' && (type === 'in' || type === 'out' || type === 'home')) setZoom(z => type === 'home' ? 1 : Math.max(.6, Math.min(2, z * (type === 'in' ? 1.2 : 1 / 1.2))))
    else { setView('3D'); setCameraAction(a => ({ type, tick: a.tick + 1 })) }
  }
  const save = useCallback(() => {
    try { localStorage.setItem(STORAGE_KEY, serializeProject(project)); setSaveState('Saved locally'); setAllowSave(true); setMessage('Project saved in this browser.') }
    catch { setSaveState('Save failed'); setMessage('Browser storage is full or unavailable. Download project JSON to keep your work.') }
  }, [project])
  const doUndo = useCallback(() => { setHistory(undo); setStart(null); setMessage('') }, [])
  const doRedo = useCallback(() => { setHistory(redo); setStart(null); setMessage('') }, [])
  const remove = useCallback(() => {
    if (selected) { setHistory(h => commit(h, removeElement(h.present, selected))); setSelected(null) }
  }, [selected])
  useEffect(() => {
    if (!allowSave) return
    try { localStorage.setItem(STORAGE_KEY, serializeProject(project)); setSaveState('Saved locally') }
    catch { setSaveState('Save failed'); setMessage('Browser storage is full or unavailable. Export your project to keep changes.') }
  }, [project, allowSave])
  useEffect(() => {
    if (dialog) dialogRef.current?.showModal()
    else dialogRef.current?.close()
  }, [dialog])
  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { setTool('select'); setStart(null); setMenu(false); setDialog(null); setMessage(''); return }
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') { e.preventDefault(); save(); return }
      if (dialog || e.target instanceof HTMLInputElement || e.target instanceof HTMLSelectElement || e.target instanceof HTMLTextAreaElement) return
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') { e.preventDefault(); if (e.shiftKey) doRedo(); else doUndo() }
      if (e.key === 'Delete') remove()
      if (!e.ctrlKey && !e.metaKey && e.key.toLowerCase() === 'w') chooseTool('wall')
      if (!e.ctrlKey && !e.metaKey && e.key.toLowerCase() === 'd') chooseTool('door')
    }
    window.addEventListener('keydown', key)
    return () => window.removeEventListener('keydown', key)
  }, [save, doUndo, doRedo, remove, dialog])
  const download = (contents: string, filename: string, type: string) => {
    const url = URL.createObjectURL(new Blob([contents], { type }))
    const anchor = document.createElement('a')
    anchor.href = url; anchor.download = filename; anchor.click()
    setTimeout(() => URL.revokeObjectURL(url), 1000)
    setMenu(false); setDialog(null)
  }
  const place = (p: Point) => {
    try {
      if (tool === 'wall' && !start) { setStart({ x: snap(p.x), z: snap(p.z) }); setMessage(''); return }
      const next = tool === 'wall' && start ? wallFromPoints(start, p, crypto.randomUUID()) : placeDoor(project, p, crypto.randomUUID())
      update({ ...project, elements: [...project.elements, next] })
      setSelected(next.id); setStart(null); setTool('select')
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to place element.') }
  }
  const focusCategory = (category: Element['category']) => {
    const el = project.elements.find(e => e.category === category)
    if (el) { setSelected(el.id); setTool('select'); setMessage('') }
  }
  const flip = (key: string) => setExpanded({ ...expanded, [key]: !expanded[key] })
  const viewButton = (next: View) => <button key={next} className={`browser-view ${view === next ? 'current' : ''}`} onClick={() => changeView(next)}><Icon name={viewIcons[next]} size={14}/>{viewLabels[next]}</button>
  const exportJSON = () => download(serializeProject(project), 'alder-pavilion.veyra.json', 'application/json')
  return <div className="app-shell">
    <header className="titlebar">
      <span className="app-mark">V</span><div className="quick-access"><button title="Open project" aria-label="Open project" onClick={() => fileInput.current?.click()}><Icon name="open" size={16}/></button><button title="Save (Ctrl+S)" aria-label="Save" onClick={save}><Icon name="save" size={16}/></button><span className="quick-divider"/><button title="Undo (Ctrl+Z)" aria-label="Undo" disabled={!history.past.length} onClick={doUndo}><Icon name="undo" size={15}/></button><button title="Redo (Ctrl+Shift+Z)" aria-label="Redo" disabled={!history.future.length} onClick={doRedo}><Icon name="redo" size={15}/></button><span className="quick-divider"/><button title="Default 3D view" onClick={() => { changeView('3D'); orient('home') }}><Icon name="home" size={16}/></button></div>
      <div className="window-title"><strong>Veyra</strong><span> · </span>{project.name}<span> — {view === '3D' ? '3D View: {3D}' : view === 'Level 1' ? 'Floor Plan: Level 1' : 'Elevation: South'}</span></div>
      <div className="title-right"><span className="local-dot"/><span>Local workspace</span><button aria-label="About Veyra" title="About Veyra" onClick={() => setDialog('about')}><Icon name="info" size={15}/></button><span className="avatar">AD</span></div>
    </header>
    <nav className="ribbon-tabs" aria-label="Ribbon tabs"><button className={`file-tab ${menu ? 'chosen' : ''}`} onClick={() => setMenu(!menu)}>File</button>{['Architecture', 'Structure', 'Insert', 'Annotate', 'Massing & Site', 'View', 'Manage', 'Modify'].map(name => <button key={name} className={tab === name ? 'chosen' : ''} onClick={() => { setTab(name); setMenu(false) }}>{name}</button>)}<span className="ribbon-context">{tool !== 'select' ? `Modify | Place ${tool === 'wall' ? 'Wall' : 'Door'}` : element ? `Modify | ${element.category}s` : ''}</span><span className="project-version">ALDER / A–001</span></nav>
    <div className={`ribbon ${tool !== 'select' ? 'contextual' : ''}`}>
      <RibbonGroup title="Select"><Tool icon="select" active={tool === 'select'} onClick={() => chooseTool('select')}>Modify</Tool></RibbonGroup>
      {tab === 'Architecture' || tab === 'Structure' || tab === 'Modify' ? <>
        <RibbonGroup title="Properties"><Tool icon="layers" onClick={() => setDialog('visibility')}>Properties</Tool></RibbonGroup>
        <RibbonGroup title={tab === 'Structure' ? 'Structure' : 'Build'}>
          <Tool icon="wall" active={tool === 'wall'} onClick={() => chooseTool('wall')} title="Place Wall (W)">Wall⌄</Tool>
          <Tool icon="door" active={tool === 'door'} onClick={() => chooseTool('door')} title="Place Door (D)">Door</Tool>
          <Tool icon="window" onClick={() => focusCategory('Curtain Wall')}>Curtain<br/>Wall</Tool>
          <Tool icon="furniture" onClick={() => focusCategory('Furniture')}>Component</Tool>
          <Tool icon="column" disabled>Column</Tool>
          <Tool icon="roof" onClick={() => focusCategory('Roof')}>Roof⌄</Tool>
          <Tool icon="floor" onClick={() => focusCategory('Floor')}>Floor⌄</Tool>
          <div className="tool-stack"><Tool icon="window" small onClick={() => focusCategory('Curtain Wall')}>Curtain System</Tool><Tool icon="column" small onClick={() => focusCategory('Timber Fins')}>Timber Screen</Tool><Tool icon="grid" small disabled>Mullion</Tool></div>
        </RibbonGroup>
        <RibbonGroup title="Circulation"><Tool icon="stairs" disabled>Stair</Tool><div className="tool-stack"><Tool icon="stairs" small disabled>Railing</Tool><Tool icon="floor" small disabled>Ramp</Tool></div></RibbonGroup>
        <RibbonGroup title="Model"><Tool icon="text" disabled>Model<br/>Text</Tool><Tool icon="room" disabled>Model<br/>Group</Tool></RibbonGroup>
        <RibbonGroup title="Datum"><div className="tool-stack"><Tool icon="elevation" small onClick={() => changeView('South')}>Level</Tool><Tool icon="grid" small onClick={() => setDimensions(!dimensions)}>Grid</Tool><Tool icon="measure" small onClick={() => setDimensions(!dimensions)}>Dimensions</Tool></div></RibbonGroup>
        <RibbonGroup title="Modify"><Tool icon="delete" disabled={!element} onClick={remove}>Delete</Tool></RibbonGroup>
      </> : tab === 'View' ? <>
        <RibbonGroup title="Create"><Tool icon="cube" onClick={() => changeView('3D')}>3D View</Tool><Tool icon="plan" onClick={() => changeView('Level 1')}>Floor Plan</Tool><Tool icon="elevation" onClick={() => changeView('South')}>Elevation</Tool></RibbonGroup>
        <RibbonGroup title="Graphics"><Tool icon="eye" onClick={() => setDialog('visibility')}>Visibility /<br/>Graphics</Tool><Tool icon="sun" active={shadows} onClick={() => setShadows(!shadows)}>Shadows</Tool><Tool icon="cube" active={wireframe} onClick={() => setWireframe(!wireframe)}>Wireframe</Tool></RibbonGroup>
        <RibbonGroup title="Navigate"><Tool icon="home" onClick={() => orient('home')}>Fit to View</Tool><Tool icon="zoom" onClick={() => orient('in')}>Zoom In</Tool></RibbonGroup>
      </> : tab === 'Insert' ? <>
        <RibbonGroup title="Project"><Tool icon="open" onClick={() => fileInput.current?.click()}>Open<br/>Veyra JSON</Tool><Tool icon="export" onClick={exportJSON}>Download<br/>Project</Tool></RibbonGroup><RibbonGroup title="Link"><Tool icon="link" disabled>Link Revit</Tool><Tool icon="link" disabled>Link CAD</Tool><Tool icon="camera" disabled>Image</Tool></RibbonGroup>
      </> : tab === 'Annotate' ? <>
        <RibbonGroup title="Dimension"><Tool icon="measure" active={dimensions} onClick={() => setDimensions(!dimensions)}>Dimensions</Tool><Tool icon="grid" active={dimensions} onClick={() => setDimensions(!dimensions)}>Datum Grids</Tool></RibbonGroup><RibbonGroup title="Detail"><Tool icon="text" disabled>Text</Tool><Tool icon="room" disabled>Tag by<br/>Category</Tool></RibbonGroup><RibbonGroup title="Drawing"><Tool icon="export" onClick={() => download(exportPlan(project), 'alder-level-1.svg', 'image/svg+xml')}>Export Plan<br/>SVG</Tool></RibbonGroup>
      </> : tab === 'Massing & Site' ? <>
        <RibbonGroup title="Model Site"><Tool icon="tree" onClick={() => focusCategory('Landscape')}>Site<br/>Component</Tool><Tool icon="eye" onClick={() => setDialog('visibility')}>Site Visibility</Tool><Tool icon="floor" disabled>Toposolid</Tool></RibbonGroup><RibbonGroup title="Sun Study"><Tool icon="sun" active={shadows} onClick={() => setShadows(!shadows)}>Shadows</Tool></RibbonGroup>
      </> : <>
        <RibbonGroup title="Project"><Tool icon="save" onClick={save}>Save Project</Tool><Tool icon="export" onClick={() => setDialog('export')}>Export</Tool><Tool icon="layers" onClick={() => setDialog('visibility')}>Object<br/>Visibility</Tool></RibbonGroup><RibbonGroup title="Settings"><Tool icon="home" onClick={() => setDialog('reset')}>Reset Sample</Tool><Tool icon="info" onClick={() => setDialog('about')}>About</Tool></RibbonGroup>
      </>}
      <div className="ribbon-end"><span>⌃</span></div>
    </div>
    <div className={`optionsbar ${tool !== 'select' ? 'placing-options' : ''}`}><span>{tool === 'select' ? 'Modify' : `Place ${tool === 'wall' ? 'Wall' : 'Door'}`}</span><i/>{tool === 'wall' ? <><span>Location Line: <b>Wall Centerline</b></span><span>Height: <b>3.600 m</b></span><span>Snap: <b>0.500 m</b></span></> : tool === 'door' ? <><span>Type: <b>Single Flush · 1200 × 2400 mm</b></span><span>Placement: <b>Wall hosted</b></span></> : <><span className="muted">Select an element to edit its properties</span><span className="options-project"><span className="green-dot"/>All changes saved to this device</span></>}</div>
    <main className="workspace">
      <aside className="left-dock">
        <section className="properties-panel"><div className="panel-heading"><span>Properties</span><span>⌄</span></div>
          {element ? <ElementProperties element={element} apply={next => { try { update(updateElement(project, next)); setMessage('Element properties applied.') } catch (error) { setMessage(error instanceof Error ? error.message : 'Invalid properties.') } }} clear={() => setSelected(null)}/> : <>
            <div className="type-selector"><div className="type-thumbnail"><Icon name={viewIcons[view]} size={43}/></div><div><span>{view === '3D' ? '3D View' : view === 'Level 1' ? 'Floor Plan' : 'Elevation'}</span><strong>{view === '3D' ? 'Architectural Perspective' : view === 'Level 1' ? 'Level 1 · General Arrangement' : 'South · Building Elevation'}</strong></div><span className="down">⌄</span></div>
            <div className="type-description"><span>{view === '3D' ? '3D View' : view} : {viewLabels[view]}</span><button onClick={() => setDialog('visibility')}>Edit…</button></div>
            <div className="view-properties"><PropertySection title="Graphics"><PropertyRow label="View Scale"><span>1 : 100</span></PropertyRow><PropertyRow label="Detail Level"><span>Fine</span></PropertyRow><PropertyRow label="Parts Visibility"><span>Show Original</span></PropertyRow><PropertyRow label="Visibility/Graphics"><button onClick={() => setDialog('visibility')}>Edit…</button></PropertyRow><PropertyRow label="Visual Style"><select aria-label="Visual Style" value={wireframe ? 'Wireframe' : 'Realistic'} onChange={e => setWireframe(e.target.value === 'Wireframe')}><option>Realistic</option><option>Wireframe</option></select></PropertyRow><PropertyRow label="Shadows"><input type="checkbox" aria-label="Shadows" checked={shadows} onChange={e => setShadows(e.target.checked)}/></PropertyRow></PropertySection>
            <PropertySection title="Extents"><PropertyRow label="Crop View"><span className="readonly">No</span></PropertyRow><PropertyRow label="Section Box"><span className="readonly">No</span></PropertyRow></PropertySection>
            <PropertySection title="Identity Data"><PropertyRow label="View Name"><span>{viewLabels[view]}</span></PropertyRow><PropertyRow label="Discipline"><span>Architectural</span></PropertyRow><PropertyRow label="Phase"><span>New Construction</span></PropertyRow></PropertySection></div><div className="apply-row"><span>View properties</span><button disabled>Apply</button></div>
          </>}
        </section>
        <section className="project-browser"><div className="panel-heading"><span>Project Browser — Alder Pavilion</span><span>⌄</span></div><label className="browser-search"><Icon name="search" size={13}/><input aria-label="Search project browser" placeholder="Search views and elements" value={search} onChange={e => setSearch(e.target.value)}/>{search && <button aria-label="Clear search" onClick={() => setSearch('')}>×</button>}</label>
          <div className="browser-tree">{search ? <div className="search-results">{(['3D', 'Level 1', 'South'] as View[]).filter(v => v.toLowerCase().includes(search.toLowerCase())).map(viewButton)}{project.elements.filter(e => `${e.name} ${e.category}`.toLowerCase().includes(search.toLowerCase())).map(e => <button key={e.id} className={`element-result ${selected === e.id ? 'current' : ''}`} onClick={() => select(e.id)}><Icon name={categoryIcons[e.category]} size={14}/><span>{e.name}</span></button>)}{!project.elements.some(e => `${e.name} ${e.category}`.toLowerCase().includes(search.toLowerCase())) && !['3D', 'Level 1', 'South'].some(v => v.toLowerCase().includes(search.toLowerCase())) && <p className="empty-search">No matching views or elements.</p>}</div> : <>
            <button className="tree-heading" onClick={() => flip('Views')}><span>{expanded.Views ? '−' : '+'}</span><Icon name="layers" size={13}/>Views (all)</button>{expanded.Views && <div className="tree-branch">{[['Floor Plans', 'Level 1'], ['3D Views', '3D'], ['Elevations', 'South']].map(([group, v]) => <div key={group}><button className="tree-heading" onClick={() => flip(group)}><span>{expanded[group] ? '−' : '+'}</span>{group === 'Elevations' ? 'Elevations (Building Elevation)' : group}</button>{expanded[group] && viewButton(v as View)}</div>)}</div>}
            <button className="tree-heading" onClick={() => setDialog('export')}><span>+</span><Icon name="plan" size={13}/>Schedules / Quantities</button>
            <button className="tree-heading" onClick={() => flip('Elements')}><span>{expanded.Elements ? '−' : '+'}</span><Icon name="cube" size={13}/>Model Elements ({project.elements.length})</button>{expanded.Elements && <div className="tree-branch">{categories.map(c => <div key={c}><button className="tree-heading" onClick={() => flip(c)}><span>{expanded[c] ? '−' : '+'}</span>{c} ({project.elements.filter(e => e.category === c).length})</button>{expanded[c] && project.elements.filter(e => e.category === c).map(e => <button className={`element-result ${selected === e.id ? 'current' : ''}`} key={e.id} onClick={() => select(e.id)}>{e.name}</button>)}</div>)}</div>}
            <button className="tree-heading" onClick={() => setDialog('visibility')}><span>+</span><Icon name="eye" size={13}/>Visibility / Graphics</button>
          </>}</div>
          <div className="browser-footer"><Icon name="cube" size={13}/><span>{project.elements.length} model elements</span><span className="local-dot"/></div>
        </section>
      </aside>
      <section className="drawing-workspace">
        <div className="view-tabs" role="tablist" aria-label="Project views">{(['3D', 'Level 1', 'South'] as View[]).map(v => <button key={v} role="tab" aria-selected={view === v} className={view === v ? 'active' : ''} onClick={() => changeView(v)}><Icon name={viewIcons[v]} size={14}/><span>{viewLabels[v]}</span><span className="view-dot">{v === view ? '●' : ''}</span></button>)}<span className="view-tabs-end">⌄</span></div>
        <div className="canvas-area">
          {view === '3D' ? <Scene project={project} selected={selected} onSelect={select} action={cameraAction} shadows={shadows} wireframe={wireframe}/> : <Drawing project={project} selected={selected} onSelect={select} view={view} tool={tool} onPoint={place} start={start} dimensions={dimensions} zoom={zoom}/>}
          <div className="viewport-heading"><div><span className="project-kicker">ALDER CULTURAL PAVILION</span><span className="view-description">{view === '3D' ? 'Architectural coordination' : view === 'Level 1' ? 'General arrangement · Level 1' : 'Building elevations · South'}</span></div><span className="phase-chip">NEW CONSTRUCTION</span></div>
          {view === '3D' && <div className="view-cube"><button className="cube-home" aria-label="Home view" onClick={() => orient('home')}><Icon name="home" size={17}/></button><svg viewBox="0 0 110 100" aria-label="View cube"><g><path d="m55 12 37 19-37 20-37-20Z" className="cube-top" onClick={() => orient('top')} role="button" tabIndex={0} aria-label="Top view" onKeyDown={e => e.key === 'Enter' && orient('top')}/><path d="m18 31 37 20v40L18 70Z" className="cube-front" onClick={() => orient('front')} role="button" tabIndex={0} aria-label="Front view" onKeyDown={e => e.key === 'Enter' && orient('front')}/><path d="m55 51 37-20v39L55 91Z" className="cube-right" onClick={() => orient('right')} role="button" tabIndex={0} aria-label="Right view" onKeyDown={e => e.key === 'Enter' && orient('right')}/><text x="55" y="35" textAnchor="middle" pointerEvents="none">TOP</text><text x="36" y="62" textAnchor="middle" transform="rotate(28 36 62)" pointerEvents="none">FRONT</text><text x="75" y="62" textAnchor="middle" transform="rotate(-28 75 62)" pointerEvents="none">RIGHT</text></g></svg><div className="compass"><span>W</span><span>S</span><span>E</span></div></div>}
          <div className="navigation-bar"><button title="Fit to view" aria-label="Fit to view" onClick={() => orient('home')}><Icon name="home" size={19}/></button><i/><button title="Zoom in" aria-label="Zoom in" onClick={() => orient('in')}>＋</button><button title="Zoom out" aria-label="Zoom out" onClick={() => orient('out')}>−</button><i/><button title="Visibility / Graphics" aria-label="Visibility / Graphics" onClick={() => setDialog('visibility')}><Icon name="eye" size={18}/></button></div>
          {tool !== 'select' && <div className="placement-guide"><span className="guide-icon"><Icon name={tool} size={19}/></span><div><strong>{tool === 'wall' ? start ? 'Pick the wall end point' : 'Pick the wall start point' : 'Choose a host wall'}</strong><span>{tool === 'wall' ? 'Snaps to a 0.5 m grid · click two points' : 'Click within 1 m of an existing wall'}</span></div><button onClick={() => chooseTool('select')}>Esc</button></div>}
          {message && <div className="feedback" role="status"><Icon name="info" size={16}/><span>{message}</span><button aria-label="Dismiss message" onClick={() => setMessage('')}>×</button></div>}
          <div className="viewport-footer"><div className="north-symbol"><span>N</span><svg viewBox="0 0 30 36"><path d="M15 2 7 31l8-7 8 7Z" fill="none" stroke="currentColor"/><path d="M15 2v22l-8 7Z" fill="currentColor"/></svg></div><div className="model-caption"><strong>{view === '3D' ? 'ALDER / 01' : view === 'Level 1' ? 'A–101 / 01' : 'A–201 / 02'}</strong><span>{view === '3D' ? 'SOUTHEAST AXONOMETRIC' : view === 'Level 1' ? 'FLOOR PLAN' : 'SOUTH ELEVATION'}</span></div>{view === '3D' && <div className="scale-bar"><span>0</span><i/><span>5</span><i/><span>10 m</span></div>}</div>
        </div>
        <div className="view-controls"><span className="scale-label">1 : 100</span><button title="Detail level: Fine" disabled><Icon name="grid" size={15}/></button><button title={wireframe ? 'Switch to realistic' : 'Switch to wireframe'} onClick={() => setWireframe(!wireframe)} className={wireframe ? 'active' : ''}><Icon name="cube" size={16}/></button><button title="Toggle shadows" onClick={() => setShadows(!shadows)} className={shadows ? 'active' : ''}><Icon name="sun" size={16}/></button><button title="Toggle datum dimensions" onClick={() => setDimensions(!dimensions)} className={dimensions ? 'active' : ''}><Icon name="measure" size={16}/></button><button title="Visibility categories" onClick={() => setDialog('visibility')}><Icon name="eye" size={16}/></button><i/><span>{view === '3D' ? 'Real-time 3D' : 'Coordinated drawing'}</span><span className="view-control-right">{view === '3D' ? 'Drag to orbit  ·  Right-drag to pan  ·  Scroll to zoom' : tool !== 'select' ? 'Click to place  ·  Esc to cancel' : 'Click an element to select  ·  W wall  ·  D door'}</span></div>
      </section>
    </main>
    <footer className="statusbar"><span>{element ? `${element.category} : ${element.name} : ${element.id}` : tool === 'select' ? 'Ready · Click an element to select it' : start ? 'Click to define wall end point' : 'Click to place an element'}</span><div><span className="green-dot"/>{saveState}<i/><span>Main Model</span><i/><Icon name="layers" size={14}/><span>{element ? '1' : '0'} selected</span></div></footer>
    <input ref={fileInput} type="file" accept=".json,application/json" className="hidden" onChange={async e => {
      const file = e.target.files?.[0]
      if (!file) return
      try { if (file.size > 2_000_000) throw new Error('Project file exceeds 2 MB.'); const next = parseProject(await file.text()); update(next); setAllowSave(true); setSelected(null); setMenu(false); setMessage('Project opened. Undo restores the previous model.') } catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to open project.') }
      e.target.value = ''
    }}/>
    {menu && <><button className="menu-dismiss" aria-label="Close File menu" onClick={() => setMenu(false)}/><div className="file-menu"><h3>Project</h3><button onClick={() => { save(); setMenu(false) }}><Icon name="save"/>Save<span>Ctrl+S</span></button><button onClick={() => fileInput.current?.click()}><Icon name="open"/>Open Veyra project…</button><button onClick={exportJSON}><Icon name="export"/>Download project JSON</button><button onClick={() => { setMenu(false); setDialog('export') }}><Icon name="plan"/>Export drawings & schedule…</button><hr/><button onClick={() => { setMenu(false); setDialog('reset') }}><Icon name="home"/>Reset sample project…</button><div className="file-menu-note">Saved on this device.<br/>Download a project to share or back up.</div></div></>}
    <dialog ref={dialogRef} onCancel={() => setDialog(null)} className="app-dialog">
      <div className="dialog-title"><span>{dialog === 'visibility' ? 'Visibility / Graphic Overrides' : dialog === 'reset' ? 'Reset sample project' : dialog === 'about' ? 'About Veyra' : 'Export project'}</span><button aria-label="Close dialog" onClick={() => setDialog(null)}>×</button></div>
      {dialog === 'visibility' ? <><div className="dialog-body"><p>Model categories</p><span className="dialog-explanation">Visibility is coordinated across all three views and saved with the project.</span><div className="visibility-table"><div><span>Visible</span><span>Category</span><span>Elements</span></div>{categories.map(c => <label key={c}><input type="checkbox" aria-label={`${c} visibility`} checked={!project.hidden.includes(c)} onChange={e => update({ ...project, hidden: e.target.checked ? project.hidden.filter(h => h !== c) : [...project.hidden, c] })}/><span><Icon name={categoryIcons[c]} size={16}/>{c}</span><span>{project.elements.filter(e => e.category === c).length}</span></label>)}</div><button onClick={() => update({ ...project, hidden: [] })}>Show all categories</button></div><div className="dialog-actions"><button className="primary" onClick={() => setDialog(null)}>Done</button></div></> : dialog === 'reset' ? <><div className="dialog-body"><p>Restore the original Alder Cultural Pavilion?</p><span className="dialog-explanation">Your current model will be replaced. You can undo this action or download a backup first.</span></div><div className="dialog-actions"><button onClick={exportJSON}>Download backup</button><button onClick={() => setDialog(null)}>Cancel</button><button className="primary" onClick={() => { update(createProject()); setAllowSave(true); setSelected(null); setTool('select'); setStart(null); setDialog(null); changeView('3D'); orient('home') }}>Reset sample</button></div></> : dialog === 'about' ? <><div className="dialog-body"><h2>Veyra <span>1.0</span></h2><p>A thoughtful space for architecture.</p><p className="dialog-explanation">An independent browser BIM demo inspired by the Autodesk Revit 2025.1 desktop workspace. All geometry and interface artwork are original. Autodesk Revit is a trademark of Autodesk; Veyra is not affiliated with Autodesk.</p><p className="dialog-explanation">Local JSON projects, SVG floor plans and CSV schedules. Native RVT/IFC, worksharing, analysis, sheets and commercial render engines are outside this V1. Gray ribbon controls are unavailable.</p></div><div className="dialog-actions"><button className="primary" onClick={() => setDialog(null)}>Close</button></div></> : <><div className="dialog-body"><p>Export {project.name}</p><span className="dialog-explanation">Exports use the current model, including your edits.</span><div className="export-options"><button onClick={exportJSON}><Icon name="cube" size={28}/><div><strong>Veyra project</strong><span>Editable model · .veyra.json</span></div><span>↓</span></button><button onClick={() => download(exportPlan(project), 'alder-level-1.svg', 'image/svg+xml')}><Icon name="plan" size={28}/><div><strong>Level 1 floor plan</strong><span>Visible geometry in metres · .svg</span></div><span>↓</span></button><button onClick={() => download(exportSchedule(project), 'alder-model-schedule.csv', 'text/csv')}><Icon name="layers" size={28}/><div><strong>Model schedule</strong><span>{project.elements.length} elements · quantities · .csv</span></div><span>↓</span></button></div></div><div className="dialog-actions"><button onClick={() => setDialog(null)}>Cancel</button></div></>}
    </dialog>
  </div>
}
export default App
