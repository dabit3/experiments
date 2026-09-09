import { useCallback, useEffect, useRef, useState } from 'react'
import { TASKS } from './tasks'
import { useMouseGuard } from './hooks/useMouseGuard'
import { useKeyLog } from './hooks/useKeyLog'
import { Header } from './components/Header'
import { Checklist } from './components/Checklist'
import { KeyHud } from './components/KeyHud'
import { Toast } from './components/Toast'
import { IntroScreen } from './components/IntroScreen'
import { TaskCard } from './components/TaskCard'
import { SummaryScreen } from './components/SummaryScreen'
import './App.css'

export type Phase = 'intro' | 'running' | 'done'

export interface TaskResult {
  ms: number
  keys: number
}

export default function App() {
  const [phase, setPhase] = useState<Phase>('intro')
  const [current, setCurrent] = useState(0)
  const [results, setResults] = useState<TaskResult[]>([])
  const [startedAt, setStartedAt] = useState(0)
  const [finishedAt, setFinishedAt] = useState(0)
  const [now, setNow] = useState(0)
  const taskStartRef = useRef(0)
  const taskKeysRef = useRef(0)
  const phaseRef = useRef<Phase>('intro')

  useEffect(() => {
    phaseRef.current = phase
  }, [phase])

  const mouse = useMouseGuard()
  const keys = useKeyLog(
    useCallback(() => {
      if (phaseRef.current === 'running') taskKeysRef.current += 1
    }, []),
  )

  useEffect(() => {
    if (phase !== 'running') return
    const id = window.setInterval(() => setNow(performance.now()), 100)
    return () => window.clearInterval(id)
  }, [phase])

  const start = () => {
    const t = performance.now()
    taskStartRef.current = t
    taskKeysRef.current = 0
    setStartedAt(t)
    setNow(t)
    setFinishedAt(0)
    setResults([])
    setCurrent(0)
    mouse.reset()
    keys.reset()
    setPhase('running')
  }

  const completeTask = useCallback(() => {
    const t = performance.now()
    const result: TaskResult = { ms: t - taskStartRef.current, keys: taskKeysRef.current }
    setResults((r) => [...r, result])
    taskStartRef.current = t
    taskKeysRef.current = 0
    if (current + 1 >= TASKS.length) {
      setFinishedAt(t)
      setPhase('done')
    } else {
      setCurrent(current + 1)
    }
  }, [current])

  const elapsed = phase === 'running' ? now - startedAt : phase === 'done' ? finishedAt - startedAt : 0
  const doneCount = phase === 'done' ? TASKS.length : phase === 'running' ? current : 0

  return (
    <div className="app">
      <Header phase={phase} elapsed={elapsed} violations={mouse.violations} doneCount={doneCount} />
      <div className="app-body">
        <Checklist phase={phase} current={current} results={results} />
        <main className="stage">
          {phase === 'intro' && <IntroScreen onStart={start} violations={mouse.violations} />}
          {phase === 'running' && (
            <TaskCard key={current} task={TASKS[current]} index={current} onComplete={completeTask} />
          )}
          {phase === 'done' && (
            <SummaryScreen
              elapsed={elapsed}
              violations={mouse.violations}
              results={results}
              onRestart={() => setPhase('intro')}
            />
          )}
        </main>
      </div>
      <KeyHud recent={keys.recent} total={keys.total} />
      <Toast visible={mouse.toastVisible} toastKey={mouse.toastKey} />
    </div>
  )
}
