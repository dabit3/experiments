import { useEffect, useReducer, useRef, useState, type ReactNode } from 'react'
import { Aperture, Archive, Axis3D, Box, Camera, Check, ChevronDown, ChevronRight, Circle, CircleDot, Copy, Diamond, Download, Eye, EyeOff, Folder, Grid2X2, Grip, Hand, HelpCircle, Image, Layers, Lightbulb, LockKeyhole, Magnet, Maximize, MousePointer2, Move, Pause, Play, Plus, Rotate3D, RotateCcw, Scaling, Search, Settings2, SkipBack, SkipForward, SlidersHorizontal, Sun, Trash2, Triangle, Wrench, X } from 'lucide-react'
import Viewport, { type Shading, type Tool, type ViewportHandle } from './Viewport'
import { addObject, createProject, defaultCameras, downloadFile, duplicateObject, historyReducer, parseProject, removeObject, serializeProject, setKeyframe, STORAGE_KEY, updateObject, type CameraBookmark, type History, type Project, type SceneObject, type Vec3 } from './model'

type Modal = 'help' | 'reset' | 'render' | null
const initialError = { message: '' }
function loadProject(): History {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return { past: [], present: raw ? parseProject(raw) : createProject(), future: [] }
  } catch {
    initialError.message = 'Saved project could not be read. The built-in loft has been opened.'
    return { past: [], present: createProject(), future: [] }
  }
}
function IconButton({ label, children, active = false, disabled = false, onClick }: { label: string; children: ReactNode; active?: boolean; disabled?: boolean; onClick?: () => void }) {
  return <button type="button" title={label} aria-label={label} aria-pressed={active} className={`icon-button ${active ? 'active' : ''}`} disabled={disabled} onClick={onClick}>{children}</button>
}
function Menu({ label, open, setOpen, children }: { label: string; open: string | null; setOpen: (v: string | null) => void; children: ReactNode }) {
  return <div className="menu">
    <button className={open === label ? 'menu-trigger open' : 'menu-trigger'} onClick={() => setOpen(open === label ? null : label)} aria-expanded={open === label}>{label}</button>
    {open === label && <div className="dropdown" role="menu" onClick={() => setOpen(null)}>{children}</div>}
  </div>
}
function MenuItem({ label, hint, onClick, disabled }: { label: string; hint?: string; onClick?: () => void; disabled?: boolean }) {
  return <button role="menuitem" onClick={onClick} disabled={disabled}><span>{label}</span><kbd>{hint}</kbd></button>
}
function NumberField({ label, value, onChange, min, max, step = 0.1 }: { label: string; value: number; onChange: (v: number) => void; min?: number; max?: number; step?: number }) {
  const [draft, setDraft] = useState(String(value))
  useEffect(() => setDraft(String(value)), [value])
  const commit = () => {
    const n = Number(draft)
    if (draft.trim() && Number.isFinite(n)) onChange(Math.min(max ?? 10000, Math.max(min ?? -10000, n)))
    else setDraft(String(value))
  }
  return <input aria-label={label} type="number" value={draft} min={min} max={max} step={step} onChange={event => setDraft(event.target.value)} onBlur={commit} onKeyDown={event => { if (event.key === 'Enter') event.currentTarget.blur() }} />
}
const collections = ['Architecture', 'Furniture', 'Objects & greenery', 'Lighting', 'Added objects']
const palettes = ['#b96035', '#e1d6bf', '#6e7964', '#748384', '#ae8a58', '#494c48', '#a65040', '#c4beb1']

