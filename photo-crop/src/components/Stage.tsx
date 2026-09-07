import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { drawTransformed, filtersToCss } from '../lib/image'
import type { Filters, Transform } from '../lib/image'
import type { Rect, Size } from '../lib/crop'
import { CropOverlay } from './CropOverlay'

interface Props {
  source: ImageBitmap
  transform: Transform
  transformedSize: Size
  filters: Filters
  compare: boolean
  crop: Rect
  ratio: number | null
  onCropChange: (rect: Rect) => void
}

export function Stage({ source, transform, transformedSize, filters, compare, crop, ratio, onCropChange }: Props) {
  const stageRef = useRef<HTMLDivElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [avail, setAvail] = useState<Size>({ w: 0, h: 0 })

  useLayoutEffect(() => {
    const el = stageRef.current
    if (!el) return
    const measure = () => setAvail({ w: el.clientWidth - 48, h: el.clientHeight - 48 })
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  useEffect(() => {
    const ctx = canvasRef.current?.getContext('2d')
    if (ctx) drawTransformed(ctx, source, transform)
  }, [source, transform])

  const scale =
    avail.w > 0 && avail.h > 0 ? Math.min(avail.w / transformedSize.w, avail.h / transformedSize.h, 1) : 0
  const displayW = transformedSize.w * scale
  const displayH = transformedSize.h * scale

  return (
    <div className="stage" ref={stageRef}>
      <div className="stage-image" style={{ width: displayW, height: displayH }}>
        <canvas
          ref={canvasRef}
          className="stage-canvas"
          style={{ filter: compare ? 'none' : filtersToCss(filters) }}
          data-testid="preview-canvas"
        />
        {scale > 0 && (
          <CropOverlay rect={crop} bounds={transformedSize} scale={scale} ratio={ratio} onChange={onCropChange} />
        )}
        <div className={`compare-badge${compare ? ' compare-badge-before' : ''}`} data-testid="compare-badge">
          {compare ? 'Before' : 'After'}
        </div>
      </div>
    </div>
  )
}
