import type { Level } from './board'

/** The browser test scenario documented in README.md, rendered in-app as a live checklist. */
export const SCENARIO: { level: Level; seed: number; minChords: number } = {
  level: 'intermediate',
  seed: 1234,
  minChords: 2,
}
