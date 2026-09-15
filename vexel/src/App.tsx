import { useEffect, useRef, useState, type ReactNode } from 'react'
import {
  ArrowDownToLine,
  Box,
  ChevronDown,
  ChevronRight,
  Circle,
  CircleHelp,
  Copy,
  Cylinder,
  Eye,
  EyeOff,
  FastForward,
  FilePlus2,
  FolderOpen,
  Grid2X2,
  Hand,
  Layers,
  Magnet,
  Maximize2,
  MousePointer2,
  Move,
  Palette,
  Pause,
  Play,
  Plus,
  Redo2,
  Rotate3D,
  RotateCcw,
  Save,
  Scaling,
  Search,
  Settings2,
  SkipBack,
  SkipForward,
  SlidersHorizontal,
  Sun,
  Trash2,
  Triangle,
  Undo2,
  X,
  ZoomIn,
  Diamond,
  Aperture,
  LockKeyhole,
  Lightbulb,
  Shapes,
  Check,
  PanelRight,
  Boxes,
  Target,
  Link2,
  Unlink2,
} from 'lucide-react'
import {
  type Category,
  type History,
  type Kind,
  type Project,
  type SceneObject,
  type Vec3,
  STORAGE_KEY,
  addKey,
  commit,
  createPrimitive,
  initialProject,
  parseProject,
  patchObject,
  playbackFrame,
  redo,
  sample,
  serializeProject,
  undo,
  updateWithKeys,
} from './model'
import { exportOBJ } from './geometry'
import { Viewport, type ViewName } from './Viewport'

type Panel = 'Create' | 'Modify' | 'Material'
type Tool = 'Select' | 'Move' | 'Rotate' | 'Scale'
const categories: Category[] = ['Architecture', 'Sculptures', 'Furniture', 'Landscape']
const palette = ['#b7894f', '#546e65', '#d6ccba', '#b76d55', '#91b8c4', '#747a8d', '#dbcfb2', '#3c4041']

function IconButton({
  title,
  children,
  onClick,
  active = false,
  disabled = false,
  className = '',
}: {
  title: string
  children: ReactNode
  onClick?: () => void
  active?: boolean
  disabled?: boolean
  className?: string
}) {
  return (
    <button
      title={disabled ? `${title} — unavailable in browser V1` : title}
      aria-label={title}
      disabled={disabled}
      onClick={onClick}
      className={`icon-button ${active ? 'selected' : ''} ${className}`}
    >
      {children}
    </button>
  )
}
function NumberField({
  label,
  value,
  onChange,
  onFocus,
  min = -1000,
  max = 1000,
  step = 0.1,
}: {
  label: string
  value: number
  onChange: (n: number) => void
  onFocus?: () => void
  min?: number
  max?: number
  step?: number
}) {
  const [draft, setDraft] = useState(String(Number(value.toFixed(3))))
  useEffect(() => setDraft(String(Number(value.toFixed(3)))), [value])
  function submit() {
    const n = Number(draft)
    if (draft.trim() && Number.isFinite(n)) onChange(Math.min(max, Math.max(min, n)))
    else setDraft(String(Number(value.toFixed(3))))
  }
  return (
    <input
      aria-label={label}
      type="number"
      value={draft}
      min={min}
      max={max}
      step={step}
      onFocus={onFocus}
      onChange={(e) => setDraft(e.target.value)}
      onBlur={submit}
      onKeyDown={(e) => {
        if (e.key === 'Enter') e.currentTarget.blur()
      }}
    />
  )
}
function Rollout({
  title,
  children,
  defaultOpen = true,
}: {
  title: string
  children: ReactNode
  defaultOpen?: boolean
}) {
  const [open, setOpen] = useState(defaultOpen)
  return (
    <section className="rollout">
      <button className="rollout-title" onClick={() => setOpen(!open)}>
        {open ? <ChevronDown size={11} /> : <ChevronRight size={11} />}
        {title}
      </button>
      {open && <div className="rollout-body">{children}</div>}
    </section>
  )
}
function load(): History {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    return { past: [], present: stored ? parseProject(stored) : initialProject(), future: [] }
  } catch {
    return { past: [], present: initialProject(), future: [] }
  }
}

