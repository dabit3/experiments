import { useEffect, useRef, type CSSProperties, type KeyboardEvent } from 'react'
import type { ShapeElement, SlideElement, StickerElement, TextElement } from '../types'
import { contrastText } from '../lib/themes'

interface EditableProps {
  value: string
  onCommit: (value: string, contentHeight: number) => void
  onCancel: () => void
  style?: CSSProperties
  className?: string
}

/** Plain-text contentEditable that commits on blur / Escape. */
function EditableText({ value, onCommit, onCancel, style, className }: EditableProps) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const node = ref.current
    if (!node) return
    node.innerText = value
    node.focus()
    const range = document.createRange()
    range.selectNodeContents(node)
    const sel = window.getSelection()
    sel?.removeAllRanges()
    sel?.addRange(range)
  }, [])

  const onKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    e.stopPropagation()
    if (e.key === 'Escape') {
      e.preventDefault()
      onCancel()
    }
  }

  return (
    <div
      ref={ref}
      className={`editable ${className ?? ''}`}
      contentEditable
      suppressContentEditableWarning
      spellCheck={false}
      style={style}
      onKeyDown={onKeyDown}
      onBlur={() => {
        const node = ref.current
        const box = node?.parentElement
        const padding = box ? parseFloat(getComputedStyle(box).paddingTop) + parseFloat(getComputedStyle(box).paddingBottom) : 0
        onCommit(node?.innerText.replace(/\n$/, '') ?? '', (node?.scrollHeight ?? 0) + padding)
      }}
      onPointerDown={(e) => e.stopPropagation()}
      onDoubleClick={(e) => e.stopPropagation()}
    />
  )
}

function TextLines({ el }: { el: TextElement }) {
  if (!el.text) {
    return <div className="text-placeholder">{el.placeholder ?? ''}</div>
  }
  const lines = el.text.split('\n')
  if (el.bullets) {
    return (
      <ul className="text-bullets">
        {lines.map((line, i) => (
          <li key={i}>{line || '\u00a0'}</li>
        ))}
      </ul>
    )
  }
  return (
    <>
      {lines.map((line, i) => (
        <div key={i}>{line || '\u00a0'}</div>
      ))}
    </>
  )
}

function ArrowSvg({ el }: { el: ShapeElement }) {
  const { w, h } = el
  const t = Math.max(4, Math.min(18, h / 3))
  const head = Math.min(w * 0.4, h)
  const mid = h / 2
  return (
    <svg className="arrow-svg" width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
      <line x1={0} y1={mid} x2={Math.max(0, w - head + 1)} y2={mid} stroke={el.fill} strokeWidth={t} strokeLinecap="round" />
      <polygon points={`${w - head},${mid - h / 2} ${w},${mid} ${w - head},${mid + h / 2}`} fill={el.fill} />
    </svg>
  )
}

interface Props {
  el: SlideElement
  editing?: boolean
  onCommitText?: (value: string, contentHeight: number) => void
  onCancelEdit?: () => void
}

export function ElementBody({ el, editing = false, onCommitText, onCancelEdit }: Props) {
  if (el.kind === 'text') {
    const style: CSSProperties = {
      fontSize: el.fontSize,
      textAlign: el.align,
      fontWeight: el.bold ? 700 : 400,
      color: el.color,
      background: el.fill,
    }
    return (
      <div className={`el-text ${el.bullets ? 'is-bullets' : ''}`} style={style}>
        {editing && onCommitText && onCancelEdit ? (
          <EditableText value={el.text} onCommit={onCommitText} onCancel={onCancelEdit} />
        ) : (
          <TextLines el={el} />
        )}
      </div>
    )
  }
  if (el.kind === 'sticker') {
    const s: StickerElement = el
    return (
      <div className="el-sticker" style={{ fontSize: Math.min(s.w, s.h) * 0.78 }}>
        {s.emoji}
      </div>
    )
  }
  if (el.kind === 'arrow') {
    return <ArrowSvg el={el} />
  }
  const labelStyle: CSSProperties = { color: contrastText(el.fill), fontSize: el.fontSize }
  return (
    <div className={`el-shape el-${el.kind}`} style={{ background: el.fill }}>
      {editing && onCommitText && onCancelEdit ? (
        <EditableText value={el.label} onCommit={onCommitText} onCancel={onCancelEdit} className="shape-label" style={labelStyle} />
      ) : el.label ? (
        <div className="shape-label" style={labelStyle}>
          {el.label.split('\n').map((line, i) => (
            <div key={i}>{line || '\u00a0'}</div>
          ))}
        </div>
      ) : null}
    </div>
  )
}
