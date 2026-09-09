import type { PartType } from './parts.ts'

export const SCENE_W = 960
export const SCENE_H = 600
export const BALL_RADIUS = 13
export const BELL_RADIUS = 24

export interface Rect {
  x: number
  y: number
  w: number
  h: number
}

export interface Level {
  id: number
  name: string
  objective: string
  spawn: { x: number; y: number }
  bell: { x: number; y: number; mount: 'stand' | 'hang' }
  obstacles: Rect[]
  /** How many of each part the tray offers. */
  tray: Partial<Record<PartType, number>>
}

export const LEVELS: Level[] = [
  {
    id: 1,
    name: 'First Drop',
    objective:
      'The ball falls straight down and stops. Drop a ramp beneath the spawn and tilt it so the ball rolls right, all the way to the bell.',
    spawn: { x: 140, y: 60 },
    bell: { x: 870, y: 536, mount: 'stand' },
    obstacles: [
      { x: 0, y: 570, w: 960, h: 30 },
      { x: 0, y: 0, w: 20, h: 600 },
      { x: 940, y: 0, w: 20, h: 600 },
    ],
    tray: { ramp: 1 },
  },
  {
    id: 2,
    name: 'Mind the Gap',
    objective:
      'Two ledges, one pit. Build enough speed on the left ledge and launch the ball across the gap to the bell on the right.',
    spawn: { x: 110, y: 60 },
    bell: { x: 890, y: 466, mount: 'stand' },
    obstacles: [
      { x: 0, y: 330, w: 380, h: 24 },
      { x: 560, y: 500, w: 400, h: 24 },
      { x: 0, y: 580, w: 960, h: 20 },
      { x: 0, y: 0, w: 20, h: 600 },
      { x: 940, y: 0, w: 20, h: 600 },
    ],
    tray: { ramp: 2 },
  },
  {
    id: 3,
    name: 'Bounce House',
    objective:
      'The bell hangs high on the right. Give the ball some sideways speed, then bounce it off a trampoline so it flies up into the bell.',
    spawn: { x: 120, y: 60 },
    bell: { x: 700, y: 200, mount: 'hang' },
    obstacles: [
      { x: 0, y: 570, w: 960, h: 30 },
      { x: 0, y: 0, w: 20, h: 600 },
      { x: 940, y: 0, w: 20, h: 600 },
    ],
    tray: { ramp: 1, trampoline: 1 },
  },
  {
    id: 4,
    name: 'Wind Tunnel',
    objective:
      'The ball lands at the bottom of a shaft with no momentum. Use the fan to blow it along the floor and a ramp to climb the pedestal.',
    spawn: { x: 80, y: 60 },
    bell: { x: 890, y: 474, mount: 'stand' },
    obstacles: [
      { x: 0, y: 570, w: 960, h: 30 },
      { x: 0, y: 0, w: 20, h: 600 },
      { x: 140, y: 0, w: 20, h: 400 },
      { x: 820, y: 500, w: 140, h: 70 },
      { x: 940, y: 0, w: 20, h: 500 },
    ],
    tray: { fan: 1, ramp: 1, domino: 2 },
  },
  {
    id: 5,
    name: 'Grand Finale',
    objective:
      'Everything in the tray, one bell hanging high on the right past a pillar. Chain ramps, a seesaw, a trampoline and a fan however you like — just ring it.',
    spawn: { x: 90, y: 60 },
    bell: { x: 880, y: 320, mount: 'hang' },
    obstacles: [
      { x: 0, y: 250, w: 300, h: 20 },
      { x: 470, y: 400, w: 40, h: 200 },
      { x: 0, y: 580, w: 960, h: 20 },
      { x: 0, y: 0, w: 20, h: 600 },
      { x: 940, y: 0, w: 20, h: 600 },
    ],
    tray: { ramp: 2, seesaw: 1, trampoline: 1, fan: 1, domino: 3 },
  },
]
