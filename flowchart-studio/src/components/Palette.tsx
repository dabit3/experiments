import { NODE_KINDS } from '../types'
import type { NodeKind } from '../types'
import { ShapeIcon } from './Icons'
import './Palette.css'

interface PaletteProps {
  onDragStart: (kind: NodeKind, e: React.PointerEvent) => void
}

export function Palette({ onDragStart }: PaletteProps) {
  return (
    <aside className="palette" aria-label="Node palette">
      <div className="palette-title">Shapes</div>
      <p className="palette-hint">Drag onto the canvas</p>
      <div className="palette-list">
        {NODE_KINDS.map((meta) => (
          <button
            key={meta.kind}
            type="button"
            className="palette-item"
            data-kind={meta.kind}
            title={`Drag to add a ${meta.name} node (${meta.hint})`}
            onPointerDown={(e) => {
              if (e.button !== 0) return
              onDragStart(meta.kind, e)
            }}
            style={{ '--kind-color': meta.color } as React.CSSProperties}
          >
            <span className="palette-shape">
              <ShapeIcon kind={meta.kind} color={meta.color} />
            </span>
            <span className="palette-text">
              <span className="palette-name">{meta.name}</span>
              <span className="palette-kind">{meta.hint}</span>
            </span>
          </button>
        ))}
      </div>
      <div className="palette-footer">
        <div className="palette-title">Shortcuts</div>
        <dl className="shortcuts">
          <dt>Drag port</dt>
          <dd>connect</dd>
          <dt>Double-click</dt>
          <dd>edit label</dd>
          <dt>Drag canvas</dt>
          <dd>marquee</dd>
          <dt>Space + drag</dt>
          <dd>pan</dd>
          <dt>Wheel</dt>
          <dd>zoom</dd>
          <dt>Delete</dt>
          <dd>remove</dd>
          <dt>Ctrl + D</dt>
          <dd>duplicate</dd>
          <dt>Ctrl + Z</dt>
          <dd>undo</dd>
        </dl>
      </div>
    </aside>
  )
}