export default function App() {
  const [history, dispatch] = useReducer(historyReducer, undefined, loadProject)
  const project = history.present
  const [selected, setSelected] = useState<string | null>('sofa')
  const object = project.objects.find(o => o.id === selected)
  const [openMenu, setOpenMenu] = useState<string | null>(null)
  const [workspace, setWorkspace] = useState('Layout')
  const [tool, setTool] = useState<Tool>('select')
  const [shading, setShading] = useState<Shading>('material')
  const [camera, setCamera] = useState<CameraBookmark>(defaultCameras[0])
  const [activeCamera, setActiveCamera] = useState<CameraBookmark>(defaultCameras[0])
  const [grid, setGrid] = useState(true)
  const [sidebar, setSidebar] = useState(false)
  const [properties, setProperties] = useState<'object' | 'material' | 'render'>('object')
  const [collapsed, setCollapsed] = useState<string[]>(['Architecture', 'Objects & greenery', 'Lighting'])
  const [search, setSearch] = useState('')
  const [frame, setFrame] = useState(1)
  const [playing, setPlaying] = useState(false)
  const [animate, setAnimate] = useState(false)
  const [exposure, setExposure] = useState(1.15)
  const [ready, setReady] = useState(false)
  const [error, setError] = useState(initialError.message)
  const [saved, setSaved] = useState(true)
  const [notice, setNotice] = useState('')
  const [modal, setModal] = useState<Modal>(null)
  const [renderResult, setRenderResult] = useState<{ blob: Blob; url: string } | null>(null)
  const [numeric, setNumeric] = useState<{ mode: Tool; axis: number | null; value: string } | null>(null)
  const view = useRef<ViewportHandle>(null)
  const fileInput = useRef<HTMLInputElement>(null)
  const dialogRef = useRef<HTMLDialogElement>(null)
  const chooseCamera = (value: CameraBookmark) => { setCamera({ ...value }); setActiveCamera(value) }
  const resetCamera = () => chooseCamera(defaultCameras[0])
  const cameraIndex = project.cameras.findIndex(c => c.position.every((v, i) => Math.abs(v - activeCamera.position[i]) < 0.001) && c.target.every((v, i) => Math.abs(v - activeCamera.target[i]) < 0.001))
  const edit = (next: Project) => { dispatch({ type: 'edit', project: next }); setSaved(false) }
  const patch = (id: string, value: Partial<Omit<SceneObject, 'id' | 'kind'>>) => { setAnimate(false); setPlaying(false); edit(updateObject(project, id, value)) }
  const select = (id: string | null) => { setSelected(id); setNumeric(null) }
  const duplicate = () => {
    if (!selected || project.objects.length >= 200) return
    const id = crypto.randomUUID()
    edit(duplicateObject(project, selected, id))
    setSelected(id)
  }
  const remove = () => { if (selected) { edit(removeObject(project, selected)); setSelected(null) } }
  const add = (kind: 'cube' | 'sphere' | 'cylinder' | 'plant') => {
    if (project.objects.length >= 200) { setError('A project can contain up to 200 editable objects.'); return }
    const id = crypto.randomUUID()
    edit(addObject(project, kind, id))
    setSelected(id)
    setCollapsed(collapsed.filter(c => c !== 'Added objects'))
    setTool('translate')
  }
  const exportProject = () => {
    downloadFile(new Blob([serializeProject(project)], { type: 'application/json' }), 'atelier-no-04.polyn.json')
    setNotice('Project exported')
  }
  const renderImage = async () => {
    try {
      setPlaying(false)
      const blob = await view.current?.capture()
      if (blob) {
        if (renderResult) URL.revokeObjectURL(renderResult.url)
        setRenderResult({ blob, url: URL.createObjectURL(blob) })
        setModal('render')
      }
    } catch (e) { setError(e instanceof Error ? e.message : 'Could not render image.') }
  }
  const insertKey = () => { if (selected) { edit(setKeyframe(project, selected, frame)); setNotice(`Transform keyframe inserted at frame ${frame}`) } }
  const save = () => {
    try { localStorage.setItem(STORAGE_KEY, serializeProject(project)); setSaved(true); setNotice('Project saved locally') }
    catch { setError('Browser storage is full or unavailable. Export the project to keep your changes.'); setSaved(false) }
  }
  useEffect(() => {
    const timer = setTimeout(() => {
      try { localStorage.setItem(STORAGE_KEY, serializeProject(project)); setSaved(true) }
      catch { setSaved(false); setError('Could not autosave. Export the project to keep your changes.') }
    }, 350)
    return () => clearTimeout(timer)
  }, [project])
  useEffect(() => {
    if (!playing) return
    const timer = setInterval(() => setFrame(f => f >= 250 ? 1 : f + 1), 1000 / 24)
    return () => clearInterval(timer)
  }, [playing])
  useEffect(() => {
    if (!notice) return
    const timer = setTimeout(() => setNotice(''), 3500)
    return () => clearTimeout(timer)
  }, [notice])
  useEffect(() => {
    if (modal) dialogRef.current?.showModal()
    else dialogRef.current?.close()
  }, [modal])
  useEffect(() => {
    const keydown = (event: KeyboardEvent) => {
      const target = event.target
      if (target instanceof HTMLElement && (['INPUT', 'SELECT', 'TEXTAREA'].includes(target.tagName) || target.isContentEditable)) return
      if (modal) return
      const key = event.key.toLowerCase()
      if (event.ctrlKey || event.metaKey) {
        if (key === 'z') { event.preventDefault(); dispatch({ type: event.shiftKey ? 'redo' : 'undo' }); setNumeric(null) }
        if (key === 's') { event.preventDefault(); save() }
        return
      }
      if (numeric) {
        if (['x', 'y', 'z'].includes(key)) { setNumeric({ ...numeric, axis: ['x', 'y', 'z'].indexOf(key) }); return }
        if (/^[0-9.-]$/.test(key)) { setNumeric({ ...numeric, value: numeric.value + key }); return }
        if (key === 'backspace') { event.preventDefault(); setNumeric({ ...numeric, value: numeric.value.slice(0, -1) }); return }
        if (key === 'escape') { setNumeric(null); setTool('select'); return }
        if (key === 'enter' && object) {
          const value = Number(numeric.value)
          if (numeric.value && Number.isFinite(value)) {
            const prop = numeric.mode === 'translate' ? 'position' : numeric.mode === 'rotate' ? 'rotation' : 'scale'
            const next = [...object[prop]] as Vec3
            for (let axis = 0; axis < 3; axis++) {
              if (numeric.axis === axis || (numeric.axis === null && (prop === 'scale' || axis === (prop === 'rotation' ? 2 : 0)))) {
                next[axis] = prop === 'scale' ? Math.max(0.01, Math.min(100, next[axis] * value)) : Math.max(-10000, Math.min(10000, next[axis] + value))
              }
            }
            patch(object.id, { [prop]: next })
          }
          setNumeric(null)
          return
        }
      }
      if (['g', 'r', 's'].includes(key) && object) {
        const mode = key === 'g' ? 'translate' : key === 'r' ? 'rotate' : 'scale'
        setTool(mode); setNumeric({ mode, axis: null, value: '' })
      }
      if (key === 'd' && event.shiftKey) { event.preventDefault(); duplicate() }
      if (key === 'delete' || key === 'backspace') { event.preventDefault(); remove() }
      if (key === 'i') insertKey()
      if (key === 'n') setSidebar(v => !v)
      if (key === 'escape') { setTool('select'); setOpenMenu(null); setNumeric(null) }
      if (key === ' ') { event.preventDefault(); setAnimate(true); setPlaying(v => !v) }
      if (key === 'home') { event.preventDefault(); resetCamera() }
      if (key === 'f12') { event.preventDefault(); void renderImage() }
    }
    window.addEventListener('keydown', keydown)
    return () => window.removeEventListener('keydown', keydown)
  })
  const transformFields = object && <div className="transform-fields">
    {(['position', 'rotation', 'scale'] as const).map(prop => <div className="vector-row" key={prop}>
      <span className="field-label">{prop === 'position' ? 'Location' : prop === 'rotation' ? 'Rotation' : 'Scale'}</span>
      <div className="vector-inputs">{(['X', 'Y', 'Z'] as const).map((axis, i) => <label key={axis}><span className={`axis-label axis-${axis.toLowerCase()}`}>{axis}</span><NumberField label={`${prop === 'position' ? 'Location' : prop === 'rotation' ? 'Rotation' : 'Scale'} ${axis}`} value={object[prop][i]} min={prop === 'scale' ? 0.01 : undefined} max={prop === 'scale' ? 100 : undefined} step={prop === 'rotation' ? 5 : 0.1} onChange={value => {
        const next = [...object[prop]] as Vec3
        next[i] = value
        patch(object.id, { [prop]: next })
      }} /><span className="field-unit">{prop === 'position' ? 'm' : prop === 'rotation' ? '°' : ''}</span><LockKeyhole size={10} className="field-lock" /></label>)}</div>
    </div>)}
  </div>
  const setViewFrame = (value: number) => { setFrame(Math.round(value)); setAnimate(true) }
  const chooseWorkspace = (label: string) => {
    setWorkspace(label)
    if (label === 'Shading') { setProperties('material'); setShading('material') }
    if (label === 'Rendering') setProperties('render')
    if (label === 'Animation') setAnimate(true)
  }
  return <div className={`app workspace-${workspace.toLowerCase()}`} onPointerDown={event => { if (!(event.target as HTMLElement).closest('.menu')) setOpenMenu(null) }}>
    <header className="topbar">
      <div className="brand" title="Polyn · Architectural workspace"><Aperture size={21} /><strong>polyn</strong></div>
      <nav className="main-menus" aria-label="Main menu">
        <Menu label="File" open={openMenu} setOpen={setOpenMenu}>
          <MenuItem label="New · Built-in loft" onClick={() => setModal('reset')} />
          <MenuItem label="Open project…" hint="JSON" onClick={() => fileInput.current?.click()} />
          <div className="menu-divider" />
          <MenuItem label="Save" hint="Ctrl S" onClick={save} />
          <MenuItem label="Export project…" hint=".polyn.json" onClick={exportProject} />
        </Menu>
        <Menu label="Edit" open={openMenu} setOpen={setOpenMenu}>
          <MenuItem label="Undo" hint="Ctrl Z" disabled={!history.past.length} onClick={() => dispatch({ type: 'undo' })} />
          <MenuItem label="Redo" hint="Ctrl Shift Z" disabled={!history.future.length} onClick={() => dispatch({ type: 'redo' })} />
          <div className="menu-divider" /><MenuItem label="Duplicate object" hint="Shift D" disabled={!object} onClick={duplicate} />
          <MenuItem label="Delete object" hint="Del" disabled={!object} onClick={remove} />
        </Menu>
        <Menu label="Render" open={openMenu} setOpen={setOpenMenu}>
          <MenuItem label="Render image" hint="F12" disabled={!ready} onClick={() => void renderImage()} />
          <MenuItem label="Render settings" onClick={() => setProperties('render')} />
          <MenuItem label="Render animation · unavailable in V1" disabled />
        </Menu>
        <Menu label="Window" open={openMenu} setOpen={setOpenMenu}>
          <MenuItem label="Toggle viewport sidebar" hint="N" onClick={() => setSidebar(!sidebar)} />
          <MenuItem label="Toggle grid overlay" onClick={() => setGrid(!grid)} />
          <MenuItem label="Frame whole project" hint="Home" onClick={resetCamera} />
        </Menu>
        <button className="menu-trigger" onClick={() => setModal('help')}>Help</button>
      </nav>
      <nav className="workspaces" aria-label="Workspaces">
        {['Layout', 'Modeling', 'Sculpting', 'UV Editing', 'Shading', 'Animation', 'Rendering'].map(label => <button key={label} className={workspace === label ? 'selected' : ''} disabled={['Modeling', 'Sculpting', 'UV Editing'].includes(label)} title={['Modeling', 'Sculpting', 'UV Editing'].includes(label) ? `${label} is outside this browser V1` : label} onClick={() => chooseWorkspace(label)}>{label}</button>)}
        <button title="Additional native workspaces are outside V1" disabled><Plus size={12} /></button>
      </nav>
      <div className="scene-select"><Layers size={14} /><span>Scene</span><ChevronDown size={12} /></div>
      <div className="view-layer"><Image size={13} /><span>ViewLayer</span><ChevronDown size={12} /></div>
    </header>
    <div className="contextbar">
      <span className="file-breadcrumb"><Folder size={12} /><span>Projects</span><ChevronRight size={11} /><strong>{project.name}</strong><span className="file-extension">.polyn</span></span>
      <span className="file-state">{saved ? <Check size={11} /> : <Circle size={9} />}{saved ? 'Saved locally' : 'Unsaved changes'}</span>
      <span className="context-spacer" />
      <span className="engine-badge"><Sun size={12} />WebGL Studio</span>
      <button className="render-button" disabled={!ready} onClick={() => void renderImage()}><Camera size={12} /> Render image <kbd>F12</kbd></button>
    </div>
    <main className="work-area">
      <section className="editor" aria-label="3D editor">
        <div className="viewport-header">
          <span className="editor-icon"><Box size={15} /><ChevronDown size={9} /></span>
          <button className="mode-control" disabled title="V1 supports Object Mode; mesh edit mode is unavailable"><Box size={12} />Object Mode<ChevronDown size={10} /></button>
          <Menu label="View" open={openMenu} setOpen={setOpenMenu}>{project.cameras.map((c, i) => <MenuItem key={i} label={c.name} onClick={() => chooseCamera(c)} />)}<div className="menu-divider" /><MenuItem label="Save current view" onClick={() => {
            const value = view.current?.bookmark()
            if (value && project.cameras.length < 30) {
              edit({ ...project, cameras: [...project.cameras, { ...value, name: `Saved view ${project.cameras.length - 3}` }] })
              setActiveCamera(value)
            }
          }} /></Menu>
          <Menu label="Select" open={openMenu} setOpen={setOpenMenu}><MenuItem label="Deselect all" onClick={() => select(null)} /><MenuItem label="Select sofa" onClick={() => select('sofa')} /></Menu>
          <Menu label="Add" open={openMenu} setOpen={setOpenMenu}>{(['cube', 'sphere', 'cylinder', 'plant'] as const).map(k => <MenuItem key={k} label={k === 'plant' ? 'Plant · Strelitzia' : `Mesh · ${k[0].toUpperCase()}${k.slice(1)}`} onClick={() => add(k)} />)}</Menu>
          <Menu label="Object" open={openMenu} setOpen={setOpenMenu}><MenuItem label="Duplicate" hint="Shift D" onClick={duplicate} disabled={!object} /><MenuItem label="Delete" hint="Del" onClick={remove} disabled={!object} /><MenuItem label="Insert transform keyframe" hint="I" onClick={insertKey} disabled={!object} /></Menu>
          <div className="header-center"><span><Axis3D size={13} />Global<ChevronDown size={10} /></span><CircleDot size={14} /><ChevronDown size={9} /><Magnet size={14} className="muted" /></div>
          <div className="viewport-display">
            <IconButton label="Toggle grid" active={grid} onClick={() => setGrid(!grid)}><Grid2X2 size={14} /></IconButton>
            <IconButton label="Toggle item sidebar" active={sidebar} onClick={() => setSidebar(!sidebar)}><SlidersHorizontal size={14} /></IconButton>
            <span className="control-divider" />
            <IconButton label="Wireframe view" active={shading === 'wireframe'} onClick={() => setShading('wireframe')}><Grid2X2 size={14} /></IconButton>
            <IconButton label="Solid view" active={shading === 'solid'} onClick={() => setShading('solid')}><Circle size={15} fill="currentColor" /></IconButton>
            <IconButton label="Material view" active={shading === 'material'} onClick={() => setShading('material')}><CircleDot size={16} /></IconButton>
          </div>
        </div>
        <div className="viewport-body">
          <Viewport ref={view} project={project} selected={selected} shading={shading} tool={tool} grid={grid} camera={camera} frame={frame} animate={animate} exposure={exposure} onSelect={select} onTransform={patch} onCameraChange={setActiveCamera} onReady={() => setReady(true)} onError={setError} />
          <div className="viewport-info"><span>User Perspective</span><span>({frame}) {project.name} <span className="orange">| {object?.name ?? 'No selection'}</span></span><span className="viewport-mode">{shading === 'material' ? 'Material Preview' : shading === 'solid' ? 'Solid' : 'Wireframe'}</span></div>
          <div className="tool-shelf">
            <IconButton label="Select (Esc)" active={tool === 'select'} onClick={() => { setTool('select'); setNumeric(null) }}><MousePointer2 /></IconButton>
            <IconButton label="3D cursor · centered in this V1" disabled><CircleDot /></IconButton>
            <span className="tool-separator" />
            <IconButton label="Move (G)" active={tool === 'translate'} onClick={() => setTool('translate')}><Move /></IconButton>
            <IconButton label="Rotate (R)" active={tool === 'rotate'} onClick={() => setTool('rotate')}><Rotate3D /></IconButton>
            <IconButton label="Scale (S)" active={tool === 'scale'} onClick={() => setTool('scale')}><Scaling /></IconButton>
            <span className="tool-separator" />
            <IconButton label="Frame project (Home)" onClick={resetCamera}><Maximize /></IconButton>
            <IconButton label="Add cube" onClick={() => add('cube')}><Box /></IconButton>
          </div>
          <div className="gizmo">
            <svg viewBox="0 0 90 90" aria-label="Viewport axis orientation">
              <path d="M44 45V12M44 45L72 60M44 45L16 60" stroke="#92958d" strokeWidth="2" />
              <circle cx="44" cy="14" r="10" fill="#4c94df" /><text x="44" y="18">Z</text>
              <circle cx="72" cy="60" r="10" fill="#d96369" /><text x="72" y="64">X</text>
              <circle cx="16" cy="60" r="10" fill="#92ba42" /><text x="16" y="64">Y</text>
              <circle cx="44" cy="45" r="5" fill="#7e827c" />
            </svg>
            <IconButton label="Reset camera" onClick={resetCamera}><RotateCcw size={15} /></IconButton>
            <IconButton label="Front camera" onClick={() => chooseCamera(defaultCameras[3])}><Camera size={15} /></IconButton>
            <IconButton label="Toggle overlays" active={grid} onClick={() => setGrid(!grid)}><Grid2X2 size={15} /></IconButton>
          </div>
          {sidebar && <aside className="item-panel"><h3>Item <button onClick={() => setSidebar(false)} aria-label="Close item sidebar"><X size={13} /></button></h3><h4>Transform</h4>{object ? transformFields : <p>Select an object</p>}</aside>}
          <div className="scene-caption"><span className="caption-rule" /><div><strong>ATELIER <span>No. 04</span></strong><span>Residential study · Warm minimalism</span></div></div>
          <div className="camera-selector"><Camera size={12} /><select aria-label="Saved camera" value={cameraIndex} onChange={event => chooseCamera(project.cameras[Number(event.target.value)])}><option value="-1" hidden>Custom view</option>{project.cameras.map((c, i) => <option key={i} value={i}>{c.name}</option>)}</select></div>
          {!ready && !error && <div className="loading-scene"><Aperture size={28} />Preparing atelier…</div>}
          {numeric && <div className="transform-hud"><Move size={13} /><strong>{numeric.mode}</strong><span>{numeric.axis === null ? 'Choose X / Y / Z' : ['X', 'Y', 'Z'][numeric.axis]}</span><b>{numeric.value || 'Type a value'}</b><kbd>Enter</kbd><span>confirm</span><kbd>Esc</kbd><span>cancel</span></div>}
        </div>
        <section className="timeline" aria-label="Animation timeline">
          <div className="timeline-header">
            <span className="editor-icon"><CircleDot size={14} /><ChevronDown size={9} /></span><span>Playback</span><span>Keying</span><span className="timeline-view-label">View</span>
            <div className="play-controls">
              <IconButton label="First frame" onClick={() => setViewFrame(1)}><SkipBack size={14} /></IconButton>
              <IconButton label="Previous keyframe" onClick={() => setViewFrame([...object?.keyframes ?? []].reverse().find(k => k.frame < frame)?.frame ?? 1)}><ChevronRight size={14} className="reverse" /></IconButton>
              <IconButton label={playing ? 'Pause animation' : 'Play animation'} active={playing} onClick={() => { setAnimate(true); setPlaying(!playing) }}>{playing ? <Pause size={14} /> : <Play size={14} fill="currentColor" />}</IconButton>
              <IconButton label="Next keyframe" onClick={() => setViewFrame(object?.keyframes.find(k => k.frame > frame)?.frame ?? 250)}><ChevronRight size={14} /></IconButton>
              <IconButton label="Last frame" onClick={() => setViewFrame(250)}><SkipForward size={14} /></IconButton>
            </div>
            <IconButton label="Insert keyframe (I)" disabled={!object} onClick={insertKey}><Diamond size={12} /></IconButton>
            <div className="timeline-range"><NumberField label="Current frame" value={frame} min={1} max={250} step={1} onChange={setViewFrame} /><span>Start <b>1</b></span><span>End <b>250</b></span></div>
          </div>
          <div className="timeline-track" onPointerDown={event => {
            if (event.target instanceof HTMLInputElement) return
            const rect = event.currentTarget.getBoundingClientRect()
            setViewFrame(Math.max(1, Math.min(250, Math.round((event.clientX - rect.left - 24) / (rect.width - 48) * 249 + 1))))
          }}>
            <div className="timeline-ticks">{Array.from({ length: 13 }, (_, i) => <span key={i}>{i * 20}</span>)}</div>
            <div className="keyframe-lane">{object?.keyframes.map(k => <button key={k.frame} aria-label={`Keyframe ${k.frame}`} title={`Transform keyframe · ${k.frame}`} style={{ left: `calc(24px + (100% - 48px) * ${(k.frame - 1) / 249})` }} onPointerDown={event => event.stopPropagation()} onClick={() => setViewFrame(k.frame)}><Diamond size={10} fill="#d3b45e" /></button>)}</div>
            <div className="playhead" style={{ left: `calc(24px + (100% - 48px) * ${(frame - 1) / 249})` }}><b>{frame}</b></div>
            <input className="timeline-scrubber" type="range" aria-label="Timeline scrubber" min="1" max="250" value={frame} onChange={event => setViewFrame(Number(event.target.value))} />
          </div>
        </section>
      </section>
      <aside className="right-column">
        <section className="outliner" aria-label="Scene outliner">
          <div className="panel-header"><span className="editor-icon"><Layers size={15} /><ChevronDown size={9} /></span><label className="search"><Search size={13} /><input aria-label="Search objects" placeholder="Search" value={search} onChange={event => setSearch(event.target.value)} /></label><Settings2 size={14} /></div>
          <div className="outliner-tree">
            <div className="scene-root"><Archive size={14} /><span>Scene Collection</span></div>
            {collections.map(collection => {
              const items = project.objects.filter(o => o.collection === collection && o.name.toLowerCase().includes(search.toLowerCase()))
              if (!items.length) return null
              const closed = collapsed.includes(collection) && !search
              return <div key={collection}>
                <button className="collection-row" onClick={() => setCollapsed(closed ? collapsed.filter(c => c !== collection) : [...collapsed, collection])}>{closed ? <ChevronRight size={12} /> : <ChevronDown size={12} />}<Folder size={14} /><span>{collection}</span><small>{items.length.toString().padStart(2, '0')}</small><Eye size={12} /></button>
                {!closed && items.map(o => <div key={o.id} className={`object-row ${o.id === selected ? 'selected' : ''} ${!o.visible ? 'hidden-object' : ''}`}>
                  <button className="object-name" onClick={() => select(o.id)} title={o.name}><ChevronRight size={10} />{o.kind === 'pendant' ? <Lightbulb size={13} /> : <Triangle size={13} />}<span>{o.name}</span>{o.id === selected && <span className="selected-dot" />}</button>
                  <button className="visibility" aria-label={`${o.visible ? 'Hide' : 'Show'} ${o.name}`} onClick={() => patch(o.id, { visible: !o.visible })}>{o.visible ? <Eye size={12} /> : <EyeOff size={12} />}</button>
                </div>)}
              </div>
            })}
            {search && !project.objects.some(o => o.name.toLowerCase().includes(search.toLowerCase())) && <p className="empty-search">No objects match “{search}”</p>}
          </div>
          <div className="outliner-footer"><span>{project.objects.length} objects</span><span>{object ? '1 selected' : '0 selected'}</span></div>
        </section>
        <section className="properties" aria-label="Object properties">
          <div className="panel-header"><span className="editor-icon"><SlidersHorizontal size={15} /><ChevronDown size={9} /></span><span className="property-breadcrumb"><Box size={12} />{object?.name ?? 'Scene'}</span></div>
          <div className="property-body">
            <nav className="property-tabs" aria-label="Property tabs">
              <IconButton label="Render properties" active={properties === 'render'} onClick={() => setProperties('render')}><Camera size={16} /></IconButton>
              <IconButton label="Native output engine · unavailable in V1" disabled><Image size={16} /></IconButton>
              <IconButton label="Native simulation · unavailable in V1" disabled><Layers size={16} /></IconButton>
              <span className="tool-separator" />
              <IconButton label="Object properties" active={properties === 'object'} onClick={() => setProperties('object')}><Box size={16} /></IconButton>
              <IconButton label="Modifiers · unavailable in V1" disabled><Wrench size={16} /></IconButton>
              <IconButton label="Mesh data · unavailable in V1" disabled><Triangle size={16} /></IconButton>
              <IconButton label="Material properties" active={properties === 'material'} onClick={() => setProperties('material')}><CircleDot size={17} /></IconButton>
            </nav>
            <div className="property-content">
              {properties === 'render' ? <>
                <div className="property-title"><Camera size={15} />Render</div>
                <details open><summary>Render engine</summary><div className="property-section"><span className="engine-select">WebGL Studio <ChevronDown size={12} /></span><p>Real-time physically based materials with soft shadows and ambient lighting.</p></div></details>
                <details open><summary>Color management</summary><div className="property-section"><label className="single-field">View transform<span>ACES Filmic</span></label><label className="single-field">Exposure<NumberField label="Exposure" value={exposure} min={0.2} max={3} onChange={setExposure} /></label></div></details>
                <details open><summary>Output</summary><div className="property-section"><label className="single-field">File format<span>PNG · RGBA</span></label><p>Exports the current viewport at its canvas resolution, without editor overlays.</p><button className="wide-button" onClick={() => void renderImage()} disabled={!ready}><Camera size={13} />Render image</button></div></details>
              </> : object ? <>
                <div className="property-title"><Box size={14} className="orange" /><input aria-label="Object name" value={object.name} maxLength={100} onChange={event => patch(object.id, { name: event.target.value })} /></div>
                {properties === 'object' ? <>
                  <details open><summary>Transform <Grip size={11} /></summary>{transformFields}<div className="rotation-mode">Mode <span>XYZ Euler<ChevronDown size={10} /></span></div></details>
                  <details><summary>Animation</summary><div className="property-section"><p>{object.keyframes.length} transform keyframes</p><button className="wide-button" onClick={insertKey}><Diamond size={12} />Insert at frame {frame}</button>{object.keyframes.length > 0 && <button className="wide-button" onClick={() => patch(object.id, { keyframes: [] })}>Clear keyframes</button>}</div></details>
                  <details><summary>Relations</summary><div className="property-section"><label className="single-field">Collection<span>{object.collection}</span></label><label className="single-field">Parent<span>None</span></label></div></details>
                </> : null}
                <details open><summary>Material <CircleDot size={12} /></summary><div className="property-section">
                  <button className="material-slot" onClick={() => setProperties('material')}><span style={{ background: object.color }} />{object.name.split(' · ')[1] ?? 'Surface'}<span className="material-users">1</span></button>
                  <div className="surface-title">Surface<span>Principled BSDF</span></div>
                  <label className="single-field color-field">Base Color<input type="color" aria-label="Base color" value={object.color} onChange={event => patch(object.id, { color: event.target.value })} /><span className="hex-label">{object.color.toUpperCase()}</span></label>
                  <div className="palette">{palettes.map(color => <button key={color} aria-label={`Set material ${color}`} title={color} onClick={() => patch(object.id, { color })} style={{ background: color }} className={object.color === color ? 'chosen' : ''} />)}</div>
                  <label className="single-field">Metallic<NumberField label="Metallic" value={object.metallic} min={0} max={1} step={0.05} onChange={metallic => patch(object.id, { metallic })} /></label>
                  <label className="single-field">Roughness<NumberField label="Roughness" value={object.roughness} min={0} max={1} step={0.05} onChange={roughness => patch(object.id, { roughness })} /></label>
                </div></details>
                <div className="object-actions"><button onClick={duplicate}><Copy size={12} />Duplicate</button><button onClick={remove}><Trash2 size={12} />Delete</button></div>
              </> : <div className="no-selection"><MousePointer2 size={24} /><p>Select an object in the viewport or Outliner to edit its properties.</p><button className="wide-button" onClick={() => add('cube')}><Plus size={13} />Add mesh</button></div>}
            </div>
          </div>
        </section>
      </aside>
    </main>
    <footer className="statusbar"><span><MousePointer2 size={11} />Select</span><span><Rotate3D size={11} />Drag to orbit</span><span><Hand size={11} />Right-drag to pan</span><span><Move size={11} />G <span className="shortcut-separator">/</span> R <span className="shortcut-separator">/</span> S Transform</span><div className="status-message" aria-live="polite">{notice}</div><span>{project.objects.length} objects</span><span>Polyn 1.0</span><Grip size={12} /></footer>
    {error && <div className="error-banner" role="alert"><HelpCircle size={16} />{error}<button onClick={() => setError('')} aria-label="Dismiss error"><X size={14} /></button></div>}
    <input ref={fileInput} className="file-input" type="file" accept=".json,application/json" aria-label="Import project" onChange={async event => {
      const file = event.target.files?.[0]
      if (!file) return
      try { const next = parseProject(await file.text()); edit(next); setSelected(next.objects[0]?.id ?? null); setNotice('Project imported'); setAnimate(false) }
      catch (e) { setError(e instanceof Error ? e.message : 'Invalid project file.') }
      event.target.value = ''
    }} />
    <dialog ref={dialogRef} onCancel={() => setModal(null)} className={modal === 'render' ? 'render-dialog' : 'standard-dialog'}>
      <div className="dialog-header"><span>{modal === 'render' ? 'Render Result' : modal === 'reset' ? 'Open built-in loft' : 'Welcome to Polyn'}</span><button aria-label="Close dialog" onClick={() => setModal(null)}><X size={15} /></button></div>
      {modal === 'render' && renderResult ? <><div className="render-meta"><span>Image Editor <ChevronRight size={11} />{project.name}</span><span>WebGL Studio · PNG</span></div><img src={renderResult.url} alt="Rendered architectural loft" /><div className="render-dialog-footer"><span>Current view · ACES Filmic</span><button className="primary-button" onClick={() => downloadFile(renderResult.blob, 'atelier-no-04-render.png')}><Download size={14} />Save image</button></div></> : modal === 'reset' ? <div className="dialog-content"><p>Open a fresh copy of Atelier No. 04? Your current edits can still be recovered with Undo.</p><div className="dialog-actions"><button onClick={() => setModal(null)}>Cancel</button><button className="primary-button" onClick={() => { edit(createProject()); setSelected('sofa'); setAnimate(false); setPlaying(false); setFrame(1); resetCamera(); setModal(null) }}>Open loft</button></div></div> : <div className="dialog-content"><div className="help-brand"><Aperture size={32} /><h2>A space to make your own.</h2></div><p>A Blender-inspired architectural workspace. Select a piece, shape the scene, and find your light.</p><div className="shortcut-list">{[['G / R / S', 'Move, rotate or scale. Choose an axis, type a value, Enter.'], ['Shift D / Delete', 'Duplicate or delete the selected object.'], ['Ctrl Z / Ctrl Shift Z', 'Undo / redo your edits.'], ['I / Space', 'Insert a transform keyframe / play the timeline.'], ['N / Home', 'Toggle the item sidebar / frame the whole project.'], ['Ctrl S / F12', 'Save locally / render an actual PNG image.']].map(([key, text]) => <div key={key}><kbd>{key}</kbd><span>{text}</span></div>)}</div><p className="help-note">Projects autosave in this browser. Use File → Export project for a portable copy. This independent V1 uses Blender 4.2 manual references; it is not affiliated with Blender Foundation. Sculpting, UV editing, modifiers, Cycles and .blend files are outside its scope.</p><button className="primary-button" onClick={() => setModal(null)}>Back to atelier</button></div>}
    </dialog>
  </div>
}