export default function App() {
  const [history, setHistory] = useState<History>(load)
  const project = history.present
  const [selected, setSelected] = useState<string | null>('hero')
  const [panel, setPanel] = useState<Panel>('Modify')
  const [tool, setTool] = useState<Tool>('Move')
  const [search, setSearch] = useState('')
  const [collapsed, setCollapsed] = useState<Category[]>([])
  const [active, setActive] = useState<ViewName>('Perspective')
  const [maximized, setMaximized] = useState(false)
  const [grid, setGrid] = useState(true)
  const [lighting, setLighting] = useState<'Studio' | 'Daylight'>('Studio')
  const [cameraReset, setCameraReset] = useState(0)
  const [frame, setFrame] = useState(0)
  const frameRef = useRef(frame)
  frameRef.current = frame
  const [playing, setPlaying] = useState(false)
  const [autoKey, setAutoKey] = useState(false)
  const [menu, setMenu] = useState<string | null>(null)
  const [modal, setModal] = useState<'reset' | 'help' | null>(null)
  const [message, setMessage] = useState('Select an object to edit its parameters.')
  const [saveError, setSaveError] = useState('')
  const [ribbon, setRibbon] = useState('Modeling')
  const fileInput = useRef<HTMLInputElement>(null)
  const object = project.objects.find((o) => o.id === selected)
  const displayed = object ? sample(object, frame) : null

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, serializeProject(project))
      setSaveError('')
    } catch {
      setSaveError('Local storage is full or unavailable. Export JSON to preserve this project.')
    }
  }, [project])
  useEffect(() => {
    if (!playing) return
    const start = performance.now(),
      startFrame = frameRef.current
    const timer = setInterval(() => setFrame(playbackFrame(startFrame, performance.now() - start)), 1000 / 24)
    return () => clearInterval(timer)
  }, [playing])

  function seek(nextFrame: number) {
    setPlaying(false)
    setFrame(Math.max(0, Math.min(100, Math.round(nextFrame))))
  }
  function edit(next: Project, status: string) {
    setHistory((h) => commit(h, next))
    setMessage(status)
  }
  function patch(p: Partial<SceneObject>, status = 'Object parameters updated.') {
    if (!object) return
    const next = updateWithKeys(object, p, frame, autoKey)
    edit(patchObject(project, object.id, next), status)
  }
  function create(kind: Kind) {
    if (project.objects.length >= 200) {
      setMessage('This project has reached the 200 object limit.')
      return
    }
    const next = createPrimitive(project, kind)
    edit({ ...project, objects: [...project.objects, next] }, `${next.name} created.`)
    setSelected(next.id)
    setPanel('Modify')
  }
  function remove() {
    if (!object) return
    edit({ ...project, objects: project.objects.filter((o) => o.id !== object.id) }, `${object.name} deleted.`)
    setSelected(null)
  }
  function duplicate() {
    if (!object || project.objects.length >= 200) return
    const clone = createPrimitive(project, object.kind)
    const offset = sample(object, frame)
    const next = {
      ...object,
      ...offset,
      id: clone.id,
      name: `${object.name.slice(0, 90)} copy`,
      keys: [],
      position: [Math.min(1000, offset.position[0] + 1.5), offset.position[1], offset.position[2]] as Vec3,
    }
    edit({ ...project, objects: [...project.objects, next] }, `${next.name} created.`)
    setSelected(next.id)
  }
  function save() {
    try {
      localStorage.setItem(STORAGE_KEY, serializeProject(project))
      setSaveError('')
      setMessage('Project saved in this browser.')
    } catch {
      setSaveError('Could not save locally. Export JSON to preserve your work.')
    }
  }
  function download(format: 'json' | 'obj') {
    const content = format === 'json' ? serializeProject(project) : exportOBJ(project, frame)
    const blob = new Blob([content], { type: format === 'json' ? 'application/json' : 'text/plain' })
    const url = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = `forma-gallery.${format}`
    anchor.click()
    setTimeout(() => URL.revokeObjectURL(url), 1000)
    setMessage(`${format.toUpperCase()} exported${format === 'obj' ? ` at frame ${frame}` : ''}.`)
    setMenu(null)
  }
  async function importProject(file?: File) {
    if (!file) return
    try {
      if (file.size > 2_000_000) throw new Error('Project exceeds the 2 MB limit.')
      const next = parseProject(await file.text())
      edit(next, `Opened ${next.name}.`)
      setSelected(next.objects[0]?.id ?? null)
      setFrame(0)
      setPlaying(false)
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Could not open project.')
    }
    if (fileInput.current) fileInput.current.value = ''
  }
  function setKey() {
    if (!object) return
    patch(
      { keys: addKey({ ...object, ...sample(object, frame) }, frame) },
      `Key set for ${object.name} at frame ${frame}.`,
    )
  }
  function select(id: string | null) {
    setSelected(id)
    setMessage(
      id
        ? 'Edit numeric transforms in the Command Panel.'
        : 'No object selected. Click in a viewport or Scene Explorer.',
    )
  }

  useEffect(() => {
    const keydown = (e: KeyboardEvent) => {
      const target = e.target
      if (
        target instanceof HTMLInputElement ||
        target instanceof HTMLTextAreaElement ||
        target instanceof HTMLSelectElement
      )
        return
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
        e.preventDefault()
        setHistory((h) => (e.shiftKey ? redo(h) : undo(h)))
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'y') {
        e.preventDefault()
        setHistory(redo)
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
        e.preventDefault()
        save()
      } else if (e.altKey && e.key.toLowerCase() === 'w') {
        e.preventDefault()
        setMaximized((v) => !v)
      } else if (e.code === 'Space') {
        e.preventDefault()
        setPlaying((v) => !v)
      } else if (e.key === 'Delete') remove()
      else if (e.key.toLowerCase() === 'g') setGrid((v) => !v)
      else if (e.key.toLowerCase() === 'f') setCameraReset((v) => v + 1)
      else if (e.key === 'Escape') {
        setMenu(null)
        setModal(null)
      }
    }
    window.addEventListener('keydown', keydown)
    return () => window.removeEventListener('keydown', keydown)
  })

  const menuActions: Record<string, { label: string; shortcut?: string; action: () => void; disabled?: boolean }[]> = {
    File: [
      { label: 'New · reset gallery…', shortcut: '', action: () => setModal('reset') },
      { label: 'Open Vexel project…', shortcut: 'JSON', action: () => fileInput.current?.click() },
      { label: 'Save project locally', shortcut: 'Ctrl+S', action: save },
      { label: 'Export project…', shortcut: '.json', action: () => download('json') },
      { label: 'Export visible geometry…', shortcut: '.obj', action: () => download('obj') },
    ],
    Edit: [
      { label: 'Undo', shortcut: 'Ctrl+Z', action: () => setHistory(undo), disabled: !history.past.length },
      { label: 'Redo', shortcut: 'Ctrl+Y', action: () => setHistory(redo), disabled: !history.future.length },
      { label: 'Clone selected', action: duplicate, disabled: !object },
      { label: 'Delete selected', shortcut: 'Del', action: remove, disabled: !object },
    ],
    Views: [
      ...(['Top', 'Front', 'Left', 'Perspective'] as ViewName[]).map((view) => ({
        label: `${view} viewport`,
        action: () => setActive(view),
      })),
      {
        label: maximized ? 'Restore four viewports' : 'Maximize active viewport',
        shortcut: 'Alt+W',
        action: () => setMaximized((v) => !v),
      },
      { label: 'Show grid', shortcut: 'G', action: () => setGrid((v) => !v) },
      { label: 'Reset view cameras', shortcut: 'F', action: () => setCameraReset((v) => v + 1) },
    ],
    Create: ['box', 'sphere', 'cylinder', 'torus'].map((kind) => ({
      label: kind[0].toUpperCase() + kind.slice(1),
      action: () => create(kind as Kind),
    })),
    Modifiers: [
      {
        label: 'Twist',
        action: () => {
          setPanel('Modify')
          patch({ twist: 90 })
        },
        disabled: !object,
      },
    ],
    Animation: [
      { label: playing ? 'Stop playback' : 'Play animation', shortcut: 'Space', action: () => setPlaying((v) => !v) },
      { label: 'Set key', action: setKey, disabled: !object },
      { label: 'Clear selected animation', action: () => patch({ keys: [] }), disabled: !object?.keys.length },
    ],
    Rendering: [
      { label: 'Studio lighting', action: () => setLighting('Studio') },
      { label: 'Daylight lighting', action: () => setLighting('Daylight') },
      { label: 'Material editor', shortcut: '', action: () => setPanel('Material') },
    ],
    Help: [{ label: 'About Vexel / keyboard shortcuts', action: () => setModal('help') }],
  }
  const transformFields =
    object && displayed
      ? (['position', 'rotation', 'scale'] as const).map((property, index) => (
          <div
            className={`transform-block ${tool === ['Move', 'Rotate', 'Scale'][index] ? 'emphasized' : ''}`}
            key={property}
          >
            <div className="field-caption">
              {['Position', 'Rotation', 'Scale'][index]} <span>{['m', '°', '×'][index]}</span>
            </div>
            <div className="xyz">
              {(['X', 'Y', 'Z'] as const).map((axis, i) => (
                <label key={axis}>
                  <span className={`color-${axis.toLowerCase()}`}>{axis}</span>
                  <NumberField
                    label={`${property} ${axis}`}
                    value={displayed[property][i]}
                    min={property === 'scale' ? 0.01 : -1000}
                    max={property === 'scale' ? 100 : 1000}
                    onChange={(n) => {
                      const vector = [...displayed[property]] as Vec3
                      vector[i] = n
                      patch({ [property]: vector })
                    }}
                  />
                </label>
              ))}
            </div>
          </div>
        ))
      : null

  return (
    <div className="app">
      <header className="titlebar">
        <div className="brand-mark">V</div>
        <strong>VEXEL</strong>
        <span className="title-separator">|</span>
        <span>{project.name.toLowerCase().replaceAll(' ', '_')}.vxl</span>
        <span className="title-detail">— Architectural visualization</span>
        <div className="title-right">
          <span className={`saved-dot ${saveError ? 'error' : ''}`} />
          {saveError ? 'Save unavailable' : 'Local project'}
          <span className="title-separator">|</span>
          <span>Workspace:</span>
          <button
            onClick={() => {
              setMaximized(false)
              setPanel('Modify')
              setCameraReset((v) => v + 1)
            }}
          >
            Default <ChevronDown size={11} />
          </button>
          <CircleHelp size={14} onClick={() => setModal('help')} />
        </div>
      </header>
      <nav className="menubar" aria-label="Main menu">
        {[
          'File',
          'Edit',
          'Tools',
          'Group',
          'Views',
          'Create',
          'Modifiers',
          'Animation',
          'Graph Editors',
          'Rendering',
          'Customize',
          'Scripting',
          'Help',
        ].map((name) => (
          <div className="menu-anchor" key={name}>
            <button
              disabled={!menuActions[name]}
              title={!menuActions[name] ? 'Unavailable in browser V1' : name}
              className={menu === name ? 'open' : ''}
              onClick={() => setMenu(menu === name ? null : name)}
            >
              {name}
            </button>
            {menu === name && (
              <div className="dropdown">
                {menuActions[name].map((action) => (
                  <button
                    key={action.label}
                    disabled={action.disabled}
                    onClick={() => {
                      action.action()
                      setMenu(null)
                    }}
                  >
                    <span>{action.label}</span>
                    <small>{action.shortcut}</small>
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}
        <span className="menubar-end">FORMA / 01</span>
      </nav>
      {menu && <div className="menu-dismiss" onClick={() => setMenu(null)} />}
      <div className="toolbar">
        <div className="tool-group">
          <IconButton title="Undo (Ctrl+Z)" disabled={!history.past.length} onClick={() => setHistory(undo)}>
            <Undo2 />
          </IconButton>
          <IconButton title="Redo (Ctrl+Y)" disabled={!history.future.length} onClick={() => setHistory(redo)}>
            <Redo2 />
          </IconButton>
        </div>
        <div className="tool-group">
          <IconButton title="Link objects" disabled>
            <Link2 />
          </IconButton>
          <IconButton title="Unlink objects" disabled>
            <Unlink2 />
          </IconButton>
          <IconButton title="Bind to space warp" disabled>
            <Magnet />
          </IconButton>
        </div>
        <div className="tool-group">
          <select
            aria-label="Selection filter"
            onChange={(e) => setSearch(e.target.value)}
            value={categories.includes(search as Category) ? search : ''}
          >
            <option value="">All</option>
            {categories.map((c) => (
              <option key={c}>{c}</option>
            ))}
          </select>
          <IconButton title="Select object" active={tool === 'Select'} onClick={() => setTool('Select')}>
            <MousePointer2 className="amber" />
          </IconButton>
          <IconButton title="Select by name" onClick={() => document.getElementById('scene-search')?.focus()}>
            <Search />
          </IconButton>
          <IconButton title="Rectangular selection" disabled>
            <Box className="cyan" />
          </IconButton>
        </div>
        <div className="tool-group">
          <IconButton
            title="Select and move · numeric"
            active={tool === 'Move'}
            onClick={() => {
              setTool('Move')
              setPanel('Modify')
            }}
          >
            <Move />
          </IconButton>
          <IconButton
            title="Select and rotate · numeric"
            active={tool === 'Rotate'}
            onClick={() => {
              setTool('Rotate')
              setPanel('Modify')
            }}
          >
            <Rotate3D />
          </IconButton>
          <IconButton
            title="Select and scale · numeric"
            active={tool === 'Scale'}
            onClick={() => {
              setTool('Scale')
              setPanel('Modify')
            }}
          >
            <Scaling />
          </IconButton>
          <select aria-label="Transform coordinates" disabled>
            <option>World</option>
          </select>
        </div>
        <div className="tool-group">
          <IconButton title="Transform center" disabled>
            <Target />
          </IconButton>
          <IconButton title="Toggle grid (G)" active={grid} onClick={() => setGrid(!grid)}>
            <Grid2X2 className="cyan" />
          </IconButton>
          <IconButton title="Snap toggle" disabled>
            <Magnet />
          </IconButton>
          <IconButton title="Angle snap" disabled>
            <RotateCcw />
          </IconButton>
        </div>
        <div className="tool-group">
          <IconButton title="Clone selected" onClick={duplicate} disabled={!object}>
            <Copy />
          </IconButton>
          <IconButton
            title="Scene Explorer"
            onClick={() => {
              setCollapsed([])
              setSearch('')
            }}
          >
            <Layers className="cyan" />
          </IconButton>
          <IconButton title="Command Panel" onClick={() => setPanel('Modify')}>
            <PanelRight />
          </IconButton>
        </div>
        <div className="tool-group">
          <IconButton title="Material editor" active={panel === 'Material'} onClick={() => setPanel('Material')}>
            <Palette className="material-icon" />
          </IconButton>
          <IconButton
            title="Toggle studio / daylight"
            onClick={() => setLighting(lighting === 'Studio' ? 'Daylight' : 'Studio')}
          >
            <Sun className="amber" />
          </IconButton>
          <IconButton title="Save project" onClick={save}>
            <Save className="cyan" />
          </IconButton>
        </div>
        <div className="toolbar-project">
          <FolderOpen size={15} />
          <span>Forma Gallery</span>
          <ChevronDown size={12} />
        </div>
      </div>
      <div className="ribbon">
        <div className="ribbon-tabs">
          {['Modeling', 'Freeform', 'Selection', 'Object Paint', 'Populate'].map((t) => (
            <button
              key={t}
              className={ribbon === t ? 'active' : ''}
              disabled={t !== 'Modeling'}
              title={t !== 'Modeling' ? 'Unavailable in browser V1' : t}
              onClick={() => setRibbon(t)}
            >
              {t}
            </button>
          ))}
          <span>Graphite Modeling Tools</span>
          <ChevronDown size={12} />
        </div>
        <div className="ribbon-content">
          <div className="ribbon-section wide">
            <div className="ribbon-items">
              <button className="ribbon-large" onClick={() => create('box')}>
                <Box size={27} className="cyan" />
                <span>
                  Create
                  <br />
                  geometry
                </span>
              </button>
              <div className="ribbon-stack">
                <button onClick={() => create('sphere')}>
                  <Circle size={15} />
                  Sphere
                </button>
                <button onClick={() => create('cylinder')}>
                  <Cylinder size={15} />
                  Cylinder
                </button>
                <button onClick={() => create('torus')}>
                  <Aperture size={15} />
                  Torus
                </button>
              </div>
            </div>
            <div className="ribbon-caption">
              Object creation <ChevronDown size={9} />
            </div>
          </div>
          <div className="ribbon-section">
            <div className="ribbon-items">
              <button
                className="ribbon-large"
                onClick={() => {
                  setPanel('Modify')
                  patch({ twist: object?.twist ? 0 : 90 })
                }}
                disabled={!object}
              >
                <Rotate3D size={25} className="amber" />
                <span>Twist</span>
              </button>
              <div className="ribbon-stack">
                <button onClick={duplicate} disabled={!object}>
                  <Copy size={14} />
                  Clone
                </button>
                <button onClick={() => patch({ twist: 0, scale: [1, 1, 1] })} disabled={!object}>
                  <RotateCcw size={14} />
                  Reset form
                </button>
                <button disabled title="Native Edit Poly unavailable">
                  <Triangle size={14} />
                  Edit Poly
                </button>
              </div>
            </div>
            <div className="ribbon-caption">Modify</div>
          </div>
          <div className="ribbon-section">
            <div className="ribbon-items">
              <button className="ribbon-large" onClick={() => setPanel('Material')}>
                <Palette size={28} className="material-icon" />
                <span>
                  Material
                  <br />
                  editor
                </span>
              </button>
              <div className="ribbon-swatches">
                {palette.slice(0, 6).map((color) => (
                  <button
                    aria-label={`Apply ${color}`}
                    key={color}
                    style={{ background: color }}
                    disabled={!object}
                    onClick={() => patch({ color })}
                  />
                ))}
              </div>
            </div>
            <div className="ribbon-caption">Materials</div>
          </div>
          <div className="ribbon-section">
            <div className="ribbon-items">
              <button
                className="ribbon-large"
                onClick={() => setLighting(lighting === 'Studio' ? 'Daylight' : 'Studio')}
              >
                <Sun size={25} className="amber" />
                <span>
                  {lighting}
                  <br />
                  lighting
                </span>
              </button>
              <button className="ribbon-large" onClick={() => setMaximized(!maximized)}>
                <Maximize2 size={23} />
                <span>
                  {maximized ? 'Four views' : 'Maximize'}
                  <br />
                  viewport
                </span>
              </button>
            </div>
            <div className="ribbon-caption">Viewport display</div>
          </div>
          <div className="ribbon-section">
            <div className="ribbon-items">
              <button className="ribbon-large" onClick={() => download('json')}>
                <ArrowDownToLine size={25} className="cyan" />
                <span>
                  Save
                  <br />
                  project
                </span>
              </button>
              <button className="ribbon-large" onClick={() => download('obj')}>
                <Boxes size={26} />
                <span>
                  Export
                  <br />
                  geometry
                </span>
              </button>
            </div>
            <div className="ribbon-caption">Project</div>
          </div>
          <div className="ribbon-note">
            <span>SCENE COLLECTION</span>
            <b>Forma Gallery</b>
            <small>Light, rhythm & sculptural form</small>
          </div>
        </div>
      </div>
      <main className="workspace">
        <aside className="explorer">
          <div className="panel-heading">
            <Layers size={13} />
            <b>Scene Explorer</b>
            <span className="flex-gap" />
            <Settings2 size={12} />
          </div>
          <div className="explorer-menu">
            <button onClick={() => setCollapsed([])}>Select</button>
            <button onClick={() => setCollapsed(collapsed.length ? [] : categories)}>Display</button>
            <button
              onClick={() => {
                setSearch('')
                setCollapsed([])
              }}
            >
              Customize
            </button>
          </div>
          <div className="explorer-search">
            <Search size={13} />
            <input
              id="scene-search"
              aria-label="Search scene"
              placeholder="Search scene..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            {search && (
              <button aria-label="Clear search" onClick={() => setSearch('')}>
                <X size={11} />
              </button>
            )}
          </div>
          <div className="explorer-columns">
            <span>Name (A–Z)</span>
            <Eye size={12} />
          </div>
          <div className="object-tree">
            {categories.map((category) => {
              const objects = project.objects.filter(
                (o) =>
                  o.category === category &&
                  (o.name.toLowerCase().includes(search.toLowerCase()) ||
                    o.category.toLowerCase().includes(search.toLowerCase())),
              )
              if (!objects.length) return null
              const closed = collapsed.includes(category) && !search
              return (
                <div key={category}>
                  <button
                    className="tree-category"
                    onClick={() =>
                      setCollapsed(closed ? collapsed.filter((c) => c !== category) : [...collapsed, category])
                    }
                  >
                    {closed ? <ChevronRight size={11} /> : <ChevronDown size={11} />}
                    <FolderOpen size={13} />
                    <span>{category}</span>
                    <small>{objects.length}</small>
                  </button>
                  {!closed &&
                    objects.map((o) => (
                      <div
                        className={`tree-object ${selected === o.id ? 'selected' : ''} ${!o.visible ? 'invisible' : ''}`}
                        key={o.id}
                      >
                        <button title={o.name} onClick={() => select(o.id)} className="object-select">
                          <span className="tree-indent" />
                          <Box size={12} style={{ color: o.category === 'Sculptures' ? '#cbb17c' : '#83a3a4' }} />
                          <span>{o.name}</span>
                        </button>
                        <button
                          className="visibility"
                          aria-label={`${o.visible ? 'Hide' : 'Show'} ${o.name}`}
                          onClick={() =>
                            edit(
                              patchObject(project, o.id, { visible: !o.visible }),
                              `${o.name} ${o.visible ? 'hidden' : 'shown'}.`,
                            )
                          }
                        >
                          {o.visible ? <Eye size={11} /> : <EyeOff size={11} />}
                        </button>
                      </div>
                    ))}
                </div>
              )
            })}
            {!project.objects.some((o) => `${o.name} ${o.category}`.toLowerCase().includes(search.toLowerCase())) && (
              <p className="empty-search">No matching objects</p>
            )}
          </div>
          <div className="explorer-bottom">
            <div>
              <span className="saved-dot" />
              {project.objects.filter((o) => o.visible).length} / {project.objects.length} objects visible
            </div>
            <div className="explorer-bottom-tools">
              <button onClick={() => setCollapsed([])}>
                <Layers size={12} /> Default
              </button>
              <IconButton title="Create object" onClick={() => setPanel('Create')}>
                <Plus size={13} />
              </IconButton>
              <IconButton title="Delete selected" disabled={!object} onClick={remove}>
                <Trash2 size={13} />
              </IconButton>
            </div>
          </div>
        </aside>
        <div className="viewport-column">
          <Viewport
            project={project}
            selected={selected}
            frame={frame}
            active={active}
            maximized={maximized}
            grid={grid}
            lighting={lighting}
            cameraReset={cameraReset}
            onSelect={select}
            onActive={setActive}
            onMaximize={() => setMaximized((v) => !v)}
          />
          <div className="viewport-bottom">
            <span>
              <span className="live-dot" />
              {active}
            </span>
            <span>Real-time · {lighting}</span>
            <span>World units: meters</span>
          </div>
        </div>
        <aside className="command-panel">
          <div className="command-tabs">
            <IconButton title="Create" active={panel === 'Create'} onClick={() => setPanel('Create')}>
              <Plus />
            </IconButton>
            <IconButton title="Modify" active={panel === 'Modify'} onClick={() => setPanel('Modify')}>
              <SlidersHorizontal className="cyan" />
            </IconButton>
            <IconButton title="Hierarchy" disabled>
              <Layers />
            </IconButton>
            <IconButton title="Motion" disabled>
              <Rotate3D />
            </IconButton>
            <IconButton title="Material" active={panel === 'Material'} onClick={() => setPanel('Material')}>
              <Palette />
            </IconButton>
            <IconButton title="Utilities" onClick={() => setModal('help')}>
              <Settings2 />
            </IconButton>
          </div>
          <div className="command-scroll" onFocus={() => setPlaying(false)}>
            {panel === 'Create' ? (
              <>
                <div className="create-category">
                  <span className="icon-button selected" title="Geometry">
                    <Circle />
                  </span>
                  <IconButton title="Shapes" disabled>
                    <Shapes />
                  </IconButton>
                  <IconButton title="Lights" disabled>
                    <Lightbulb />
                  </IconButton>
                  <IconButton title="Helpers" disabled>
                    <Target />
                  </IconButton>
                </div>
                <div className="select-static">
                  Standard Primitives <ChevronDown size={11} />
                </div>
                <Rollout title="Object Type">
                  <p className="muted small">Create at X 2.8, Y 1, Z 2.8 m</p>
                  <div className="primitive-grid">
                    {(['box', 'sphere', 'cylinder', 'torus'] as Kind[]).map((kind) => (
                      <button key={kind} onClick={() => create(kind)}>
                        {kind[0].toUpperCase() + kind.slice(1)}
                      </button>
                    ))}
                  </div>
                  <p className="muted small">Select the new object to adjust its transform and material.</p>
                </Rollout>
              </>
            ) : object ? (
              <>
                <div className="object-name">
                  <input
                    aria-label="Object name"
                    key={object.id + object.name}
                    defaultValue={object.name}
                    maxLength={100}
                    onBlur={(e) => {
                      const name = e.target.value.trim()
                      if (name) patch({ name })
                      else e.target.value = object.name
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') e.currentTarget.blur()
                    }}
                  />
                  <input
                    aria-label="Object color"
                    type="color"
                    value={object.color}
                    onChange={(e) => patch({ color: e.target.value })}
                  />
                </div>
                {panel === 'Modify' ? (
                  <>
                    <select
                      className="modifier-list"
                      aria-label="Modifier List"
                      value=""
                      onChange={(e) => {
                        if (e.target.value === 'twist') patch({ twist: 90 })
                      }}
                    >
                      <option value="">Modifier List</option>
                      <option value="twist">Twist</option>
                    </select>
                    <div className="modifier-stack">
                      <div className={object.twist !== 0 ? 'stack-modifier' : 'stack-muted'}>
                        <Eye size={12} />
                        <span>{object.twist !== 0 ? 'Twist' : 'No modifiers applied'}</span>
                        {object.twist !== 0 && (
                          <button aria-label="Remove Twist" onClick={() => patch({ twist: 0 })}>
                            <X size={11} />
                          </button>
                        )}
                      </div>
                      <div className="stack-base">
                        <Box size={12} />
                        {object.kind === 'sculpture'
                          ? 'Editable spline mesh'
                          : object.kind[0].toUpperCase() + object.kind.slice(1)}
                      </div>
                    </div>
                    <div className="stack-tools">
                      <span className="icon-button selected" title="End result displayed">
                        <Eye size={13} />
                      </span>
                      <IconButton title="Make unique" disabled>
                        <Copy size={13} />
                      </IconButton>
                      <IconButton title="Remove modifier" onClick={() => patch({ twist: 0 })} disabled={!object.twist}>
                        <Trash2 size={13} />
                      </IconButton>
                      <span className="flex-gap" />
                      <span>1 object</span>
                    </div>
                    <Rollout title="Transform">
                      {transformFields}
                      <button
                        className="subtle-button"
                        onClick={() => patch({ position: [0, 1, 0], rotation: [0, 0, 0], scale: [1, 1, 1] })}
                      >
                        Reset transform
                      </button>
                    </Rollout>
                    <Rollout title="Twist Parameters">
                      <div className="row-field">
                        <span>Angle</span>
                        <NumberField
                          label="Twist angle"
                          value={object.twist}
                          min={-360}
                          max={360}
                          step={5}
                          onChange={(twist) => patch({ twist })}
                        />
                        <span>°</span>
                      </div>
                      <input
                        className="full-range"
                        aria-label="Twist slider"
                        type="range"
                        min="-360"
                        max="360"
                        step="5"
                        value={object.twist}
                        onChange={(e) => patch({ twist: Number(e.target.value) })}
                      />
                      <div className="row-field">
                        <span>Twist axis</span>
                        <span className="axis-tag">Y</span>
                        <small className="muted">Local object space</small>
                      </div>
                    </Rollout>
                    <Rollout title="Animation">
                      <div className="animation-summary">
                        <Diamond size={12} />
                        <span>{object.keys.length} position / rotation / scale keys</span>
                      </div>
                      <div className="two-buttons">
                        <button onClick={setKey}>Set key · {frame}</button>
                        <button disabled={!object.keys.length} onClick={() => patch({ keys: [] })}>
                          Clear keys
                        </button>
                      </div>
                    </Rollout>
                  </>
                ) : (
                  <>
                    <Rollout title="Physical Material">
                      <div
                        className="material-preview"
                        style={{ '--material-color': object.color } as React.CSSProperties}
                      >
                        <div />
                        <span>{object.name}</span>
                      </div>
                      <label className="color-field">
                        Base color
                        <input
                          type="color"
                          aria-label="Material base color"
                          value={object.color}
                          onChange={(e) => patch({ color: e.target.value })}
                        />
                        <code>{object.color}</code>
                      </label>
                      <div className="material-swatches">
                        {palette.map((color) => (
                          <button
                            aria-label={`Material ${color}`}
                            key={color}
                            className={color === object.color ? 'active' : ''}
                            style={{ background: color }}
                            onClick={() => patch({ color })}
                          />
                        ))}
                      </div>
                      <div className="row-field">
                        <span>Roughness</span>
                        <NumberField
                          label="Roughness"
                          value={object.roughness}
                          min={0}
                          max={1}
                          step={0.05}
                          onChange={(roughness) => patch({ roughness })}
                        />
                      </div>
                      <input
                        type="range"
                        className="full-range"
                        aria-label="Roughness slider"
                        min="0"
                        max="1"
                        step="0.05"
                        value={object.roughness}
                        onChange={(e) => patch({ roughness: Number(e.target.value) })}
                      />
                      <div className="row-field">
                        <span>Metalness</span>
                        <NumberField
                          label="Metalness"
                          value={object.metalness}
                          min={0}
                          max={1}
                          step={0.05}
                          onChange={(metalness) => patch({ metalness })}
                        />
                      </div>
                      <input
                        type="range"
                        className="full-range"
                        aria-label="Metalness slider"
                        min="0"
                        max="1"
                        step="0.05"
                        value={object.metalness}
                        onChange={(e) => patch({ metalness: Number(e.target.value) })}
                      />
                    </Rollout>
                    <Rollout title="Material presets">
                      <div className="preset-list">
                        <button onClick={() => patch({ color: '#b7894f', roughness: 0.28, metalness: 0.8 })}>
                          <span style={{ background: '#b7894f' }} />
                          Satin bronze
                          <ChevronRight size={12} />
                        </button>
                        <button onClick={() => patch({ color: '#d6ccba', roughness: 0.85, metalness: 0 })}>
                          <span style={{ background: '#d6ccba' }} />
                          Limestone
                          <ChevronRight size={12} />
                        </button>
                        <button onClick={() => patch({ color: '#546e65', roughness: 0.24, metalness: 0.35 })}>
                          <span style={{ background: '#546e65' }} />
                          Patinated copper
                          <ChevronRight size={12} />
                        </button>
                      </div>
                    </Rollout>
                  </>
                )}
              </>
            ) : (
              <div className="no-selection">
                <MousePointer2 size={28} />
                <b>No object selected</b>
                <p>Select an object in a viewport or the Scene Explorer.</p>
                <button onClick={() => setPanel('Create')}>Create an object</button>
              </div>
            )}
          </div>
          <div className="command-footer">
            <LockKeyhole size={11} />
            {object ? object.category : 'Scene'}
            <span className="flex-gap" />
            VEXEL 1.0
          </div>
        </aside>
      </main>
      <div className={`timeline ${autoKey ? 'recording' : ''}`}>
        <div className="timeline-top">
          <button className="time-range" onClick={() => seek(0)}>
            <ChevronRight size={11} />0 / 100
            <ChevronDown size={11} />
          </button>
          <span>{object?.name ?? 'No object selected'}</span>
          <div className="flex-gap" />
          <span className="timeline-fps">24 FPS</span>
          <button onClick={() => seek(0)}>Full range</button>
          <Settings2 size={12} />
        </div>
        <div className="track">
          <div className="track-ticks">
            {Array.from({ length: 21 }, (_, i) => (
              <span key={i}>{i * 5}</span>
            ))}
          </div>
          <div className="key-track">
            {object?.keys.map((key) => (
              <button
                key={key.frame}
                title={`Key at frame ${key.frame}`}
                aria-label={`Go to key ${key.frame}`}
                style={{ left: `${key.frame}%` }}
                onClick={() => {
                  setFrame(key.frame)
                  setPlaying(false)
                }}
              >
                <Diamond size={9} fill="#ddb152" />
              </button>
            ))}
          </div>
          <div className="playhead" style={{ left: `calc(12px + (100% - 24px) * ${frame / 100})` }}>
            <span>{frame}</span>
          </div>
          <input
            aria-label="Timeline frame"
            type="range"
            min="0"
            max="100"
            step="1"
            value={frame}
            onChange={(e) => {
              setPlaying(false)
              setFrame(Number(e.target.value))
            }}
          />
        </div>
      </div>
      <footer className="statusbar">
        <div className="status-message">
          <div>
            <span className="status-square" />
            {object ? '1 Object Selected' : 'None Selected'}
            <span className="muted"> / {project.objects.length} total</span>
          </div>
          <p role="status">{saveError || message}</p>
        </div>
        <div className="status-coordinates">
          <LockKeyhole size={12} />
          {(['X', 'Y', 'Z'] as const).map((axis, i) => (
            <span key={axis}>
              {axis}: <b>{displayed?.position[i].toFixed(2) ?? '0.00'}</b>
            </span>
          ))}
          <small>Grid = 1.0 m</small>
        </div>
        <div className="key-controls">
          <button className={autoKey ? 'auto-key active' : 'auto-key'} onClick={() => setAutoKey(!autoKey)}>
            Auto Key
          </button>
          <button onClick={setKey} disabled={!object}>
            <Plus size={12} />
            Set Key
          </button>
        </div>
        <div className="transport">
          <div>
            <IconButton title="First frame" onClick={() => seek(0)}>
              <SkipBack />
            </IconButton>
            <IconButton title="Previous frame" onClick={() => seek(frame - 1)}>
              <Play className="backward" />
            </IconButton>
            <IconButton
              title={playing ? 'Pause animation' : 'Play animation'}
              active={playing}
              onClick={() => setPlaying(!playing)}
            >
              {playing ? <Pause /> : <Play />}
            </IconButton>
            <IconButton title="Next frame" onClick={() => seek(frame + 1)}>
              <FastForward />
            </IconButton>
            <IconButton title="Last frame" onClick={() => seek(100)}>
              <SkipForward />
            </IconButton>
          </div>
          <label>
            <span>Frame</span>
            <NumberField
              label="Current frame"
              value={frame}
              min={0}
              max={100}
              step={1}
              onChange={seek}
              onFocus={() => setPlaying(false)}
            />
          </label>
        </div>
        <div className="navigation-controls">
          <IconButton title="Reset view cameras (F)" onClick={() => setCameraReset((v) => v + 1)}>
            <ZoomIn />
          </IconButton>
          <IconButton title="Orbit · drag Perspective" onClick={() => setActive('Perspective')}>
            <Rotate3D />
          </IconButton>
          <IconButton title="Pan · right-drag Perspective" onClick={() => setActive('Perspective')}>
            <Hand />
          </IconButton>
          <IconButton title="Maximize active viewport (Alt+W)" onClick={() => setMaximized(!maximized)}>
            <Maximize2 />
          </IconButton>
        </div>
      </footer>
      <input
        className="hidden"
        ref={fileInput}
        type="file"
        accept=".json,application/json"
        onChange={(e) => void importProject(e.target.files?.[0])}
      />
      {modal && (
        <div className="modal-backdrop" onClick={() => setModal(null)}>
          <section
            className="dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="dialog-title"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="dialog-title">
              <b id="dialog-title">
                {modal === 'reset' ? 'Reset Forma Gallery?' : 'Vexel · architectural scene studio'}
              </b>
              <button aria-label="Close dialog" onClick={() => setModal(null)}>
                <X size={15} />
              </button>
            </div>
            {modal === 'reset' ? (
              <>
                <p>
                  Restore the original gallery, objects and materials. Your current changes can be recovered with Undo.
                </p>
                <div className="dialog-actions">
                  <button onClick={() => setModal(null)}>Cancel</button>
                  <button
                    className="primary"
                    onClick={() => {
                      edit(initialProject(), 'Original gallery restored.')
                      setSelected('hero')
                      setFrame(0)
                      setPlaying(false)
                      setModal(null)
                    }}
                  >
                    <FilePlus2 size={13} />
                    Reset gallery
                  </button>
                </div>
              </>
            ) : (
              <>
                <p>A local, interactive architectural scene editor inspired by the Autodesk 3ds Max 2025 workspace.</p>
                <dl>
                  <dt>Alt + W</dt>
                  <dd>Maximize / restore active viewport</dd>
                  <dt>Ctrl + Z / Y</dt>
                  <dd>Undo / redo scene changes</dd>
                  <dt>Space</dt>
                  <dd>Play / pause animation</dd>
                  <dt>G / F</dt>
                  <dd>Toggle grid / reset cameras</dd>
                  <dt>Ctrl + S</dt>
                  <dd>Save locally</dd>
                  <dt>Delete</dt>
                  <dd>Delete selected object</dd>
                </dl>
                <p>
                  Drag to orbit, right-drag to pan and scroll to zoom in Perspective. Orthographic views support scroll
                  zoom. Edit transforms in the Command Panel. Keyed objects update at the current frame; Auto Key adds
                  animation to unkeyed objects.
                </p>
                <p className="muted">
                  Browser V1 · no native .max files, Arnold rendering, plugins or mesh sub-object editing. No Autodesk
                  code or assets are included.
                </p>
                <div className="dialog-actions">
                  <button className="primary" onClick={() => setModal(null)}>
                    <Check size={13} />
                    Continue editing
                  </button>
                </div>
              </>
            )}
          </section>
        </div>
      )}
    </div>
  )
}
