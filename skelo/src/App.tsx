import { useEffect, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import { Icon } from './Icon'
import type { IconName } from './Icon'
import { Viewport } from './Viewport'
import type { Tool, ViewportApi } from './Viewport'
import { allTags, commit, createProject, createVolume, groupEntities, materials, parseMeasurements, parseProject, redo, selectionFor, serializeProject, standardViews, STORAGE_KEY, tagNames, undo, ungroupEntities, updateEntity, volume } from './model'
import type { Entity, History, MaterialId, Project, Tag, Vec3 } from './model'

const toolLabels: Record<Tool, string> = { select: 'Select', rectangle: 'Rectangle', pull: 'Push/Pull', paint: 'Paint Bucket', orbit: 'Orbit', pan: 'Pan', zoom: 'Zoom' }
const instructions: Record<Tool, string> = {
  select: 'Select objects. Shift = add to selection. Middle drag = orbit. Right drag = pan.',
  rectangle: 'Click two corners on the ground, or enter width, depth, height in Measurements.',
  pull: 'Click an object and drag up/down, or enter its height in Measurements.',
  paint: 'Choose a material, then click an object to paint it.',
  orbit: 'Drag to orbit around your model. Scroll to zoom. Right drag to pan.',
  pan: 'Drag to move your view. Scroll to zoom.',
  zoom: 'Click to zoom in. Shift-click to zoom out. Scroll for smooth zoom.',
}
function download(content: string, filename: string, type: string) {
  const url = URL.createObjectURL(new Blob([content], { type }))
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  anchor.click()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
function Button({ icon, label, onClick, active, disabled, compact = false }: { icon: IconName; label: string; onClick: () => void; active?: boolean; disabled?: boolean; compact?: boolean }) {
  return <button className={`tool-button ${active ? 'active' : ''} ${compact ? 'compact' : ''}`} title={label} aria-label={label} aria-pressed={active === undefined ? undefined : active} disabled={disabled} onClick={onClick}><Icon name={icon} size={compact ? 20 : 26} /></button>
}
function Panel({ title, children, initial = true }: { title: string; children: ReactNode; initial?: boolean }) {
  const [open, setOpen] = useState(initial)
  return <section className="tray-panel"><button className="panel-heading" aria-expanded={open} onClick={() => setOpen(!open)}><span className="disclosure">{open ? '▾' : '▸'}</span>{title}<span className="panel-grip">⋮</span></button>{open && <div className="panel-content">{children}</div>}</section>
}
function EntityEditor({ entity, onUpdate }: { entity: Entity; onUpdate: (patch: Partial<Pick<Entity, 'name' | 'size' | 'tag'>>) => void }) {
  const [name, setName] = useState(entity.name)
  const [size, setSize] = useState(entity.size.map(String))
  useEffect(() => { setName(entity.name); setSize(entity.size.map(String)) }, [entity])
  return <>
    <div className="entity-kind"><Icon name="cube" size={20} /><b>{entity.kind === 'volume' ? 'Solid component' : 'Component'}</b><span>{entity.group ? 'Grouped' : 'Unlocked'}</span></div>
    <label className="field-row"><span>Name</span><input aria-label="Entity name" maxLength={100} value={name} onChange={e => setName(e.target.value)} onBlur={() => { onUpdate({ name }); setName(entity.name) }} onKeyDown={e => { if (e.key === 'Enter') e.currentTarget.blur() }} /></label>
    <label className="field-row"><span>Tag</span><select aria-label="Entity tag" value={entity.tag} onChange={e => onUpdate({ tag: e.target.value as Tag })}>{tagNames.map(t => <option key={t}>{t}</option>)}</select></label>
    <div className="dimensions">{['Width', 'Height', 'Depth'].map((label, i) => <label key={label}><span>{label} <small>m</small></span><input type="number" aria-label={label} min=".05" max="50" step=".1" value={size[i]} onChange={e => setSize(size.map((v, j) => i === j ? e.target.value : v))} onBlur={() => { onUpdate({ size: size.map(Number) as Vec3 }); setSize(entity.size.map(String)) }} onKeyDown={e => { if (e.key === 'Enter') e.currentTarget.blur() }} /></label>)}</div>
    <div className="entity-meta"><span>Bounding volume</span><span>{volume(entity).toFixed(2)} m³</span></div>
  </>
}

export default function App() {
  const [loadWarning] = useState(() => {
    try { const saved = localStorage.getItem(STORAGE_KEY); if (saved) parseProject(saved); return '' } catch { return 'The saved project could not be read. The built-in house is loaded; import a backup to recover your work.' }
  })
  const [history, setHistory] = useState<History>(() => {
    try { const saved = localStorage.getItem(STORAGE_KEY); return { past: [], present: saved ? parseProject(saved) : createProject(), future: [] } } catch { return { past: [], present: createProject(), future: [] } }
  })
  const project = history.present
  const [selected, setSelected] = useState<string[]>([])
  const [tool, setTool] = useState<Tool>('select')
  const [activeMaterial, setActiveMaterial] = useState<MaterialId>('cedar')
  const [materialQuery, setMaterialQuery] = useState('')
  const [materialFamily, setMaterialFamily] = useState('In Model')
  const [measurements, setMeasurements] = useState('')
  const [hint, setHint] = useState('')
  const [status, setStatus] = useState('Saved locally')
  const [notice, setNotice] = useState(loadWarning)
  const [menu, setMenu] = useState<string | null>(null)
  const [dialog, setDialog] = useState<'scene' | 'reset' | 'help' | null>(null)
  const [sceneName, setSceneName] = useState('')
  const [sceneError, setSceneError] = useState('')
  const [activeScene, setActiveScene] = useState('scene-1')
  const [viewName, setViewName] = useState('Perspective')
  const [outlinerSearch, setOutlinerSearch] = useState('')
  const viewport = useRef<ViewportApi | null>(null)
  const inputFile = useRef<HTMLInputElement>(null)
  const dialogRef = useRef<HTMLDialogElement>(null)
  const restoreView = useRef(false)
  const entity = project.entities.find(e => e.id === selected[0])
  const paint = materials.find(m => m.id === activeMaterial)!
  const change = (next: Project) => setHistory(h => commit(h, next))
  const safe = (action: () => void) => { try { action(); setNotice('') } catch (e) { setNotice(e instanceof Error ? e.message : 'This change could not be applied.') } }
  const selectTool = (next: Tool) => { setTool(next); setHint(''); setMeasurements(''); setMenu(null) }
  const setView = (name: string) => {
    const view = standardViews[name]
    if (name === 'Courtyard') viewport.current?.setView(view.position, view.target)
    else viewport.current?.fit(view.position.map((n, i) => n - view.target[i]) as Vec3)
    setViewName(name)
    setActiveScene('')
    setMenu(null)
  }
  const fitModel = () => { viewport.current?.fit(); setActiveScene(''); setMenu(null) }
  const saveProject = () => { download(serializeProject(project), `${project.name.replace(/[^\w-]+/g, '-')}.skelo.json`, 'application/json'); setHint('Project exported. All objects, materials, tags and scenes are included.') }
  const deleteSelected = () => { change({ ...project, entities: project.entities.filter(e => !selected.includes(e.id)) }); setSelected([]) }
  const makeGroup = () => safe(() => { change(groupEntities(project, selected)); setHint(`${selected.length} components grouped. Click any member to select the assembly.`) })
  const paintSelected = () => { if (selected.length) change(updateEntity(project, selected, { material: activeMaterial })) }
  const onSelect = (id: string | null, additive: boolean) => {
    if (!id) { if (!additive) setSelected([]); return }
    const ids = selectionFor(project, id)
    setSelected(previous => additive ? ids.every(i => previous.includes(i)) ? previous.filter(i => !ids.includes(i)) : [...new Set([...previous, ...ids])] : ids)
    setHint('')
  }
  const onPull = (id: string, height: number) => safe(() => {
    const object = project.entities.find(e => e.id === id)!
    change(updateEntity(project, [id], { size: [object.size[0], height, object.size[2]] }))
    setHint(`Push/Pull · ${height.toFixed(2)} m`)
  })
  const onRectangle = (a: Vec3, b: Vec3) => safe(() => {
    const next = createVolume(project, a, b)
    change(next)
    setSelected([next.entities.at(-1)!.id])
    selectTool('pull')
    setHint('Volume created. Drag to Push/Pull, or enter a precise height below.')
  })
  const applyMeasurements = () => safe(() => {
    if (tool === 'rectangle') {
      const [w, d, h] = parseMeasurements(measurements, 'rectangle')
      const next = createVolume(project, [8, .7, 6.5], [8 + w, .7, 6.5 + d], h)
      change(next)
      setSelected([next.entities.at(-1)!.id])
      selectTool('pull')
      setHint(`Volume created · ${w} × ${d} × ${h} m`)
    } else if (entity) {
      const [height] = parseMeasurements(measurements, 'height')
      onPull(entity.id, height)
      setMeasurements('')
    } else throw new Error('Select an object, or choose Rectangle to create a measured volume.')
  })
  const recallScene = (id: string) => {
    const scene = project.scenes.find(s => s.id === id)!
    viewport.current?.setView(scene.position, scene.target)
    change({ ...project, tags: { ...scene.tags } })
    setActiveScene(id)
    setViewName(scene.name.includes('Plan') ? 'Top' : 'Perspective')
  }
  const saveScene = () => {
    if (!sceneName.trim()) { setSceneError('Enter a scene name.'); return }
    if (project.scenes.length >= 30) { setSceneError('This project supports up to 30 scenes.'); return }
    const camera = viewport.current?.camera()
    if (!camera) { setSceneError('The viewport is not ready yet.'); return }
    const id = crypto.randomUUID()
    change({ ...project, scenes: [...project.scenes, { id, name: sceneName.trim(), ...camera, tags: { ...project.tags } }] })
    setActiveScene(id)
    setDialog(null)
  }
  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, serializeProject(project)); setStatus('Saved locally') } catch { setStatus('Save unavailable'); setNotice('Browser storage is full or disabled. Use File → Save project to keep a backup.') }
    if (restoreView.current) { setView('Perspective'); setActiveScene('scene-1'); restoreView.current = false }
  }, [project])
  useEffect(() => {
    setSceneError('')
    if (dialog) dialogRef.current?.showModal()
    else dialogRef.current?.close()
  }, [dialog])
  useEffect(() => {
    const keyboard = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement || e.target instanceof HTMLSelectElement || dialog) return
      if (e.ctrlKey || e.metaKey) {
        if (e.key.toLowerCase() === 'z') { e.preventDefault(); setHistory(h => e.shiftKey ? redo(h) : undo(h)) }
        if (e.key.toLowerCase() === 'y') { e.preventDefault(); setHistory(redo) }
        if (e.key.toLowerCase() === 's') { e.preventDefault(); saveProject() }
        if (e.key.toLowerCase() === 'g') { e.preventDefault(); makeGroup() }
        return
      }
      const shortcuts: Record<string, Tool> = { ' ': 'select', r: 'rectangle', p: 'pull', b: 'paint', o: 'orbit', h: 'pan', z: 'zoom' }
      if (shortcuts[e.key.toLowerCase()]) { e.preventDefault(); selectTool(shortcuts[e.key.toLowerCase()]) }
      if (e.key === 'Escape') { setSelected([]); setMenu(null); selectTool('select') }
      if (e.key === 'Delete' && selected.length) deleteSelected()
    }
    window.addEventListener('keydown', keyboard)
    return () => window.removeEventListener('keydown', keyboard)
  })
  const menus: Record<string, { name: string; shortcut?: string; action?: () => void; disabled?: boolean }[]> = {
    File: [
      { name: 'Open project…', shortcut: 'JSON', action: () => inputFile.current?.click() },
      { name: 'Save project', shortcut: 'Ctrl+S', action: saveProject },
      { name: 'Export 3D model…', shortcut: 'OBJ', action: () => { if (viewport.current) download(viewport.current.exportObj(), 'Komorebi-House.obj', 'text/plain') } },
      { name: 'Restore built-in house…', action: () => setDialog('reset') },
    ],
    Edit: [
      { name: 'Undo', shortcut: 'Ctrl+Z', action: () => setHistory(undo), disabled: !history.past.length },
      { name: 'Redo', shortcut: 'Ctrl+Y', action: () => setHistory(redo), disabled: !history.future.length },
      { name: 'Make Group', shortcut: 'Ctrl+G', action: makeGroup, disabled: selected.length < 2 },
      { name: 'Ungroup', action: () => change(ungroupEntities(project, selected)), disabled: !entity?.group },
      { name: 'Delete selection', shortcut: 'Del', action: deleteSelected, disabled: !selected.length },
    ],
    View: [
      { name: `${project.edges ? '✓ ' : ''}Edges`, action: () => change({ ...project, edges: !project.edges }) },
      { name: `${project.axes ? '✓ ' : ''}Axes`, action: () => change({ ...project, axes: !project.axes }) },
      { name: `${project.shadows ? '✓ ' : ''}Shadows`, action: () => change({ ...project, shadows: !project.shadows }) },
      { name: 'Show all tags', action: () => change({ ...project, tags: { ...allTags } }) },
    ],
    Camera: Object.keys(standardViews).map(name => ({ name, action: () => setView(name) })),
    Draw: [{ name: 'Rectangle', shortcut: 'R', action: () => selectTool('rectangle') }],
    Tools: (Object.keys(toolLabels) as Tool[]).map(t => ({ name: toolLabels[t], action: () => selectTool(t) })),
    Window: [{ name: 'Save current scene…', action: () => { setSceneName(`Scene ${project.scenes.length + 1}`); setDialog('scene') } }],
    Extensions: [{ name: 'Native extensions are not available in this browser V1', disabled: true }],
    Help: [{ name: 'Skelo modeling guide', action: () => setDialog('help') }],
  }
  return <main className="app-shell" onClick={() => { if (menu) setMenu(null) }}>
    <header className="titlebar"><div className="brand-mark"><Icon name="cube" size={22} /></div><strong>Skelo</strong><span className="title-divider" /><span>{project.name}.skelo</span><span className="title-tail">Architectural Design</span><div className="local-badge"><span />{status}</div></header>
    <nav className="menubar" aria-label="Application menus">{Object.keys(menus).map(name => <div className="menu-wrap" key={name}><button className={menu === name ? 'menu-active' : ''} onClick={e => { e.stopPropagation(); setMenu(menu === name ? null : name) }}>{name}</button>{menu === name && <div className="menu-popover">{menus[name].map(item => <button key={item.name} disabled={item.disabled} onClick={e => { e.stopPropagation(); item.action?.(); setMenu(null) }}><span>{item.name}</span><kbd>{item.shortcut}</kbd></button>)}</div>}</div>)}</nav>
    <div className="main-toolbar">
      <div className="toolbar-set"><Button icon="open" label="Open project" onClick={() => inputFile.current?.click()} /><Button icon="save" label="Save project" onClick={saveProject} /></div>
      <div className="toolbar-set"><Button icon="undo" label="Undo" onClick={() => setHistory(undo)} disabled={!history.past.length} /><Button icon="redo" label="Redo" onClick={() => setHistory(redo)} disabled={!history.future.length} /></div>
      <div className="toolbar-set">{(['select', 'rectangle', 'pull', 'paint'] as Tool[]).map(t => <Button key={t} icon={t} label={toolLabels[t]} active={tool === t} onClick={() => selectTool(t)} />)}</div>
      <div className="toolbar-set">{(['orbit', 'pan', 'zoom'] as Tool[]).map(t => <Button key={t} icon={t} label={toolLabels[t]} active={tool === t} onClick={() => selectTool(t)} />)}<Button icon="fit" label="Zoom extents" onClick={fitModel} /></div>
      <div className="toolbar-set view-set"><Button icon="home" label="Isometric view" onClick={() => setView('Perspective')} /><Button icon="top" label="Top view" onClick={() => setView('Top')} /><Button icon="front" label="Front view" onClick={() => setView('Front')} /><Button icon="right" label="Right view" onClick={() => setView('Right')} /></div>
      <div className="toolbar-set"><Button icon="sun" label="Toggle shadows" active={project.shadows} onClick={() => change({ ...project, shadows: !project.shadows })} /><Button icon="axes" label="Toggle axes" active={project.axes} onClick={() => change({ ...project, axes: !project.axes })} /></div>
      <span className="toolbar-spacer" /><button className="outlined-button save-scene" onClick={() => { setSceneName(`Scene ${project.scenes.length + 1}`); setDialog('scene') }}><Icon name="cube" size={17} />Save scene</button>
    </div>
    <div className="workspace">
      <aside className="left-palette" aria-label="Large Tool Set">
        <div className="palette-handle">⋮⋮⋮</div>
        <div className="palette-grid">{(['select', 'paint'] as Tool[]).map(t => <Button key={t} icon={t} label={`${toolLabels[t]} tool`} active={tool === t} onClick={() => selectTool(t)} />)}</div>
        <div className="palette-rule" />
        <div className="palette-grid"><Button icon="rectangle" label="Draw rectangle (R)" active={tool === 'rectangle'} onClick={() => selectTool('rectangle')} /><Button icon="pull" label="Push/Pull (P)" active={tool === 'pull'} onClick={() => selectTool('pull')} /><Button icon="group" label="Make Group" disabled={selected.length < 2} onClick={makeGroup} /><Button icon="trash" label="Delete selected" disabled={!selected.length} onClick={deleteSelected} /></div>
        <div className="palette-rule" />
        <div className="palette-grid">{(['orbit', 'pan', 'zoom'] as Tool[]).map(t => <Button key={t} icon={t} label={`${toolLabels[t]} tool`} active={tool === t} onClick={() => selectTool(t)} />)}<Button icon="fit" label="Fit model" onClick={fitModel} /></div>
        <div className="palette-rule" />
        <div className="palette-grid"><Button icon="top" label="Plan view" onClick={() => setView('Top')} /><Button icon="front" label="Elevation view" onClick={() => setView('Front')} /><Button icon="eye" label="Toggle edges" active={project.edges} onClick={() => change({ ...project, edges: !project.edges })} /><Button icon="axes" label="Show axes" active={project.axes} onClick={() => change({ ...project, axes: !project.axes })} /></div>
        <div className="palette-bottom"><Button icon="info" label="Modeling guide" onClick={() => setDialog('help')} /></div>
      </aside>
      <div className="model-area">
        <div className="scene-tabs" role="tablist" aria-label="Saved scenes">{project.scenes.map(scene => <button role="tab" key={scene.id} aria-selected={scene.id === activeScene} className={scene.id === activeScene ? 'selected' : ''} onClick={() => recallScene(scene.id)}>{scene.name}</button>)}<button className="add-scene" aria-label="Add scene" onClick={() => { setSceneName(`Scene ${project.scenes.length + 1}`); setDialog('scene') }}>+</button></div>
        <div className="canvas-wrap">
          <Viewport project={project} selected={selected} tool={tool} api={viewport} onSelect={onSelect} onRectangle={onRectangle} onPull={onPull} onPaint={id => { setSelected([id]); change(updateEntity(project, [id], { material: activeMaterial })) }} onHint={setHint} />
          <div className="view-label">{viewName}<span>Architectural style</span></div>
          <div className="view-controls"><button title="Zoom in" aria-label="Zoom in" onClick={() => viewport.current?.zoom(.83)}>+</button><button title="Zoom out" aria-label="Zoom out" onClick={() => viewport.current?.zoom(1.2)}>−</button><button title="Reset camera" aria-label="Reset camera" onClick={() => setView('Perspective')}><Icon name="home" size={19} /></button></div>
          <div className="model-caption"><strong>KOMOREBI HOUSE</strong><span>Kyoto, Japan · Courtyard residence</span></div>
          <div className="compass"><span className="north">N</span><svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="24" fill="none" stroke="#818b80" strokeWidth=".5"/><path d="m30 8-5 25 5-4 5 4Z" fill="#a8554e"/><path d="m30 52-5-19 5 4 5-4Z" fill="#84958b"/></svg></div>
          {notice && <div className="notice" role="alert"><Icon name="info" size={18} /><span>{notice}</span><button aria-label="Dismiss notice" onClick={() => setNotice('')}>×</button></div>}
        </div>
      </div>
      <aside className="default-tray" aria-label="Default Tray">
        <div className="tray-title">Default Tray<span>⌖</span></div>
        <div className="tray-scroll">
          <Panel title="Entity Info">{selected.length === 1 && entity ? <EntityEditor entity={entity} onUpdate={patch => safe(() => change(updateEntity(project, [entity.id], patch)))} /> : selected.length > 1 ? <div className="multi-selection"><Icon name="group" size={28} /><b>{selected.length} components selected</b><button className="outlined-button" onClick={makeGroup}>Make Group</button>{entity?.group && <button className="outlined-button" onClick={() => change(ungroupEntities(project, selected))}>Ungroup</button>}</div> : <div className="empty-selection"><Icon name="cube" size={33} /><div><b>No selection</b><p>Select an object to view its properties.</p></div></div>}<div className="panel-foot"><span>{project.entities.length} components in model</span><span>Meters</span></div></Panel>
          <Panel title="Materials">
            <div className="material-preview-row"><div className={`material-preview swatch-${paint.id}`} style={{ backgroundColor: paint.color }} /><div><b>{paint.name}</b><span>{paint.family} · In model</span><button className="text-button" disabled={!selected.length} onClick={paintSelected}>Paint selected</button></div></div>
            <div className="material-tabs"><span className="on">Select</span><span>In model collection</span><Icon name="home" size={16} /></div>
            <div className="material-filter"><select aria-label="Material category" value={materialFamily} onChange={e => setMaterialFamily(e.target.value)}>{['In Model', 'Wood', 'Stone', 'Metal', 'Color', 'Glass'].map(x => <option key={x}>{x}</option>)}</select><input aria-label="Search materials" placeholder="Search" value={materialQuery} onChange={e => setMaterialQuery(e.target.value)} /></div>
            <div className="swatches">{materials.filter(m => (materialFamily === 'In Model' || m.family === materialFamily) && m.name.toLowerCase().includes(materialQuery.toLowerCase())).map(m => <button key={m.id} className={`swatch swatch-${m.id} ${activeMaterial === m.id ? 'chosen' : ''}`} style={{ backgroundColor: m.color }} title={m.name} aria-label={m.name} aria-pressed={activeMaterial === m.id} onClick={() => { setActiveMaterial(m.id); selectTool('paint') }}><span>{m.family}</span></button>)}</div>
            {!materials.some(m => (materialFamily === 'In Model' || m.family === materialFamily) && m.name.toLowerCase().includes(materialQuery.toLowerCase())) && <p className="muted">No matching materials.</p>}
          </Panel>
          <Panel title="Tags">
            <div className="tag-table-head"><span>Visible</span><span>Name</span><span>Color</span></div>
            {tagNames.map((tag, i) => <label className="tag-row" key={tag}><input type="checkbox" aria-label={`Show ${tag}`} checked={project.tags[tag]} onChange={e => change({ ...project, tags: { ...project.tags, [tag]: e.target.checked } })} /><span>{tag}</span><i style={{ background: ['#b2bdc4', '#95a77d', '#c8ae86', '#84b6d4'][i] }} /></label>)}
          </Panel>
          <Panel title="Shadows">
            <div className="shadow-toggle"><label><input type="checkbox" checked={project.shadows} onChange={e => change({ ...project, shadows: e.target.checked })} />Display shadows</label><Icon name="sun" size={22} /></div>
            <label className="time-slider"><span>Time</span><input aria-label="Shadow time" type="range" min="6" max="18" step=".25" value={project.time} onChange={e => change({ ...project, time: Number(e.target.value) })} /><output>{String(Math.floor(project.time)).padStart(2, '0')}:{String(Math.round(project.time % 1 * 60)).padStart(2, '0')}</output></label>
            <div className="slider-labels"><span>Sunrise</span><span>Sunset</span></div>
          </Panel>
          <Panel title="Outliner">
            <input className="outliner-search" aria-label="Search objects" placeholder="Filter components…" value={outlinerSearch} onChange={e => setOutlinerSearch(e.target.value)} />
            <div className="outliner-root">▾ <Icon name="home" size={16} /> {project.name}</div>
            {project.entities.filter(e => e.name.toLowerCase().includes(outlinerSearch.toLowerCase())).map(e => <button key={e.id} className={`outliner-item ${selected.includes(e.id) ? 'selected' : ''} ${project.tags[e.tag] ? '' : 'hidden-entity'}`} aria-pressed={selected.includes(e.id)} onClick={event => onSelect(e.id, event.shiftKey)}><span>◇</span>{e.name}{e.group && <small>▧</small>}</button>)}
            {!project.entities.some(e => e.name.toLowerCase().includes(outlinerSearch.toLowerCase())) && <p className="muted">No matching components.</p>}
          </Panel>
          <Panel title="Scenes" initial={false}>{project.scenes.map(s => <div className="scene-row" key={s.id}><button onClick={() => recallScene(s.id)}>{s.name}</button><button title={`Delete ${s.name}`} disabled={project.scenes.length === 1} onClick={() => change({ ...project, scenes: project.scenes.filter(scene => scene.id !== s.id) })}>×</button></div>)}</Panel>
        </div>
      </aside>
    </div>
    <footer className="statusbar"><button aria-label="Help" onClick={() => setDialog('help')}><Icon name="info" size={16} /></button><span className="status-tool">{toolLabels[tool]}</span><span className="status-hint" role="status">{hint || instructions[tool]}</span><form onSubmit={e => { e.preventDefault(); applyMeasurements() }}><label htmlFor="measurements">{tool === 'rectangle' ? 'Dimensions' : 'Measurements'}</label><input id="measurements" autoComplete="off" placeholder={tool === 'rectangle' ? '3, 2, 1.5' : entity ? `${entity.size[1].toFixed(2)} m` : ''} value={measurements} onChange={e => setMeasurements(e.target.value)} /></form></footer>
    <input ref={inputFile} type="file" accept=".json,.skelo" hidden onChange={async e => {
      const file = e.target.files?.[0]
      if (!file) return
      try {
        if (file.size > 2_000_000) throw new Error('Project file exceeds the 2 MB limit.')
        const next = parseProject(await file.text())
        change(next); setSelected([]); setActiveScene(next.scenes[0].id); viewport.current?.setView(next.scenes[0].position, next.scenes[0].target); setNotice(''); setHint(`Opened ${next.name}`)
      } catch (err) { setNotice(err instanceof Error ? err.message : 'Unable to open project.') }
      e.target.value = ''
    }} />
    <dialog ref={dialogRef} onCancel={() => setDialog(null)} className="dialog">
      <div className="dialog-title">{dialog === 'scene' ? 'Add Scene' : dialog === 'reset' ? 'Restore Komorebi House' : 'Welcome to Skelo'}<button aria-label="Close dialog" onClick={() => setDialog(null)}>×</button></div>
      {dialog === 'scene' && <form onSubmit={e => { e.preventDefault(); saveScene() }}><p>Save the current camera and tag visibility as a scene.</p><label>Scene name<input autoFocus maxLength={100} aria-invalid={!!sceneError} aria-describedby={sceneError ? 'scene-error' : undefined} value={sceneName} onChange={e => { setSceneName(e.target.value); setSceneError('') }} /></label>{sceneError && <p id="scene-error" className="dialog-error" role="alert">{sceneError}</p>}<div className="dialog-actions"><button type="button" onClick={() => setDialog(null)}>Cancel</button><button className="primary" type="submit">Add Scene</button></div></form>}
      {dialog === 'reset' && <div className="dialog-body"><p>Replace the current project with the original courtyard house? You can undo this action.</p><div className="dialog-actions"><button onClick={() => setDialog(null)}>Cancel</button><button className="primary" onClick={() => { restoreView.current = true; change(createProject()); setSelected([]); setDialog(null); setNotice('') }}>Restore house</button></div></div>}
      {dialog === 'help' && <div className="dialog-body guide"><p>A quiet place to explore architecture. Every element in this courtyard is real, editable 3D geometry.</p><dl><dt>Space · Select</dt><dd>Click a component. Shift-click to select several; Ctrl+G groups them.</dd><dt>R · Rectangle</dt><dd>Click two ground corners or type width, depth, height below (meters).</dd><dt>P · Push/Pull</dt><dd>Drag a component vertically or enter a height. The whole parametric component resizes.</dd><dt>B · Paint</dt><dd>Choose a swatch, then click a component or use Paint selected.</dd><dt>O / H / Z · Navigate</dt><dd>Orbit, pan, zoom. Middle drag or right drag works from any tool.</dd><dt>Ctrl+Z / Ctrl+Y</dt><dd>Undo / redo. Changes autosave in this browser. File exports a portable JSON project or OBJ model.</dd></dl><p className="guide-boundary">Browser V1 · No SKP/DWG import, native extensions, freeform face topology or commercial rendering kernel. Inspired by SketchUp Pro; independently built.</p><button className="primary" onClick={() => setDialog(null)}>Start modeling</button></div>}
    </dialog>
  </main>
}
