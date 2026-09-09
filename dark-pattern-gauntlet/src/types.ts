export interface ScreenProps {
  /** Call once the dark pattern on this screen has been defeated. */
  onDefeat: () => void
  /** Call whenever the user falls for a trap (fake close, decoy, wrong answer...). */
  onTrap: (label: string) => void
}

export interface PatternInfo {
  id: number
  name: string
  trick: string
}

export const PATTERNS: PatternInfo[] = [
  { id: 1, name: 'Fake close button', trick: 'The big × opens an upsell; the real exit is a tiny text link.' },
  { id: 2, name: 'Dodging button', trick: '"Continue" jumps away from the cursor twice before it stays put.' },
  { id: 3, name: 'Confirmshaming', trick: 'Guilt-trip copy; the real option is low-contrast grey text.' },
  { id: 4, name: 'Forced countdown', trick: 'Cancel is disabled until a 10-second timer runs out.' },
  { id: 5, name: 'Pre-checked opt-in', trick: '"Keep my subscription" is pre-checked and hidden below the fold.' },
  { id: 6, name: 'Mandatory survey', trick: 'Three required questions; a faint "skip" link hides at the bottom.' },
  { id: 7, name: 'Disguised advert', trick: 'The primary-looking button is a sponsored ad.' },
  { id: 8, name: 'Scroll-gated terms', trick: 'The checkbox stays disabled until the terms are scrolled to the end.' },
  { id: 9, name: 'Case trap', trick: 'Asks for CANCEL in uppercase but only lowercase passes; hint on hover.' },
  { id: 10, name: 'Look-alike buttons', trick: 'Six identical Cancel buttons; only one has the real aria-label.' },
]

export const TOTAL_STEPS = PATTERNS.length
