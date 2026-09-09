import { PART_DEFS, PART_ORDER, type PartType } from './parts.ts'

interface Props {
  remaining: Partial<Record<PartType, number>>
  onPointerDown: (type: PartType, e: React.PointerEvent) => void
  disabled: boolean
  dragging: PartType | null
}

export function Tray({ remaining, onPointerDown, disabled, dragging }: Props) {
  const types = PART_ORDER.filter((t) => remaining[t] !== undefined)
  return (
    <aside className="tray" aria-label="Parts tray">
      <div className="tray-head">
        <h2>Parts tray</h2>
        <p>Drag a part into the scene</p>
      </div>
      <ul className="tray-list">
        {types.map((type) => {
          const def = PART_DEFS[type]
          const left = remaining[type] ?? 0
          const empty = left <= 0
          return (
            <li key={type}>
              <button
                type="button"
                className={`tray-item${empty ? ' empty' : ''}${dragging === type ? ' lifting' : ''}`}
                disabled={disabled || empty}
                onPointerDown={(e) => onPointerDown(type, e)}
                aria-label={`${def.label}, ${left} left`}
              >
                <span className={`part-icon part-${type}`} aria-hidden="true">
                  <span className="part-shape" />
                  {type === 'seesaw' && <span className="part-base" />}
                  {type === 'fan' && <span className="part-blades" />}
                </span>
                <span className="tray-text">
                  <span className="tray-label">
                    {def.label}
                    {def.rotatable && (
                      <span className="tray-rot" title="Rotatable">
                        ⟳
                      </span>
                    )}
                  </span>
                  <span className="tray-desc">{def.description}</span>
                </span>
                <span className={`tray-count${empty ? ' zero' : ''}`}>×{left}</span>
              </button>
            </li>
          )
        })}
      </ul>
      <div className="tray-tips">
        <h3>Controls</h3>
        <dl>
          <dt>Rotate</dt>
          <dd>
            Scroll wheel or <kbd>R</kbd> (<kbd>Shift</kbd>+<kbd>R</kbd> reverses), snaps to 15°
          </dd>
          <dt>Move</dt>
          <dd>Drag a placed part</dd>
          <dt>Remove</dt>
          <dd>
            Drag it out of the scene or press <kbd>Del</kbd>
          </dd>
        </dl>
      </div>
    </aside>
  )
}
