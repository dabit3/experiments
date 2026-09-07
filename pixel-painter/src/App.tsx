import { useCallback, useEffect, useRef, useState } from 'react'
import { PaintCanvas } from './components/PaintCanvas'
import { Toolbar } from './components/Toolbar'
import { useHistory } from './hooks/useHistory'
import {
  CANVAS_BACKGROUND,
  CANVAS_HEIGHT,
  CANVAS_WIDTH,
  MAX_BRUSH_SIZE,
  MIN_BRUSH_SIZE,
  TOOLS,
  type Point,
  type Tool,
} from './types'
import './App.css'

export default function App() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [tool, setTool] = useState<Tool>('brush')
  const [color, setColor] = useState('#1e88e5')
  const [size, setSize] = useState(8)
  const [fillShape, setFillShape] = useState(false)
  const coordsRef = useRef<HTMLSpanElement>(null)
  const { push, undo: popUndo, redo: popRedo, canUndo, canRedo } = useHistory()

  const snapshot = useCallback((): ImageData | null => {
    const ctx = canvasRef.current?.getContext('2d')
    return ctx ? ctx.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT) : null
  }, [])

  const recordHistory = useCallback(() => {
    const current = snapshot()
    if (current) push(current)
  }, [push, snapshot])

  const undo = useCallback(() => {
    const ctx = canvasRef.current?.getContext('2d')
    const current = snapshot()
    if (!ctx || !current) return
    const previous = popUndo(current)
    if (previous) ctx.putImageData(previous, 0, 0)
  }, [popUndo, snapshot])

  const redo = useCallback(() => {
    const ctx = canvasRef.current?.getContext('2d')
    const current = snapshot()
    if (!ctx || !current) return
    const next = popRedo(current)
    if (next) ctx.putImageData(next, 0, 0)
  }, [popRedo, snapshot])

  const clear = useCallback(() => {
    const ctx = canvasRef.current?.getContext('2d')
    if (!ctx) return
    recordHistory()
    ctx.fillStyle = CANVAS_BACKGROUND
    ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)
  }, [recordHistory])

  const download = useCallback(() => {
    canvasRef.current?.toBlob((blob) => {
      if (!blob) return
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = 'pixel-painter.png'
      link.click()
      URL.revokeObjectURL(url)
    }, 'image/png')
  }, [])

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      if (target && ['INPUT', 'TEXTAREA'].includes(target.tagName)) return

      const key = e.key.toLowerCase()
      if (e.ctrlKey || e.metaKey) {
        if (key === 'z' && e.shiftKey) {
          e.preventDefault()
          redo()
        } else if (key === 'z') {
          e.preventDefault()
          undo()
        } else if (key === 'y') {
          e.preventDefault()
          redo()
        }
        return
      }

      const hotkeyTool = TOOLS.find((t) => t.hotkey.toLowerCase() === key)
      if (hotkeyTool) setTool(hotkeyTool.id)
      else if (key === '[') setSize((s) => Math.max(MIN_BRUSH_SIZE, s - 2))
      else if (key === ']') setSize((s) => Math.min(MAX_BRUSH_SIZE, s + 2))
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [undo, redo])

  const showPointer = useCallback((point: Point | null) => {
    if (coordsRef.current) {
      coordsRef.current.textContent = point
        ? `${Math.round(point.x)}, ${Math.round(point.y)}`
        : '—'
    }
  }, [])

  const toolLabel = TOOLS.find((t) => t.id === tool)?.label ?? tool

  return (
    <div className="app">
      <Toolbar
        tool={tool}
        color={color}
        size={size}
        fillShape={fillShape}
        canUndo={canUndo}
        canRedo={canRedo}
        onToolChange={setTool}
        onColorChange={setColor}
        onSizeChange={setSize}
        onFillShapeChange={setFillShape}
        onUndo={undo}
        onRedo={redo}
        onClear={clear}
        onDownload={download}
      />
      <main className="workspace">
        <PaintCanvas
          canvasRef={canvasRef}
          tool={tool}
          color={color}
          size={size}
          fillShape={fillShape}
          onBeforeChange={recordHistory}
          onPointerPosition={showPointer}
        />
        <div className="status-bar">
          <span>
            <strong>{toolLabel}</strong> · {size}px ·{' '}
            <span className="status-swatch" style={{ background: color }} /> {color.toUpperCase()}
          </span>
          <span>
            <span ref={coordsRef}>—</span> · {CANVAS_WIDTH}×{CANVAS_HEIGHT}
          </span>
        </div>
      </main>
    </div>
  )
}
