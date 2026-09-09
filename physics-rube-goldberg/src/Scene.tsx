import { useEffect, useRef } from 'react'
import { SCENE_H, SCENE_W } from './levels.ts'
import { drawScene, type RenderState } from './render.ts'

interface Props {
  /** Returns the latest render state; read every frame. */
  getState: () => RenderState
  onFrame: (now: number) => void
  canvasRef: React.RefObject<HTMLCanvasElement | null>
  className?: string
}

/**
 * Canvas that redraws the world every animation frame. All interaction is
 * handled by the parent through pointer events on the canvas element.
 */
export function Scene({ getState, onFrame, canvasRef, className }: Props) {
  const getStateRef = useRef(getState)
  const onFrameRef = useRef(onFrame)
  useEffect(() => {
    getStateRef.current = getState
    onFrameRef.current = onFrame
  }, [getState, onFrame])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    let raf = 0
    let dpr = 0

    const frame = (now: number) => {
      onFrameRef.current(now)
      const nextDpr = Math.min(window.devicePixelRatio || 1, 2)
      if (nextDpr !== dpr) {
        dpr = nextDpr
        canvas.width = SCENE_W * dpr
        canvas.height = SCENE_H * dpr
      }
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      drawScene(ctx, getStateRef.current())
      raf = requestAnimationFrame(frame)
    }
    raf = requestAnimationFrame(frame)
    return () => cancelAnimationFrame(raf)
  }, [canvasRef])

  return <canvas ref={canvasRef} className={className} width={SCENE_W} height={SCENE_H} />
}
