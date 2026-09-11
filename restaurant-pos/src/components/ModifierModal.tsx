import { useMemo, useState } from 'react'
import { fmt, fmtDelta } from '../lib/money'
import type { ChosenModifier, Course, MenuItem, ModifierGroup } from '../types'
import { Modal } from './Modal'
import './ModifierModal.css'

export interface ModifierResult {
  modifiers: ChosenModifier[]
  note: string
  course: Course
  seat: number
}

interface Props {
  item: MenuItem
  seat: number
  partySize: number
  onClose: () => void
  onAdd: (result: ModifierResult) => void
}

type Selection = Record<string, string[]>

const QUICK_NOTES = ['Sauce on the side', 'No onions', 'Extra crispy', 'Birthday — add candle', 'Allergy: see server']

function groupSatisfied(group: ModifierGroup, chosen: string[]): boolean {
  if (!group.required) return true
  return chosen.length >= group.min
}

export function ModifierModal({ item, seat: initialSeat, partySize, onClose, onAdd }: Props) {
  const [selection, setSelection] = useState<Selection>(() =>
    Object.fromEntries(item.modifierGroups.map((g) => [g.id, []])),
  )
  const [note, setNote] = useState('')
  const [course, setCourse] = useState<Course>(item.defaultCourse)
  const [seat, setSeat] = useState(initialSeat)

  const toggle = (group: ModifierGroup, optionId: string) => {
    setSelection((prev) => {
      const current = prev[group.id] ?? []
      if (group.max === 1) {
        return { ...prev, [group.id]: current[0] === optionId && !group.required ? [] : [optionId] }
      }
      if (current.includes(optionId)) return { ...prev, [group.id]: current.filter((id) => id !== optionId) }
      if (current.length >= group.max) return prev
      return { ...prev, [group.id]: [...current, optionId] }
    })
  }

  const modifiers = useMemo<ChosenModifier[]>(
    () =>
      item.modifierGroups.flatMap((g) =>
        (selection[g.id] ?? []).map((optionId) => {
          const option = g.options.find((o) => o.id === optionId)!
          return {
            groupId: g.id,
            groupName: g.name,
            optionId,
            optionName: option.name,
            delta: option.delta,
          }
        }),
      ),
    [item, selection],
  )

  const price = item.price + modifiers.reduce((s, m) => s + m.delta, 0)
  const missing = item.modifierGroups.filter((g) => !groupSatisfied(g, selection[g.id] ?? []))
  const canAdd = missing.length === 0

  return (
    <Modal
      title={item.name}
      subtitle={`${item.description} · ${fmt(item.price)}`}
      onClose={onClose}
      wide
      footer={
        <>
          {!canAdd && (
            <span className="modifier-missing">
              Choose {missing.map((g) => g.name.toLowerCase()).join(' and ')} to continue
            </span>
          )}
          <span className="spacer" />
          <button type="button" className="btn-ghost btn-lg" onClick={onClose}>
            Cancel
          </button>
          <button
            type="button"
            className="btn-primary btn-lg"
            disabled={!canAdd}
            onClick={() => onAdd({ modifiers, note: note.trim(), course, seat })}
          >
            Add to Seat {seat} · {fmt(price)}
          </button>
        </>
      }
    >
      <div className="modifier-layout">
        <div className="modifier-groups">
          {item.modifierGroups.map((group) => {
            const chosen = selection[group.id] ?? []
            const ok = groupSatisfied(group, chosen)
            return (
              <section key={group.id} className="modifier-group">
                <div className="field-label">
                  <span>{group.name}</span>
                  <span className={`hint ${group.required && !ok ? 'required' : ''}`}>
                    {group.required
                      ? ok
                        ? 'Required ✓'
                        : 'Required'
                      : group.max === 1
                        ? 'Optional'
                        : `Optional · up to ${group.max}`}
                  </span>
                </div>
                <div className="option-grid">
                  {group.options.map((o) => {
                    const selected = chosen.includes(o.id)
                    return (
                      <button
                        type="button"
                        key={o.id}
                        className={`option ${selected ? 'selected' : ''}`}
                        aria-pressed={selected}
                        onClick={() => toggle(group, o.id)}
                      >
                        <span>{o.name}</span>
                        <span className="delta">{fmtDelta(o.delta)}</span>
                      </button>
                    )
                  })}
                </div>
              </section>
            )
          })}

          <section className="modifier-group">
            <div className="field-label">
              <span>Item note</span>
              <span className="hint">Printed on the kitchen ticket</span>
            </div>
            <div className="quick-notes">
              {QUICK_NOTES.map((q) => (
                <button type="button" key={q} className="btn-sm btn-ghost" onClick={() => setNote(q)}>
                  {q}
                </button>
              ))}
            </div>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="e.g. No onions, sauce on the side…"
              aria-label="Item note"
            />
          </section>
        </div>

        <aside className="modifier-side">
          <div className="field-label">
            <span>Seat</span>
          </div>
          <div className="seat-picker">
            {Array.from({ length: partySize }, (_, i) => i + 1).map((n) => (
              <button
                type="button"
                key={n}
                className={`option ${seat === n ? 'selected' : ''}`}
                onClick={() => setSeat(n)}
                aria-pressed={seat === n}
              >
                {n}
              </button>
            ))}
          </div>

          <div className="field-label">
            <span>Course</span>
          </div>
          <div className="course-picker">
            {([1, 2, 3] as Course[]).map((c) => (
              <button
                type="button"
                key={c}
                className={`option ${course === c ? 'selected' : ''}`}
                onClick={() => setCourse(c)}
                aria-pressed={course === c}
              >
                Course {c}
              </button>
            ))}
          </div>

          <div className="price-preview">
            <span className="muted">Line total</span>
            <strong>{fmt(price)}</strong>
          </div>
        </aside>
      </div>
    </Modal>
  )
}
