import { LABELS } from '../data'
import type { LabelId } from '../types'

interface LabelPillProps {
  labelId: LabelId
}

export function LabelPill({ labelId }: LabelPillProps) {
  const label = LABELS[labelId]
  return (
    <span className="label-pill" style={{ background: label.color }}>
      {label.name}
    </span>
  )
}
