import { useEffect, useRef } from 'react'
import { DIRECTION_VECTORS, GRID_SIZE } from '../game/engine'
import type { GameState, Point } from '../game/types'

const CELL = 28
const MARGIN = 14
const BOARD = GRID_SIZE * CELL
export const CANVAS_SIZE = BOARD + MARGIN * 2

function center(point: Point): Point {
  return { x: MARGIN + (point.x + 0.5) * CELL, y: MARGIN + (point.y + 0.5) * CELL }
}

function drawBoard(ctx: CanvasRenderingContext2D) {
  ctx.fillStyle = '#142119'
  ctx.fillRect(0, 0, CANVAS_SIZE, CANVAS_SIZE)
  for (let y = 0; y < GRID_SIZE; y++) {
    for (let x = 0; x < GRID_SIZE; x++) {
      ctx.fillStyle = (x + y) % 2 === 0 ? '#1b2b1e' : '#1d2e20'
      ctx.fillRect(MARGIN + x * CELL + 1, MARGIN + y * CELL + 1, CELL - 2, CELL - 2)
    }
  }
  ctx.strokeStyle = '#829b4b55'
  ctx.lineWidth = 1
  ctx.strokeRect(MARGIN - 1, MARGIN - 1, BOARD + 2, BOARD + 2)
  ctx.strokeStyle = '#b0cd72'
  ctx.lineWidth = 2
  const far = MARGIN + BOARD + 4
  const near = MARGIN - 4
  for (const [x, y, dx, dy] of [
    [near, near, 1, 1],
    [far, near, -1, 1],
    [far, far, -1, -1],
    [near, far, 1, -1],
  ]) {
    ctx.beginPath()
    ctx.moveTo(x + dx * 10, y)
    ctx.lineTo(x, y)
    ctx.lineTo(x, y + dy * 10)
    ctx.stroke()
  }
}

