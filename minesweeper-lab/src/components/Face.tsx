import type { Status } from '../hooks/useGame'

interface Props {
  status: Status
  pressing: boolean
  onClick: () => void
}

type Mood = 'smile' | 'surprised' | 'cool' | 'dead'

function moodFor(status: Status, pressing: boolean): Mood {
  if (status === 'won') return 'cool'
  if (status === 'lost') return 'dead'
  return pressing ? 'surprised' : 'smile'
}

const TITLES: Record<Mood, string> = {
  smile: 'Restart this seed',
  surprised: 'Careful…',
  cool: 'You won! Restart this seed',
  dead: 'Boom. Restart this seed',
}

export function Face({ status, pressing, onClick }: Props) {
  const mood = moodFor(status, pressing)
  return (
    <button type="button" className={`face face-${mood}`} onClick={onClick} title={TITLES[mood]} aria-label={TITLES[mood]} data-mood={mood}>
      <svg viewBox="0 0 48 48" aria-hidden="true">
        <circle cx="24" cy="24" r="21" fill="var(--face-fill)" stroke="var(--face-stroke)" strokeWidth="2.5" />
        {mood === 'cool' ? (
          <g fill="#1b1b1f">
            <rect x="9" y="17" width="13" height="8" rx="2.5" />
            <rect x="26" y="17" width="13" height="8" rx="2.5" />
            <rect x="21" y="19" width="6" height="2.2" />
            <path d="M6 18h4M38 18h4" stroke="#1b1b1f" strokeWidth="2" />
          </g>
        ) : mood === 'dead' ? (
          <g stroke="#1b1b1f" strokeWidth="2.6" strokeLinecap="round">
            <path d="M13 16l6 6M19 16l-6 6M29 16l6 6M35 16l-6 6" />
          </g>
        ) : (
          <g fill="#1b1b1f">
            <circle cx="17" cy="19" r={mood === 'surprised' ? 3 : 2.6} />
            <circle cx="31" cy="19" r={mood === 'surprised' ? 3 : 2.6} />
          </g>
        )}
        {mood === 'surprised' ? (
          <ellipse cx="24" cy="32" rx="4.5" ry="5.5" fill="#1b1b1f" />
        ) : mood === 'dead' ? (
          <path d="M16 34q8-6 16 0" fill="none" stroke="#1b1b1f" strokeWidth="2.6" strokeLinecap="round" />
        ) : (
          <path d="M14 29q10 10 20 0" fill="none" stroke="#1b1b1f" strokeWidth="2.6" strokeLinecap="round" />
        )}
      </svg>
    </button>
  )
}
