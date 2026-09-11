import type { Dir } from '../game/engine'

/*
 * All art is 16x16 pixel-art drawn with SVG rects, rendered with
 * crisp edges so it scales cleanly to whatever tile size the board uses.
 */

interface Px {
  x: number
  y: number
  w?: number
  h?: number
  c: string
}

function Pixels({ pixels, viewBox = '0 0 16 16', className }: { pixels: Px[]; viewBox?: string; className?: string }) {
  return (
    <svg viewBox={viewBox} className={className} shapeRendering="crispEdges" aria-hidden="true">
      {pixels.map((p, i) => (
        <rect key={i} x={p.x} y={p.y} width={p.w ?? 1} height={p.h ?? 1} fill={p.c} />
      ))}
    </svg>
  )
}

const MORTAR = '#2b4858'
const BRICK = '#557989'
const BRICK_HI = '#8eacb0'
const BRICK_LO = '#365d71'

function brickRow(y: number, offset: boolean): Px[] {
  const out: Px[] = []
  // Bricks are 8 wide and 3 tall, alternately offset by 4.
  const starts = offset ? [-4, 4, 12] : [0, 8]
  for (const s of starts) {
    const x0 = Math.max(0, s)
    const x1 = Math.min(16, s + 7)
    if (x1 <= x0) continue
    out.push({ x: x0, y, w: x1 - x0, h: 3, c: BRICK })
    out.push({ x: x0, y, w: x1 - x0, h: 1, c: BRICK_HI })
    out.push({ x: x0, y: y + 2, w: x1 - x0, h: 1, c: BRICK_LO })
  }
  return out
}

const WALL_PIXELS: Px[] = [
  { x: 0, y: 0, w: 16, h: 16, c: MORTAR },
  ...brickRow(0, false),
  ...brickRow(4, true),
  ...brickRow(8, false),
  ...brickRow(12, true),
]

export function WallTile() {
  return <Pixels pixels={WALL_PIXELS} className="sprite sprite-wall" />
}

const WOOD = '#eda84c'
const WOOD_HI = '#ffe0a0'
const WOOD_LO = '#ba762f'
const WOOD_EDGE = '#79502e'
const STEEL = '#fff4d4'
const STEEL_LO = '#abc3bf'

const CRATE_PIXELS: Px[] = [
  { x: 1, y: 1, w: 14, h: 14, c: WOOD },
  // frame
  { x: 1, y: 1, w: 14, h: 1, c: WOOD_EDGE },
  { x: 1, y: 14, w: 14, h: 1, c: WOOD_EDGE },
  { x: 1, y: 1, w: 1, h: 14, c: WOOD_EDGE },
  { x: 14, y: 1, w: 1, h: 14, c: WOOD_EDGE },
  { x: 2, y: 2, w: 12, h: 1, c: WOOD_HI },
  { x: 2, y: 2, w: 1, h: 12, c: WOOD_HI },
  { x: 2, y: 13, w: 12, h: 1, c: WOOD_LO },
  { x: 13, y: 2, w: 1, h: 12, c: WOOD_LO },
  // plank seams
  { x: 3, y: 5, w: 10, h: 1, c: WOOD_LO },
  { x: 3, y: 10, w: 10, h: 1, c: WOOD_LO },
  { x: 3, y: 6, w: 10, h: 1, c: WOOD_HI },
  { x: 3, y: 11, w: 10, h: 1, c: WOOD_HI },
  // diagonal brace
  ...Array.from({ length: 10 }, (_, i) => ({ x: 3 + i, y: 3 + i, c: WOOD_EDGE })),
  ...Array.from({ length: 10 }, (_, i) => ({ x: 12 - i, y: 3 + i, c: WOOD_EDGE })),
  // steel corner brackets
  { x: 2, y: 2, w: 3, h: 1, c: STEEL },
  { x: 2, y: 2, w: 1, h: 3, c: STEEL },
  { x: 11, y: 2, w: 3, h: 1, c: STEEL },
  { x: 13, y: 2, w: 1, h: 3, c: STEEL },
  { x: 2, y: 13, w: 3, h: 1, c: STEEL_LO },
  { x: 2, y: 11, w: 1, h: 3, c: STEEL_LO },
  { x: 11, y: 13, w: 3, h: 1, c: STEEL_LO },
  { x: 13, y: 11, w: 1, h: 3, c: STEEL_LO },
  // rivets
  { x: 3, y: 3, c: STEEL_LO },
  { x: 12, y: 3, c: STEEL_LO },
  { x: 3, y: 12, c: STEEL },
  { x: 12, y: 12, c: STEEL },
]

export function CrateSprite() {
  return <Pixels pixels={CRATE_PIXELS} className="sprite sprite-crate" />
}

const HAT = '#ffb020'
const HAT_LO = '#d18a0c'
const SKIN = '#f3c48e'
const SKIN_LO = '#d9a06a'
const EYE = '#1d1a24'
const VEST = '#ee6345'
const VEST_LO = '#b9442c'
const STRIPE = '#f7f7f7'
const PANTS = '#2e6077'
const BOOT = '#3a2a1e'
const GLOVE = '#ffd166'

function workerPixels(facing: Dir): Px[] {
  const back = facing === 'up'
  const px: Px[] = [
    // hard hat
    { x: 5, y: 1, w: 6, h: 1, c: HAT },
    { x: 4, y: 2, w: 8, h: 2, c: HAT },
    { x: 3, y: 4, w: 10, h: 1, c: HAT_LO },
    // head
    { x: 5, y: 5, w: 6, h: 3, c: back ? SKIN_LO : SKIN },
    // body / vest
    { x: 4, y: 8, w: 8, h: 4, c: VEST },
    { x: 4, y: 9, w: 8, h: 1, c: STRIPE },
    { x: 4, y: 11, w: 8, h: 1, c: VEST_LO },
    // arms & gloves
    { x: 3, y: 8, w: 1, h: 2, c: SKIN },
    { x: 12, y: 8, w: 1, h: 2, c: SKIN },
    { x: 3, y: 10, c: GLOVE },
    { x: 12, y: 10, c: GLOVE },
    // legs & boots
    { x: 5, y: 12, w: 2, h: 2, c: PANTS },
    { x: 9, y: 12, w: 2, h: 2, c: PANTS },
    { x: 5, y: 14, w: 2, h: 1, c: BOOT },
    { x: 9, y: 14, w: 2, h: 1, c: BOOT },
  ]
  if (!back) {
    if (facing === 'down') {
      px.push({ x: 6, y: 6, c: EYE }, { x: 9, y: 6, c: EYE })
    } else {
      // Side view: both eyes shifted toward the facing edge (sprite is mirrored for left).
      px.push({ x: 8, y: 6, c: EYE }, { x: 10, y: 6, c: EYE })
    }
  } else {
    // Hair peeking below the hat from behind.
    px.push({ x: 5, y: 5, w: 6, h: 1, c: '#4a2f1d' })
  }
  return px
}

const WORKER_BY_DIR: Record<Dir, Px[]> = {
  up: workerPixels('up'),
  down: workerPixels('down'),
  left: workerPixels('left'),
  right: workerPixels('right'),
}

export function WorkerSprite({ facing }: { facing: Dir }) {
  return <Pixels pixels={WORKER_BY_DIR[facing]} className={`sprite sprite-worker facing-${facing}`} />
}
