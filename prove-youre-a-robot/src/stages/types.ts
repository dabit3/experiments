export interface StageProps {
  /** Per-stage deterministic seed. */
  seed: number
  /** Whether the stage is locked (already passed, awaiting Continue). */
  locked: boolean
  onPass: () => void
  onFail: (reason: string) => void
}

export interface StageMeta {
  id: string
  label: string
  title: string
  instruction: string
}

export const STAGES: readonly StageMeta[] = [
  {
    id: 'slide',
    label: 'Slide',
    title: 'Slide the piece into the notch',
    instruction: 'Drag the slider until the cut-out piece sits exactly in its notch. Tolerance: ±4 px.',
  },
  {
    id: 'rotate',
    label: 'Rotate',
    title: 'Rotate the image until it is upright',
    instruction: 'Drag the knob around the dial. Release when the horizon is level and the robot stands up. Tolerance: ±5°.',
  },
  {
    id: 'select',
    label: 'Select',
    title: 'Select all tiles containing a traffic cone',
    instruction: 'Click every tile that shows an orange traffic cone, then press Verify. Barrels are not cones.',
  },
  {
    id: 'jigsaw',
    label: 'Jigsaw',
    title: 'Drag the jigsaw piece into its hole',
    instruction: 'Pick up the piece from the tray and drop it exactly into the missing spot. Tolerance: ±6 px.',
  },
  {
    id: 'trace',
    label: 'Trace',
    title: 'Trace the path without leaving the corridor',
    instruction: 'Press on START, follow the corridor with the button held down, and release on END.',
  },
]

export const STAGE_TOLERANCE = { slidePx: 4, rotateDeg: 5, jigsawPx: 6, corridorHalfWidth: 22 } as const
