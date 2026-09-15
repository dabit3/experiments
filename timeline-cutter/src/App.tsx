import { useCallback, useEffect, useState } from 'react'
import { FPS, type Project, type Selection, type Tool } from './types'
import { useHistory } from './hooks/useHistory'
import { usePlayback } from './hooks/usePlayback'
import { addTitle, appendClip, deleteTitle, rippleDelete, sequenceDuration, splitAt, updateTitle } from './lib/timeline'
import { buildEdl, downloadText, edlToCsv, edlToJson } from './lib/edl'
import { Header } from './components/Header'
import { MediaBin } from './components/MediaBin'
import { Preview } from './components/Preview'
import { Inspector } from './components/Inspector'
import { Timeline, ZOOM_MAX, ZOOM_MIN } from './components/Timeline'
import { clamp } from './lib/time'

const EMPTY: Project = { video: [], titles: [] }

export default function App() {
  const history = useHistory<Project>(EMPTY)
  const project = history.present
  const duration = sequenceDuration(project)
  const playback = usePlayback(duration)
  const [rawSelection, setSelection] = useState<Selection>(null)
  // Drop the selection if the clip disappears (undo, delete).
  const selection: Selection =
    rawSelection &&
    (rawSelection.kind === 'video'
      ? project.video.some((c) => c.id === rawSelection.id)
      : project.titles.some((t) => t.id === rawSelection.id))
      ? rawSelection
      : null
  const [tool, setTool] = useState<Tool>('select')
  const [snap, setSnap] = useState(true)
  const [pxPerSec, setPxPerSec] = useState(48)
  const [toast, setToast] = useState<string | null>(null)

  const notify = useCallback((msg: string) => {
    setToast(msg)
    window.setTimeout(() => setToast((t) => (t === msg ? null : t)), 2200)
  }, [])

  const scrub = useCallback(
    (t: number) => {
      playback.pause()
      playback.setTime(Math.round(t * FPS) / FPS)
    },
    [playback],
  )

  const split = useCallback(
    (time: number) => {
      const before = project
      const after = splitAt(before, time)
      if (after === before) return
      history.commit(after)
      notify(`Split at ${time.toFixed(2)}s`)
    },
    [project, history, notify],
  )

  const ripple = useCallback(() => {
    if (!selection) return
    if (selection.kind === 'video') {
      const hit = project.video.find((c) => c.id === selection.id)
      if (!hit) return
      history.commit(rippleDelete(project, selection.id))
      notify(`Ripple deleted ${(hit.out - hit.in).toFixed(2)}s`)
    } else {
      history.commit(deleteTitle(project, selection.id))
      notify('Title removed')
    }
    setSelection(null)
  }, [selection, project, history, notify])

  const addTitleAtPlayhead = useCallback(() => {
    const next = addTitle(project, playback.time, 'Timeline Cutter')
    history.commit(next)
    const created = next.titles[next.titles.length - 1]
    setSelection({ kind: 'title', id: created.id })
    notify('Title added on T1')
  }, [project, playback.time, history, notify])

  const add = useCallback(
    (mediaId: string) => {
      history.commit(appendClip(project, mediaId))
    },
    [project, history],
  )

  const exportEdl = useCallback(
    (format: 'json' | 'csv') => {
      const edl = buildEdl(project)
      if (format === 'json') downloadText('timeline-cutter-edl.json', edlToJson(edl), 'application/json')
      else downloadText('timeline-cutter-edl.csv', edlToCsv(edl), 'text/csv')
      notify(`Exported ${edl.events.length} events as ${format.toUpperCase()}`)
    },
    [project, notify],
  )

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) return
      const key = e.key.toLowerCase()
      if ((e.ctrlKey || e.metaKey) && key === 'z') {
        e.preventDefault()
        if (e.shiftKey) history.redo()
        else history.undo()
        return
      }
      if ((e.ctrlKey || e.metaKey) && key === 'y') {
        e.preventDefault()
        history.redo()
        return
      }
      if (e.ctrlKey || e.metaKey || e.altKey) return
      switch (key) {
        case ' ':
          e.preventDefault()
          playback.togglePlay()
          break
        case 'j':
          playback.shuttle(-1)
          break
        case 'k':
          playback.pause()
          break
        case 'l':
          playback.shuttle(1)
          break
        case 's':
          split(playback.time)
          break
        case 't':
          addTitleAtPlayhead()
          break
        case 'v':
          setTool('select')
          break
        case 'b':
          setTool('razor')
          break
        case 'n':
          setSnap((s) => !s)
          break
        case 'delete':
        case 'backspace':
          e.preventDefault()
          ripple()
          break
        case 'home':
          scrub(0)
          break
        case 'end':
          scrub(duration)
          break
        case 'arrowleft':
          e.preventDefault()
          scrub(playback.time - (e.shiftKey ? 1 : 1 / FPS))
          break
        case 'arrowright':
          e.preventDefault()
          scrub(playback.time + (e.shiftKey ? 1 : 1 / FPS))
          break
        case '=':
        case '+':
          setPxPerSec((z) => clamp(z * 1.4, ZOOM_MIN, ZOOM_MAX))
          break
        case '-':
          setPxPerSec((z) => clamp(z / 1.4, ZOOM_MIN, ZOOM_MAX))
          break
        case 'escape':
          setSelection(null)
          break
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [history, playback, split, ripple, addTitleAtPlayhead, scrub, duration])

  const usage: Record<string, number> = {}
  for (const c of project.video) usage[c.mediaId] = (usage[c.mediaId] ?? 0) + 1

  return (
    <div className="app">
      <Header
        canUndo={history.canUndo}
        canRedo={history.canRedo}
        onUndo={history.undo}
        onRedo={history.redo}
        onExport={exportEdl}
      />
      <main className="workspace">
        <MediaBin onAdd={add} usage={usage} />
        <Preview
          project={project}
          time={playback.time}
          duration={duration}
          speed={playback.speed}
          isPlaying={playback.isPlaying}
          onTogglePlay={playback.togglePlay}
          onShuttle={playback.shuttle}
          onPause={playback.pause}
          onGoStart={() => scrub(0)}
          onGoEnd={() => scrub(duration)}
          onStep={(dir) => scrub(playback.time + dir / FPS)}
        />
        <Inspector
          project={project}
          selection={selection}
          playhead={playback.time}
          onSplit={() => split(playback.time)}
          onRippleDelete={ripple}
          onAddTitle={addTitleAtPlayhead}
          onTitleText={(id, text) => history.commit(updateTitle(project, id, { text }))}
        />
      </main>
      <Timeline
        project={project}
        setProject={history.set}
        commitFrom={history.commitFrom}
        commit={history.commit}
        playhead={playback.time}
        setPlayhead={scrub}
        selection={selection}
        setSelection={setSelection}
        tool={tool}
        setTool={setTool}
        snap={snap}
        setSnap={setSnap}
        pxPerSec={pxPerSec}
        setPxPerSec={setPxPerSec}
        onSplitAt={split}
      />
      {toast && (
        <div className="toast" role="status">
          {toast}
        </div>
      )}
    </div>
  )
}
