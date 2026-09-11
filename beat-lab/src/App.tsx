import { useCallback, useEffect, useMemo, useState } from 'react'
import './App.css'
import { Logo } from './components/Logo'
import { PianoRoll } from './components/PianoRoll'
import { PatternOverview } from './components/PatternOverview'
import { ReferencePanel } from './components/ReferencePanel'
import { StepGrid } from './components/StepGrid'
import { ProjectActions, Transport } from './components/Transport'
import { downloadSong, parseSong } from './lib/patternIO'
import { Sequencer, type Position } from './lib/sequencer'
import {
  BOOM_BAP,
  compareDrums,
  referenceToPattern,
  type StepDiff,
} from './reference'
import {
  TRACKS,
  VELOCITY_GAIN,
  emptyPattern,
  emptySong,
  type Pattern,
  type PatternId,
  type Song,
  type Velocity,
} from './types'

type Tab = 'drums' | 'bass'

interface Toast {
  id: number
  kind: 'ok' | 'error'
  text: string
}

const REFERENCE_DRUMS = referenceToPattern(BOOM_BAP).drums

export default function App() {
  const [song, setSong] = useState<Song>(emptySong)
  const [editing, setEditing] = useState<PatternId>('A')
  const [muted, setMuted] = useState<boolean[]>(() => TRACKS.map(() => false))
  const [soloed, setSoloed] = useState<boolean[]>(() => TRACKS.map(() => false))
  const [tab, setTab] = useState<Tab>('drums')
  const [playing, setPlaying] = useState(false)
  const [position, setPosition] = useState<Position | null>(null)
  const [compareResult, setCompareResult] = useState<StepDiff[] | null>(null)
  const [toast, setToast] = useState<Toast | null>(null)

  const [seq] = useState(() => new Sequencer(setPosition))
  useEffect(() => {
    seq.update({
      bpm: song.bpm,
      swing: song.swing,
      chain: song.chain,
      editing,
      patterns: song.patterns,
      muted,
      soloed,
    })
  }, [seq, song, editing, muted, soloed])

  useEffect(() => () => seq.stop(), [seq])

  const notify = useCallback((kind: Toast['kind'], text: string) => {
    setToast({ id: Date.now(), kind, text })
  }, [])

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(null), 3600)
    return () => clearTimeout(t)
  }, [toast])

  const togglePlay = useCallback(() => {
    if (seq.playing) {
      seq.stop()
      setPlaying(false)
    } else {
      void seq.start()
      setPlaying(true)
    }
  }, [seq])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      const tag = target?.tagName
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'BUTTON') return
      if (e.code === 'Space') {
        e.preventDefault()
        togglePlay()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [togglePlay])

  const pattern = song.patterns[editing]

  const updatePattern = useCallback(
    (fn: (p: Pattern) => Pattern) => {
      setSong((s) => ({
        ...s,
        patterns: { ...s.patterns, [editing]: fn(s.patterns[editing]) },
      }))
      setCompareResult(null)
    },
    [editing],
  )

  const setDrum = useCallback(
    (track: number, step: number, next: (v: Velocity) => Velocity) => {
      const v = next(pattern.drums[track][step])
      updatePattern((p) => {
        const drums = p.drums.map((row) => row.slice())
        drums[track][step] = v
        return { ...p, drums }
      })
      if (v > 0 && !seq.playing) void seq.preview(track, VELOCITY_GAIN[v])
    },
    [updatePattern, pattern, seq],
  )

  const onToggle = (t: number, s: number) =>
    setDrum(t, s, (v) => (v > 0 ? 0 : 3))
  const onCycleVelocity = (t: number, s: number) =>
    setDrum(t, s, (v) => (v === 0 ? 1 : v === 3 ? 2 : v === 2 ? 1 : 3))

  const onMute = (t: number) =>
    setMuted((m) => m.map((x, i) => (i === t ? !x : x)))
  const onSolo = (t: number) =>
    setSoloed((m) => m.map((x, i) => (i === t ? !x : x)))

  const onBassToggle = (step: number, midi: number) => {
    const turningOn = pattern.bass[step] !== midi
    updatePattern((p) => {
      const bass = p.bass.slice()
      bass[step] = bass[step] === midi ? null : midi
      return { ...p, bass }
    })
    if (turningOn && !seq.playing) void seq.previewBass(midi)
  }

  const onCompare = () => {
    const diffs = compareDrums(pattern.drums, REFERENCE_DRUMS)
    setCompareResult(diffs)
  }

  const onSave = () => {
    downloadSong(song)
    notify('ok', 'Pattern saved as beat-lab-pattern.json')
  }

  const onLoadFile = async (file: File) => {
    const text = await file.text()
    const res = parseSong(text)
    if (!res.ok) {
      notify('error', `Could not load: ${res.error}`)
      return
    }
    setSong(res.song)
    setCompareResult(null)
    notify('ok', `Loaded ${file.name}`)
  }

  const onClear = () => {
    updatePattern(() => emptyPattern())
    notify('ok', `Cleared pattern ${editing}`)
  }

  const currentStep =
    position && position.pattern === editing ? position.step : null
  const activeNotes = useMemo(
    () => pattern.bass.filter((n) => n !== null).length,
    [pattern.bass],
  )
  const activeHits = useMemo(
    () =>
      pattern.drums.reduce(
        (acc, row) => acc + row.filter((v) => v > 0).length,
        0,
      ),
    [pattern.drums],
  )

  return (
    <div className="app">
      <header className="masthead">
        <div className="brand">
          <Logo size={34} />
          <h1>Beat Lab</h1>
          <span className="brand-sep" aria-hidden="true" />
          <p>Rhythm & synthesis</p>
        </div>
        <ProjectActions
          onSave={onSave}
          onLoadFile={(f) => void onLoadFile(f)}
        />
      </header>

      <div className="session-heading">
        <div>
          <p className="session-label">Your workspace</p>
          <h2>
            Untitled session<span className="session-dot">.</span>
          </h2>
        </div>
        <div className="session-details">
          <span>4/4 time</span>
          <span>1 bar per pattern</span>
          <span>1/16 resolution</span>
        </div>
      </div>

      <Transport
        playing={playing}
        bpm={song.bpm}
        swing={song.swing}
        chain={song.chain}
        nowPlaying={playing && position ? position.pattern : null}
        currentStep={playing && position ? position.step : null}
        onTogglePlay={togglePlay}
        onBpm={(bpm) => setSong((s) => ({ ...s, bpm }))}
        onSwing={(swing) => setSong((s) => ({ ...s, swing }))}
        onChain={(chain) => setSong((s) => ({ ...s, chain }))}
      />

      <main className="workspace">
        <div className="instrument">
          <section className="editor">
            <div className="editor-heading">
              <div className="tabs" role="tablist" aria-label="Editor">
                <button
                  type="button"
                  role="tab"
                  aria-selected={tab === 'drums'}
                  id="drums-tab"
                  aria-controls="drums-panel"
                  className={tab === 'drums' ? 'is-active' : ''}
                  onClick={() => setTab('drums')}
                >
                  <svg viewBox="0 0 20 20" aria-hidden="true">
                    <path d="M3 3h5v5H3zm9 0h5v5h-5zM3 12h5v5H3zm9 0h5v5h-5z" />
                  </svg>
                  Drums <span className="tab-count">{activeHits}</span>
                </button>
                <button
                  type="button"
                  role="tab"
                  aria-selected={tab === 'bass'}
                  id="bass-tab"
                  aria-controls="bass-panel"
                  className={tab === 'bass' ? 'is-active' : ''}
                  onClick={() => setTab('bass')}
                >
                  <svg viewBox="0 0 20 20" aria-hidden="true">
                    <path d="M3 3h14v14H3zM7 3v14m6-14v14M6 3h2v7H6zm6 0h2v7h-2z" />
                  </svg>
                  Bass <span className="tab-count">{activeNotes}</span>
                </button>
              </div>
              <div className="editor-actions">
                <span className="pattern-badge">Pattern {editing}</span>
                <span className="editor-divider" />
                <button
                  type="button"
                  className="clear-button"
                  onClick={onClear}
                >
                  <svg viewBox="0 0 20 20" aria-hidden="true">
                    <path d="M4 6h12M8 3h4M6 6l1 11h6l1-11M9 9v5m2-5v5" />
                  </svg>
                  Clear
                </button>
              </div>
            </div>

            <div
              className={`score-viewport ${tab === 'bass' ? 'is-piano' : ''}`}
              id={`${tab}-panel`}
              role="tabpanel"
              aria-labelledby={`${tab}-tab`}
              tabIndex={0}
            >
              {tab === 'drums' ? (
                <StepGrid
                  drums={pattern.drums}
                  muted={muted}
                  soloed={soloed}
                  currentStep={currentStep}
                  onToggle={onToggle}
                  onCycleVelocity={onCycleVelocity}
                  onMute={onMute}
                  onSolo={onSolo}
                />
              ) : (
                <PianoRoll
                  bass={pattern.bass}
                  currentStep={currentStep}
                  onToggle={onBassToggle}
                />
              )}
            </div>
            <div className="editor-footer">
              <span className="editor-help">
                {tab === 'drums'
                  ? activeHits
                    ? 'Click to toggle · right-click for velocity'
                    : 'Click a step to start your groove'
                  : 'Click to place a note · one note per step'}
              </span>
              <span className="editor-spec">
                {tab === 'drums' ? '8 voices / 16 steps' : 'C2—C4 / 16 steps'}
              </span>
            </div>
          </section>

          <PatternOverview
            patterns={song.patterns}
            editing={editing}
            nowPlaying={playing && position ? position.pattern : null}
            onSelect={(id) => {
              setEditing(id)
              setCompareResult(null)
            }}
          />
        </div>
        <ReferencePanel
          reference={BOOM_BAP}
          referenceDrums={REFERENCE_DRUMS}
          result={compareResult}
          onCompare={onCompare}
        />
      </main>

      <footer className="statusbar">
        <span>
          <i
            className={`status-led ${playing ? 'is-on' : ''}`}
            aria-hidden="true"
          />
          {playing
            ? `Playing pattern ${position?.pattern ?? editing}`
            : 'Stopped'}
        </span>
        <span className="mono">
          {song.bpm} BPM · {song.swing}% swing · {activeHits} hits ·{' '}
          {activeNotes} notes
        </span>
        <span className="status-shortcut">
          <kbd>space</kbd> play / stop <span className="status-sep">/</span>{' '}
          Synthesized with Web Audio
        </span>
      </footer>

      {toast && (
        <div key={toast.id} className={`toast is-${toast.kind}`} role="status">
          {toast.text}
        </div>
      )}
    </div>
  )
}