function drawApple(ctx: CanvasRenderingContext2D, apple: Point) {
  const { x, y } = center(apple)
  ctx.save()
  ctx.shadowColor = '#ff805888'
  ctx.shadowBlur = 17
  const skin = ctx.createRadialGradient(x - 4, y - 4, 1, x, y, 12)
  skin.addColorStop(0, '#ffbe98')
  skin.addColorStop(0.5, '#ff865f')
  skin.addColorStop(1, '#d44f35')
  ctx.fillStyle = skin
  ctx.beginPath()
  ctx.moveTo(x, y - 7)
  ctx.bezierCurveTo(x - 13, y - 15, x - 17, y + 8, x - 3, y + 11)
  ctx.quadraticCurveTo(x, y + 9, x + 3, y + 11)
  ctx.bezierCurveTo(x + 17, y + 8, x + 13, y - 15, x, y - 7)
  ctx.fill()
  ctx.shadowBlur = 0
  ctx.strokeStyle = '#dfa477'
  ctx.lineWidth = 2
  ctx.beginPath()
  ctx.moveTo(x, y - 7)
  ctx.lineTo(x + 1, y - 13)
  ctx.stroke()
  ctx.fillStyle = '#ceef80'
  ctx.beginPath()
  ctx.ellipse(x + 5, y - 11, 5, 2.5, -0.5, 0, Math.PI * 2)
  ctx.fill()
  ctx.fillStyle = '#ffe4cbbb'
  ctx.beginPath()
  ctx.ellipse(x - 6, y - 2, 2, 3.5, 0.4, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()
}

function drawSnake(
  ctx: CanvasRenderingContext2D,
  snake: Point[],
  direction: GameState['direction'],
) {
  const path = new Path2D()
  snake.forEach((point, index) => {
    const { x, y } = center(point)
    if (index === 0) path.moveTo(x, y)
    else path.lineTo(x, y)
  })
  ctx.save()
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
  ctx.shadowColor = '#050c07'
  ctx.shadowBlur = 5
  ctx.shadowOffsetY = 4
  ctx.strokeStyle = '#5c812f'
  ctx.lineWidth = CELL - 4
  ctx.stroke(path)
  ctx.shadowBlur = 0
  ctx.shadowOffsetY = 0
  const skin = ctx.createLinearGradient(0, MARGIN, BOARD, MARGIN + BOARD)
  skin.addColorStop(0, '#edffa6')
  skin.addColorStop(0.5, '#c6ec6b')
  skin.addColorStop(1, '#89b649')
  ctx.strokeStyle = skin
  ctx.lineWidth = CELL - 7
  ctx.stroke(path)
  ctx.strokeStyle = '#f5ffc747'
  ctx.lineWidth = 4
  ctx.translate(-3, -3)
  ctx.stroke(path)
  ctx.translate(3, 3)
  for (let i = 2; i < snake.length; i += 2) {
    const { x, y } = center(snake[i])
    ctx.fillStyle = '#5d862548'
    ctx.beginPath()
    ctx.arc(x, y, 2, 0, Math.PI * 2)
    ctx.fill()
  }
  const head = center(snake[0])
  ctx.translate(head.x, head.y)
  const vector = DIRECTION_VECTORS[direction]
  ctx.rotate(Math.atan2(vector.y, vector.x))
  ctx.fillStyle = '#def691'
  ctx.beginPath()
  ctx.roundRect(-13, -13, 27, 26, 10)
  ctx.fill()
  for (const side of [-1, 1]) {
    ctx.fillStyle = '#fbffda'
    ctx.beginPath()
    ctx.ellipse(5, side * 7, 5.5, 5, 0, 0, Math.PI * 2)
    ctx.fill()
    ctx.fillStyle = '#192c19'
    ctx.beginPath()
    ctx.arc(7, side * 7, 2.7, 0, Math.PI * 2)
    ctx.fill()
    ctx.fillStyle = 'white'
    ctx.fillRect(7, side * 7 - 1, 1.3, 1.3)
  }
  ctx.restore()
}

const ATTRACT_SNAKE: Point[] = [
  { x: 16, y: 3 },
  { x: 15, y: 3 },
  { x: 14, y: 3 },
  { x: 13, y: 3 },
  { x: 12, y: 3 },
  { x: 11, y: 3 },
  { x: 10, y: 3 },
  { x: 9, y: 3 },
  { x: 8, y: 3 },
  { x: 7, y: 3 },
  { x: 6, y: 3 },
  { x: 5, y: 3 },
  { x: 4, y: 3 },
  { x: 3, y: 3 },
  { x: 3, y: 4 },
  { x: 3, y: 5 },
  { x: 3, y: 6 },
  { x: 3, y: 7 },
  { x: 3, y: 8 },
  { x: 3, y: 9 },
  { x: 3, y: 10 },
  { x: 3, y: 11 },
  { x: 3, y: 12 },
  { x: 3, y: 13 },
  { x: 3, y: 14 },
  { x: 3, y: 15 },
  { x: 4, y: 15 },
  { x: 5, y: 15 },
  { x: 6, y: 15 },
  { x: 7, y: 15 },
  { x: 8, y: 15 },
  { x: 9, y: 15 },
  { x: 10, y: 15 },
  { x: 11, y: 15 },
  { x: 12, y: 15 },
  { x: 13, y: 15 },
]

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
    drawBoard(ctx)
    if (state.phase === 'ready') {
      ctx.globalAlpha = 0.65
      drawSnake(ctx, ATTRACT_SNAKE, 'right')
      drawApple(ctx, { x: 16, y: 14 })
      ctx.globalAlpha = 1
    } else {
      drawApple(ctx, state.apple)
      drawSnake(ctx, state.snake, state.direction)
    }
  }, [state])

  return (
    <canvas
      ref={canvasRef}
      className="game-canvas"
      aria-label="Snake game board"
      data-testid="game-canvas"
    />
  )
}
