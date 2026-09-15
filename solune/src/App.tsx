import { useCallback, useEffect, useRef, useState } from 'react'
import { ArrowDownToLine, Box, Camera, Check, ChevronDown, ChevronLeft, ChevronRight, Cloud, CloudFog, CloudSun, Copy, Film, Focus, FolderOpen, Grid2X2, HelpCircle, Home, Image, Layers, Leaf, Maximize, MousePointer2, Move, Palette, Plus, Redo2, RotateCcw, RotateCw, Save, Search, SlidersHorizontal, Sun, Sunset, Trash2, TreePalm, Trees, Undo2, Upload, X } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { VillaScene } from './Scene'
import { STORAGE_KEY, commit, createProject, exportProject, formatTime, materialColors, parseProject, placeObject, redo, undo } from './state'
import type { CameraShot, History, MaterialName, ObjectKind, Project, SceneObject, Weather } from './state'

type Panel = 'weather' | 'materials' | 'objects' | 'layers'
const objectNames: Record<ObjectKind, string> = { palm: 'Coastal palm', olive: 'Mediterranean olive', agave: 'Blue agave', lounger: 'Teak sun lounger' }
const objectIcons: Record<ObjectKind, LucideIcon> = { palm: TreePalm, olive: Trees, agave: Leaf, lounger: Box }
function initialState(): History {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    return { past: [], present: saved ? parseProject(saved) : createProject(), future: [] }
  } catch {
    return { past: [], present: createProject(), future: [] }
  }
}
function download(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  anchor.click()
  setTimeout(() => URL.revokeObjectURL(url), 3000)
}
function IconButton({ icon: Icon, label, active = false, onClick, disabled = false, className = '' }: {
  icon: LucideIcon; label: string; active?: boolean; onClick?: () => void; disabled?: boolean; className?: string
}) {
  return <button title={label} aria-label={label} aria-pressed={active} className={`icon-button ${active ? 'active' : ''} ${className}`} onClick={onClick} disabled={disabled}><Icon size={20} strokeWidth={1.5} /></button>
}
function Range({ label, value, min, max, step = 1, format, onChange }: {
  label: string; value: number; min: number; max: number; step?: number; format?: (n: number) => string; onChange: (n: number, squash: boolean) => void
}) {
  const gesture = useRef({ active: false, moved: false })
  return <label className="range-control">
    <span>{label}<output>{format ? format(value) : value}</output></span>
    <input aria-label={label} type="range" min={min} max={max} step={step} value={value}
      style={{ '--fill': `${(value - min) / (max - min) * 100}%` } as React.CSSProperties}
      onPointerDown={() => { gesture.current = { active: true, moved: false } }}
      onPointerUp={() => { gesture.current.active = false }}
      onPointerCancel={() => { gesture.current.active = false }}
      onChange={e => { onChange(Number(e.target.value), gesture.current.active && gesture.current.moved); gesture.current.moved = true }} />
  </label>
}
export default function App() {
  const [history, setHistory] = useState(initialState)
  const project = history.present
  const [mode, setMode] = useState<'build' | 'photo'>('build')
  const [panel, setPanel] = useState<Panel>('weather')
  const [panelOpen, setPanelOpen] = useState(true)
  const [selected, setSelected] = useState<string | null>(null)
  const [placing, setPlacing] = useState<ObjectKind | null>(null)
  const [activeShot, setActiveShot] = useState(project.shots[0].id)
  const [thumbnails, setThumbnails] = useState<Record<string, string>>({})
  const thumbnailUrls = useRef<string[]>([])
  const [grid, setGrid] = useState(false)
  const [status, setStatus] = useState('All changes saved')
  const [search, setSearch] = useState('')
  const [dialog, setDialog] = useState<'help' | 'export' | 'project' | 'reset' | null>(null)
  const [rendering, setRendering] = useState(false)
  const [size, setSize] = useState('1920')
  const [ready, setReady] = useState(false)
  const [error, setError] = useState('')
  const viewport = useRef<HTMLDivElement>(null)
  const engine = useRef<VillaScene | null>(null)
  const fileInput = useRef<HTMLInputElement>(null)
  const modal = useRef<HTMLDialogElement>(null)
  const initial = useRef(project)
  const selectedObject = project.objects.find(object => object.id === selected)
  const shot = project.shots.find(s => s.id === activeShot) ?? project.shots[0]
  const patch = useCallback((change: Partial<Project>, squash = false) => {
    setHistory(h => {
      const next = { ...h.present, ...change }
      return squash ? { ...h, present: next, future: [] } : commit(h, next)
    })
  }, [])
  const select = useCallback((id: string | null) => {
    setSelected(id)
    if (id === 'villa') { setPanel('materials'); setPanelOpen(true) }
  }, [])
  const refreshThumbnail = useCallback(async (camera: CameraShot) => {
    if (!engine.current) return
    const blob = await engine.current.image(320, 180, camera)
    const url = URL.createObjectURL(blob)
    thumbnailUrls.current.push(url)
    setThumbnails(t => ({ ...t, [camera.id]: url }))
  }, [])
  useEffect(() => {
    if (!viewport.current) return
    try {
      const scene = new VillaScene(viewport.current)
      engine.current = scene
      scene.update(initial.current)
      scene.onSelect = select
      setReady(true)
      let alive = true
      void (async () => {
        for (const camera of initial.current.shots) {
          if (!alive) return
          await refreshThumbnail(camera)
        }
      })()
      return () => {
        alive = false
        scene.dispose()
        thumbnailUrls.current.forEach(URL.revokeObjectURL)
      }
    } catch (e) { setError(`WebGL could not start: ${e instanceof Error ? e.message : 'unknown error'}`) }
  }, [refreshThumbnail, select])
  useEffect(() => {
    engine.current?.update(project)
    try { localStorage.setItem(STORAGE_KEY, exportProject(project)); setStatus('All changes saved') }
    catch { setStatus('Storage unavailable — export your project to save') }
  }, [project])
  useEffect(() => { engine.current?.select(selected) }, [selected, project.objects])
  useEffect(() => { engine.current?.setCamera(shot) }, [shot])
  useEffect(() => {
    if (!project.shots.some(camera => camera.id === activeShot)) setActiveShot(project.shots[0].id)
  }, [activeShot, project.shots])
  useEffect(() => {
    if (!engine.current) return
    engine.current.onPlace = placing ? position => {
      const id = crypto.randomUUID()
      setHistory(h => h.present.objects.length < 100 ? commit(h, placeObject(h.present, placing, position, id)) : h)
      setSelected(id)
      setPlacing(null)
    } : null
  }, [placing])
  useEffect(() => {
    if (dialog) modal.current?.showModal()
    else modal.current?.close()
  }, [dialog])
  const deleteSelected = useCallback(() => {
    if (!selected || selected === 'villa') return
    setHistory(h => commit(h, { ...h.present, objects: h.present.objects.filter(o => o.id !== selected) }))
    setSelected(null)
  }, [selected])
  useEffect(() => {
    const listener = (event: KeyboardEvent) => {
      if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement || event.target instanceof HTMLSelectElement || modal.current?.open) return
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'z') {
        event.preventDefault()
        setHistory(h => event.shiftKey ? redo(h) : undo(h))
      }
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'y') { event.preventDefault(); setHistory(redo) }
      if (event.key === 'Escape') { setPlacing(null); setSelected(null) }
      if (event.key === 'Delete') deleteSelected()
      if (event.key.toLowerCase() === 'h') engine.current?.setCamera(project.shots[0])
    }
    window.addEventListener('keydown', listener)
    return () => window.removeEventListener('keydown', listener)
  }, [deleteSelected, project.shots])
  const showPanel = (next: Panel) => { setMode('build'); setPanel(next); setPanelOpen(true); setPlacing(null) }
  const updateObject = (change: Partial<SceneObject>, squash = false) => {
    patch({ objects: project.objects.map(o => o.id === selected ? { ...o, ...change } : o) }, squash)
  }
  const chooseShot = (camera: CameraShot) => { setActiveShot(camera.id); engine.current?.setCamera(camera); setSelected(null); setPlacing(null) }
  const saveCamera = async () => {
    const camera = engine.current?.cameraShot(shot.id, shot.name)
    if (!camera) return
    patch({ shots: project.shots.map(s => s.id === camera.id ? camera : s) })
    await refreshThumbnail(camera)
  }
  const addCamera = async () => {
    const camera = engine.current?.cameraShot(crypto.randomUUID(), `Photo ${project.shots.length + 1}`)
    if (!camera) return
    patch({ shots: [...project.shots, camera] })
    setActiveShot(camera.id)
    await refreshThumbnail(camera)
  }
  const renderImage = async () => {
    if (!engine.current) return
    setRendering(true)
    try {
      const width = Number(size)
      const blob = await engine.current.image(width, width * 9 / 16)
      download(blob, `solune-${shot.name.toLowerCase().replaceAll(' ', '-')}-${width}.png`)
      setDialog(null)
    } catch (e) { setError(e instanceof Error ? e.message : 'Export failed') }
    finally { setRendering(false) }
  }
  const importFile = async (file: File) => {
    try {
      if (file.size > 500_000) throw new Error('Project file must be smaller than 500 KB.')
      const imported = parseProject(await file.text())
      setHistory(h => commit(h, imported))
      chooseShot(imported.shots[0])
      setDialog(null)
      setError('')
      for (const camera of imported.shots) await refreshThumbnail(camera)
    } catch (e) { setError(e instanceof Error ? e.message : 'Could not read project') }
    finally { if (fileInput.current) fileInput.current.value = '' }
  }

  return <div className={`app ${mode}`}>
    <header className="topbar">
      <button className="brand" onClick={() => setDialog('project')} aria-label="Solune project menu"><span className="brand-mark">◒</span><strong>solune</strong><span className="edition">STUDIO</span></button>
      <div className="project-title"><span className="project-dot" />{project.name}<ChevronDown size={13} onClick={() => setDialog('project')} /></div>
      <span className="project-subtitle">ARCHITECTURAL VISUALIZATION</span>
      <div className="top-actions"><span className="saved"><Check size={13} />{status}</span>
        <IconButton icon={Undo2} label="Undo (Ctrl+Z)" disabled={!history.past.length} onClick={() => setHistory(undo)} />
        <IconButton icon={Redo2} label="Redo (Ctrl+Shift+Z)" disabled={!history.future.length} onClick={() => setHistory(redo)} />
        <span className="divider" /><IconButton icon={FolderOpen} label="Project files" onClick={() => setDialog('project')} />
      </div>
    </header>
    <nav className="mode-rail" aria-label="Workspace">
      <IconButton icon={Home} label="Build mode" active={mode === 'build'} onClick={() => { setMode('build'); setPlacing(null) }} />
      <IconButton icon={Camera} label="Photo mode" active={mode === 'photo'} onClick={() => { setMode('photo'); setPlacing(null); setSelected(null); setPanelOpen(true) }} />
      <IconButton icon={Film} label="Movie mode — unavailable in browser V1" disabled />
      <div className="rail-line" />
      <IconButton icon={Layers} label="Scene objects" active={panel === 'layers' && mode === 'build'} onClick={() => showPanel('layers')} />
      <div className="rail-bottom"><span className="version">V1</span><IconButton icon={HelpCircle} label="Controls and help" onClick={() => setDialog('help')} /></div>
    </nav>
    <main className="workspace">
      <div ref={viewport} className={`viewport ${placing ? 'placing' : ''}`} data-ready={ready} />
      {!ready && !error && <div className="loading">Preparing coastal light…</div>}
      {grid && <div className="composition-grid"><i /><i /><i /><i /></div>}
      <div className="viewport-header">
        <span>{mode === 'photo' ? 'PHOTO' : 'BUILD'}<span className="slash">/</span>{mode === 'photo' ? shot.name : 'Perspective'}</span>
        <span className="live-badge"><i />LIVE PREVIEW</span>
      </div>
      <div className="scene-caption"><span className="caption-line" /><div><span>THE COASTAL COLLECTION</span><h1>Casa del Mar</h1><p>38° 42′ N &nbsp; 9° 25′ W <b>·</b> Atlantic coast</p></div></div>
      <div className="view-tools">
        <IconButton icon={Grid2X2} label="Composition grid" active={grid} onClick={() => setGrid(!grid)} />
        <IconButton icon={Focus} label="Restore current camera" onClick={() => chooseShot(shot)} />
        <IconButton icon={Maximize} label="Hide panels for clean viewport" active={!panelOpen} onClick={() => setPanelOpen(!panelOpen)} />
      </div>
      <div className="compass" aria-label={`Sun heading ${project.sunHeading} degrees`}><span>N</span><i style={{ transform: `rotate(${project.sunHeading - 180}deg)` }} /><b>S</b></div>
      {panelOpen && <aside className="editor-panel">
        <div className="panel-title"><span>{mode === 'photo' ? <><SlidersHorizontal size={17} />Photo effects</> : <>{panel === 'weather' ? <Sun size={18} /> : panel === 'materials' ? <Palette size={18} /> : <Trees size={18} />}{({ weather: 'Weather & sky', materials: 'Material editor', objects: 'Object library', layers: 'Scene objects' })[panel]}</>}</span><IconButton icon={ChevronLeft} label="Collapse panel" onClick={() => setPanelOpen(false)} /></div>
        {mode === 'photo' ? <>
          <div className="style-card"><Sunset size={24} /><div><strong>Coastal evening</strong><span>Custom photographic style</span></div></div>
          <div className="panel-section"><h3>COLOR & LIGHT <span>03</span></h3>
            <Range label="Exposure" value={project.exposure} min={0.4} max={1.8} step={0.01} format={n => `${n.toFixed(2)} EV`} onChange={(exposure, s) => patch({ exposure }, s)} />
            <Range label="Saturation" value={project.saturation} min={0} max={1.5} step={0.01} format={n => `${Math.round(n * 100)}%`} onChange={(saturation, s) => patch({ saturation }, s)} />
            <Range label="Bloom" value={project.bloom} min={0} max={1.2} step={0.01} format={n => `${Math.round(n * 100)}%`} onChange={(bloom, s) => patch({ bloom }, s)} />
          </div>
          <div className="panel-section"><h3>LENS & COMPOSITION</h3>
            <Range label="Vignette" value={project.vignette} min={0} max={0.8} step={0.01} format={n => `${Math.round(n * 100)}%`} onChange={(vignette, s) => patch({ vignette }, s)} />
            <Range label="Field of view" value={shot.fov} min={20} max={80} format={n => `${n}°`} onChange={(fov, s) => { const camera = engine.current?.cameraShot(shot.id, shot.name) ?? shot; patch({ shots: project.shots.map(c => c.id === shot.id ? { ...camera, fov } : c) }, s) }} />
            <button className={`option-row ${grid ? 'selected' : ''}`} onClick={() => setGrid(!grid)}><Grid2X2 size={16} />Rule of thirds<span className={`toggle ${grid ? 'on' : ''}`} /></button>
          </div>
          <div className="panel-section"><h3>ENVIRONMENT</h3><button className="option-row" onClick={() => showPanel('weather')}><Sunset size={17} />{formatTime(project.time)} · {project.weather}<ChevronRight size={14} /></button></div>
          <div className="panel-footer"><span className="small-status" /><span>Raster render · real-time reflections</span></div>
        </> : panel === 'weather' ? <>
          <div className={`sky-preview ${project.weather}`}><span>REAL-TIME SKY</span><Sun size={26} /><strong>{project.weather === 'clear' ? 'Atlantic dusk' : project.weather === 'mist' ? 'Coastal mist' : 'Soft overcast'}</strong><small>Procedural atmosphere</small></div>
          <div className="weather-types">
            {([['clear', Sun, 'Clear'], ['overcast', Cloud, 'Cloudy'], ['mist', CloudFog, 'Mist']] as const).map(([value, Icon, label]) => <button className={project.weather === value ? 'active' : ''} key={value} onClick={() => patch({ weather: value as Weather })}><Icon size={19} />{label}</button>)}
          </div>
          <div className="panel-section"><h3>SUN & SKY</h3>
            <Range label="Time of day" value={project.time} min={6} max={22} step={0.1} format={formatTime} onChange={(time, s) => patch({ time }, s)} />
            <div className="range-marks"><span>06:00</span><Sun size={11} /><span>22:00</span></div>
            <Range label="Sun heading" value={project.sunHeading} min={0} max={360} format={n => `${n}°`} onChange={(sunHeading, s) => patch({ sunHeading }, s)} />
            <Range label="Cloud coverage" value={project.cloud} min={0} max={100} format={n => `${n}%`} onChange={(cloud, s) => patch({ cloud }, s)} />
          </div>
          <div className="panel-section"><h3>LIGHTING</h3>
            <Range label="Interior lighting" value={project.interior} min={0} max={100} format={n => `${n}%`} onChange={(interior, s) => patch({ interior }, s)} />
            <div className="info-note"><span className="small-status" />Sun, sky and reflections update live.</div>
          </div>
          <div className="panel-footer"><CloudSun size={15} /><span>{formatTime(project.time)} &nbsp;·&nbsp; {project.weather === 'clear' ? 'Clear sky' : project.weather === 'mist' ? 'Sea mist' : 'Overcast'}</span></div>
        </> : panel === 'materials' ? <>
          <div className="selected-material"><div className={`material-ball ${project.material}`} style={{ '--stone': materialColors[project.material] } as React.CSSProperties} /><strong>Villa · exterior stone</strong><span>All architectural stone surfaces</span></div>
          <div className="panel-section"><h3>MATERIAL LIBRARY <span>04</span></h3><div className="material-grid">
            {(Object.keys(materialColors) as MaterialName[]).map(name => <button key={name} className={project.material === name ? 'active' : ''} onClick={() => patch({ material: name })}><span className="swatch" style={{ background: materialColors[name] }}>{project.material === name && <Check size={16} />}</span>{name}</button>)}
          </div></div>
          <div className="panel-section"><Range label="Roughness" value={project.roughness} min={0} max={1} step={0.01} format={n => `${Math.round(n * 100)}%`} onChange={(roughness, s) => patch({ roughness }, s)} /><p className="muted-copy">Click the villa in the viewport to select its architectural stone.</p></div>
        </> : panel === 'objects' ? <>
          <label className="search"><Search size={16} /><input placeholder="Search library…" aria-label="Search object library" value={search} onChange={e => setSearch(e.target.value)} /></label>
          <div className="library-heading">NATURE & OUTDOOR<span>4 objects</span></div>
          <div className="object-grid">{(Object.keys(objectNames) as ObjectKind[]).filter(k => objectNames[k].toLowerCase().includes(search.toLowerCase())).map(kind => {
            const Icon = objectIcons[kind]
            return <button key={kind} className={placing === kind ? 'active' : ''} onClick={() => { setPlacing(kind); setSelected(null) }} disabled={project.objects.length >= 100}><div className={`object-preview ${kind}`}><Icon size={58} strokeWidth={1} /><Plus size={14} className="object-plus" /></div><strong>{objectNames[kind]}</strong><span>{kind === 'lounger' ? 'Outdoor furniture' : 'Fine-detail nature'}</span></button>
          })}</div>
          {!Object.values(objectNames).some(n => n.toLowerCase().includes(search.toLowerCase())) && <p className="muted-copy">No objects match “{search}”.</p>}
          <div className="panel-section"><p className="muted-copy">{placing ? 'Click a point in the viewport to place this object. Escape cancels.' : 'Choose an object, then click the landscape to place it.'}</p></div>
        </> : <>
          <div className="library-heading">PROJECT CONTENT<span>{project.objects.length + 1} objects</span></div>
          <button className={`layer-row ${selected === 'villa' ? 'selected' : ''}`} onClick={() => select('villa')}><Home size={16} /><span>Casa del Mar <small>Architecture</small></span><span className="layer-dot" /></button>
          {project.objects.map((o, index) => { const Icon = objectIcons[o.kind]; return <button key={o.id} className={`layer-row ${selected === o.id ? 'selected' : ''}`} onClick={() => select(o.id)}><Icon size={16} /><span>{objectNames[o.kind]}<small>Object {String(index + 1).padStart(2, '0')}</small></span><span className="layer-dot" /></button> })}
        </>}
      </aside>}
      {!panelOpen && <button className="expand-panel" onClick={() => setPanelOpen(true)} aria-label="Expand panel"><ChevronRight size={17} /></button>}
      {selectedObject && mode === 'build' && <aside className="object-inspector">
        <div className="panel-title"><span>{objectNames[selectedObject.kind]}</span><IconButton icon={X} label="Deselect object" onClick={() => setSelected(null)} /></div>
        <div className="inspector-content"><span className="eyebrow">TRANSFORM</span>
          <div className="position-fields">{(['X', 'Z'] as const).map(axis => { const index = axis === 'X' ? 0 : 2; return <label key={axis}>{axis}<input aria-label={`Object position ${axis}`} type="number" min={-19} max={19} step={0.5} value={selectedObject.position[index]} onChange={e => { const value = Number(e.target.value); if (!Number.isFinite(value)) return; const position = [...selectedObject.position] as [number, number, number]; position[index] = Math.min(19, Math.max(-19, value)); updateObject({ position }) }} /><span>m</span></label> })}</div>
          <Range label="Rotation" min={-180} max={180} value={selectedObject.rotation} format={n => `${n}°`} onChange={(rotation, s) => updateObject({ rotation }, s)} />
          <Range label="Scale" min={0.3} max={3} step={0.1} value={selectedObject.scale} format={n => `${n.toFixed(1)}×`} onChange={(scale, s) => updateObject({ scale }, s)} />
          <div className="inspector-actions"><button onClick={() => { const id = crypto.randomUUID(); patch({ objects: [...project.objects, { ...selectedObject, id, position: [selectedObject.position[0] + 1, selectedObject.position[1], selectedObject.position[2] + 1] }] }); setSelected(id) }} disabled={project.objects.length >= 100}><Copy size={15} />Duplicate</button><IconButton icon={Trash2} label="Delete selected object" onClick={deleteSelected} /></div>
        </div>
      </aside>}
      {placing && <div className="placement-banner"><Plus size={15} />Place {objectNames[placing].toLowerCase()}<span>Click the landscape</span><button onClick={() => setPlacing(null)}>ESC</button></div>}
      <div className="navigation-hint"><MousePointer2 size={13} /><span>Drag to orbit</span><b>·</b><span>Scroll to zoom</span><b>·</b><span>Right-drag to pan</span></div>
      {mode === 'build' ? <div className="build-dock">
        <div className="tool-cluster primary-tools">
          <button className={panel === 'objects' ? 'active' : ''} onClick={() => showPanel('objects')}><Trees /><span>Objects</span></button>
          <button className={panel === 'materials' ? 'active' : ''} onClick={() => showPanel('materials')}><Palette /><span>Materials</span></button>
          <button className={panel === 'weather' ? 'active' : ''} onClick={() => showPanel('weather')}><CloudSun /><span>Weather</span></button>
        </div>
        <div className="tool-cluster edit-tools"><IconButton icon={MousePointer2} label="Select objects" active={!placing} onClick={() => { setPlacing(null); showPanel('layers') }} /><IconButton icon={Move} label="Edit position of selected object" disabled={!selectedObject} onClick={() => document.querySelector<HTMLInputElement>('[aria-label="Object position X"]')?.focus()} /><IconButton icon={RotateCw} label="Rotate selected object 15 degrees" disabled={!selectedObject} onClick={() => selectedObject && updateObject({ rotation: (selectedObject.rotation + 195) % 360 - 180 })} /><IconButton icon={Trash2} label="Remove selected object" disabled={!selectedObject} onClick={deleteSelected} /></div>
        <div className="dock-project"><Layers size={14} /><span>{project.objects.length + 1} objects</span><span className="dock-separator">/</span><span>Local project</span></div>
        <button className="photo-cta" onClick={() => { setMode('photo'); setSelected(null); setPlacing(null); setPanelOpen(true) }}><Camera size={21} /><span>Photo mode</span><ChevronRight size={15} /></button>
      </div> : <div className="photo-dock">
        <div className="photo-strip-heading"><span>PHOTO SET 01 <b>{project.shots.length} / 12</b></span><button onClick={() => void saveCamera()}><Save size={13} />Update camera</button><button disabled={project.shots.length >= 12} onClick={() => void addCamera()}><Plus size={14} />New photo</button></div>
        <div className="photo-strip">{project.shots.map((camera, index) => <button className={`shot-card ${activeShot === camera.id ? 'active' : ''}`} key={camera.id} onClick={() => chooseShot(camera)}>{thumbnails[camera.id] ? <img src={thumbnails[camera.id]} alt={camera.name} /> : <Camera size={24} />}<span className="shot-number">{String(index + 1).padStart(2, '0')}</span><span className="shot-name">{camera.name}</span></button>)}</div>
        <button className="render-button" onClick={() => setDialog('export')} disabled={!ready}><Image size={28} /><span>Render photo</span><small>PNG · up to 4K</small></button>
      </div>}
      {error && !dialog && <div className="error-banner" role="alert">{error}<button aria-label="Dismiss error" onClick={() => setError('')}><X size={16} /></button></div>}
    </main>
    <input hidden type="file" ref={fileInput} accept=".json,application/json" onChange={e => { const file = e.target.files?.[0]; if (file) void importFile(file) }} />
    <dialog ref={modal} className="modal" onCancel={() => setDialog(null)} onClick={e => { if (e.target === modal.current) setDialog(null) }}>
      <div className="modal-header"><h2>{dialog === 'export' ? 'Render photo' : dialog === 'help' ? 'Make yourself at home.' : dialog === 'reset' ? 'Reset the scene?' : 'Your project'}</h2><IconButton icon={X} label="Close dialog" onClick={() => setDialog(null)} /></div>
      {error && dialog && <p className="dialog-error" role="alert">{error}</p>}
      {dialog === 'export' ? <><p>Export the current camera with your lighting and photo effects. No interface, just your scene.</p><label className="select-label">OUTPUT RESOLUTION<select aria-label="Output resolution" value={size} onChange={e => setSize(e.target.value)}><option value="1280">HD · 1280 × 720</option><option value="1920">Full HD · 1920 × 1080</option><option value="3840">4K · 3840 × 2160</option></select></label><div className="export-detail"><span>Format</span><strong>PNG image</strong><span>Aspect ratio</span><strong>16 : 9</strong></div><button className="wide-primary" onClick={() => void renderImage()} disabled={rendering}><ArrowDownToLine size={17} />{rendering ? 'Exporting image…' : 'Export image'}</button></> :
      dialog === 'help' ? <><p>A local architectural visualization studio, inspired by Lumion 2024.</p><div className="help-grid"><span>Orbit the scene</span><kbd>Left drag</kbd><span>Pan camera</span><kbd>Right drag</kbd><span>Zoom</span><kbd>Scroll</kbd><span>Undo / redo</span><kbd>Ctrl Z / Shift Z</kbd><span>Remove selection</span><kbd>Delete</kbd><span>Cancel placement</span><kbd>Esc</kbd><span>First camera</span><kbd>H</kbd></div><p className="muted-copy">Everything saves in this browser. Export a project for a portable backup. WebGL rasterization; native ray tracing, BIM imports and movies are outside this V1.</p></> :
      dialog === 'reset' ? <><p>Restore Casa del Mar and its four original cameras. You can undo this action.</p><button className="wide-primary" onClick={() => { const next = createProject(); setHistory(h => commit(h, next)); chooseShot(next.shots[0]); setDialog(null); setPanel('weather'); setMode('build'); void (async () => { for (const c of next.shots) await refreshThumbnail(c) })() }}><RotateCcw size={17} />Restore original project</button></> :
      <><label className="select-label">PROJECT NAME<input aria-label="Project name" maxLength={100} value={project.name} onChange={e => patch({ name: e.target.value })} /></label><div className="project-menu-actions"><button onClick={() => { download(new Blob([exportProject(project)], { type: 'application/json' }), 'solune-project.json'); setDialog(null) }}><Save size={19} /><div><strong>Export project</strong><small>Scene, materials, lighting and cameras · JSON</small></div><ArrowDownToLine size={16} /></button><button onClick={() => fileInput.current?.click()}><Upload size={19} /><div><strong>Open project</strong><small>Import a Solune project file</small></div><ChevronRight size={16} /></button><button onClick={() => setDialog('reset')}><RotateCcw size={19} /><div><strong>Restore Casa del Mar</strong><small>Return to the original scene</small></div><ChevronRight size={16} /></button></div></>}
    </dialog>
  </div>
}
