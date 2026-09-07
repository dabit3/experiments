import { useEffect, useRef } from 'react'
import { DIRECTION_VECTORS, GRID_SIZE } from '../game/engine'
import type { GameState } from '../game/types'

const CELL = 28
const MARGIN = 22
const BOARD = GRID_SIZE * CELL
export const CANVAS_SIZE = BOARD + MARGIN * 2

const COLORS = {
  board: '#07120b',
  grid: 'rgba(57, 255, 20, 0.08)',
  border: '#39ff14',
  label: 'rgba(57, 255, 20, 0.55)',
  head: '#d9ffd0',
  eye: '#07120b',
  apple: '#ff3366',
  appleGlow: 'rgba(255, 51, 102, 0.55)',
  leaf: '#39ff14',
}

function cellRect(x: number, y: number) {
  return { px: MARGIN + x * CELL, py: MARGIN + y * CELL }
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath()
  ctx.roundRect(x, y, w, h, r)
  ctx.fill()
}

function drawBoard(ctx: CanvasRenderingContext2D) {
  ctx.fillStyle = COLORS.board
  ctx.fillRect(MARGIN, MARGIN, BOARD, BOARD)

  ctx.strokeStyle = COLORS.grid
  ctx.lineWidth = 1
  for (let i = 1; i < GRID_SIZE; i++) {
    const offset = MARGIN + i * CELL + 0.5
    ctx.beginPath()
    ctx.moveTo(offset, MARGIN)
    ctx.lineTo(offset, MARGIN + BOARD)
    ctx.moveTo(MARGIN, offset)
    ctx.lineTo(MARGIN + BOARD, offset)
    ctx.stroke()
  }

  ctx.font = '9px "Press Start 2P", monospace'
  ctx.fillStyle = COLORS.label
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  for (let i = 0; i < GRID_SIZE; i++) {
    const center = MARGIN + i * CELL + CELL / 2
    ctx.fillText(String(i), center, MARGIN / 2)
    ctx.fillText(String(i), MARGIN / 2, center)
  }

  ctx.strokeStyle = COLORS.border
  ctx.lineWidth = 2
  ctx.shadowColor = COLORS.border
  ctx.shadowBlur = 12
  ctx.strokeRect(MARGIN, MARGIN, BOARD, BOARD)
  ctx.shadowBlur = 0
}

function drawApple(ctx: CanvasRenderingContext2D, x: number, y: number) {
  const { px, py } = cellRect(x, y)
  const cx = px + CELL / 2
  const cy = py + CELL / 2 + 1
  ctx.shadowColor = COLORS.appleGlow
  ctx.shadowBlur = 16
  ctx.fillStyle = COLORS.apple
  ctx.beginPath()
  ctx.arc(cx, cy, CELL * 0.36, 0, Math.PI * 2)
  ctx.fill()
  ctx.shadowBlur = 0
  ctx.fillStyle = COLORS.leaf
  ctx.beginPath()
  ctx.ellipse(cx + 3, cy - CELL * 0.4, 5, 2.5, -Math.PI / 5, 0, Math.PI * 2)
  ctx.fill()
}

function drawSnake(ctx: CanvasRenderingContext2D, state: GameState) {
  const { snake, direction } = state
  const length = snake.length
  const pad = 2

  for (let i = length - 1; i > 0; i--) {
    const { px, py } = cellRect(snake[i].x, snake[i].y)
    const fade = 1 - (i / length) * 0.65
    ctx.fillStyle = `hsl(110 100% ${28 + fade * 24}%)`
    roundRect(ctx, px + pad, py + pad, CELL - pad * 2, CELL - pad * 2, 6)
  }

  const head = snake[0]
  const { px, py } = cellRect(head.x, head.y)
  ctx.shadowColor = COLORS.border
  ctx.shadowBlur = 14
  ctx.fillStyle = COLORS.head
  roundRect(ctx, px + 1, py + 1, CELL - 2, CELL - 2, 8)
  ctx.shadowBlur = 0

  const v = DIRECTION_VECTORS[direction]
  const cx = px + CELL / 2 + v.x * 5
  const cy = py + CELL / 2 + v.y * 5
  const side = { x: -v.y, y: v.x }
  ctx.fillStyle = COLORS.eye
  for (const s of [-1, 1]) {
    ctx.beginPath()
    ctx.arc(cx + side.x * 5 * s, cy + side.y * 5 * s, 2.6, 0, Math.PI * 2)
    ctx.fill()
  }
}

export function GameCanvas({ state }: { state: GameState }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const dpr = window.devicePixelRatio || 1
    canvas.width = CANVAS_SIZE * dpr
    canvas.height = CANVAS_SIZE * dpr
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.scale(dpr, dpr)
    ctx.clearRect(0, 0, CANVAS_SIZE, CANVAS_SIZE)
    drawBoard(ctx)
    drawApple(ctx, state.apple.x, state.apple.y)
    drawSnake(ctx, state)
  }, [state])

  return (
    <canvas
      ref={canvasRef}
      className="game-canvas"
      style={{ width: CANVAS_SIZE, height: CANVAS_SIZE }}
      aria-label="Snake game board"
      data-testid="game-canvas"
    />
  )
}
