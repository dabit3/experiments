import { PartIcon, RotateIcon } from './icons.tsx'
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
      <div className="panel-head">
        <h2>Parts</h2>
        <p>Drag a part onto the canvas</p>
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
                <span className={`part-icon part-${type}`}>
                  <PartIcon type={type} />
                </span>
                <span className="tray-text">
                  <span className="tray-label">
                    {def.label}
                    {def.rotatable && (
                      <span className="tray-rot" title="Rotatable">
                        <RotateIcon />
                      </span>
                    )}
                  </span>
                  <span className="tray-desc">{def.description}</span>
                </span>
                <span className={`tray-count${empty ? ' zero' : ''}`}>{empty ? 'Placed' : `×${left}`}</span>
              </button>
            </li>
          )
        })}
      </ul>
      <div className="tray-tips">
        <h3>Shortcuts</h3>
        <dl>
          <dt>Rotate</dt>
          <dd>
            Scroll, or <kbd>R</kbd> / <kbd>⇧R</kbd> · snaps to 15°
          </dd>
          <dt>Move</dt>
          <dd>Drag a placed part</dd>
          <dt>Remove</dt>
          <dd>
            Drag off the canvas, or <kbd>Del</kbd>
          </dd>
        </dl>
      </div>
    </aside>
  )
}
