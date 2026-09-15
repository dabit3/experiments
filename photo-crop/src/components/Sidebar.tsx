import { ASPECT_PRESETS } from '../lib/crop'
import type { Rect, Size } from '../lib/crop'
import { DEFAULT_FILTERS, FILTER_DEFS, filtersAreDefault } from '../lib/image'
import type { Filters, Transform } from '../lib/image'
import { Slider } from './Slider'

interface Props {
  fileName: string
  imageSize: Size
  crop: Rect
  cropIsFull: boolean
  ratio: number | null
  transform: Transform
  filters: Filters
  compare: boolean
  busy: boolean
  onRatio: (ratio: number | null) => void
  onResetCrop: () => void
  onApplyCrop: () => void
  onTransform: (patch: Partial<Transform>) => void
  onFilters: (filters: Filters) => void
  onCompare: (compare: boolean) => void
  onBrowse: () => void
  onResetAll: () => void
}

export function Sidebar(p: Props) {
  const rotateBy = (turns: number) =>
    p.onTransform({ quarterTurns: (((p.transform.quarterTurns + turns) % 4) + 4) % 4 })

  return (
    <aside className="sidebar">
      <section className="panel">
        <div className="panel-title">
          <h3>Image</h3>
          <span className="readout" data-testid="image-size">
            {p.imageSize.w} × {p.imageSize.h}
          </span>
        </div>
        <p className="file-name" title={p.fileName}>
          {p.fileName}
        </p>
        <div className="btn-row">
          <button type="button" className="btn" onClick={p.onBrowse}>
            Open image…
          </button>
          <button type="button" className="btn" onClick={p.onResetAll}>
            Reset all
          </button>
        </div>
      </section>

      <section className="panel">
        <div className="panel-title">
          <h3>Crop</h3>
          <span className="readout" data-testid="crop-size">
            {Math.round(p.crop.w)} × {Math.round(p.crop.h)}
          </span>
        </div>
        <div className="segmented" role="radiogroup" aria-label="Aspect ratio">
          {ASPECT_PRESETS.map((preset) => (
            <button
              key={preset.label}
              type="button"
              role="radio"
              aria-checked={p.ratio === preset.ratio}
              className={p.ratio === preset.ratio ? 'active' : ''}
              onClick={() => p.onRatio(preset.ratio)}
            >
              {preset.label}
            </button>
          ))}
        </div>
        <p className="hint">
          Offset {Math.round(p.crop.x)}, {Math.round(p.crop.y)} — drag the box to move it, drag a handle to resize.
        </p>
        <div className="btn-row">
          <button type="button" className="btn btn-primary" onClick={p.onApplyCrop} disabled={p.cropIsFull || p.busy}>
            Apply crop
          </button>
          <button type="button" className="btn" onClick={p.onResetCrop} disabled={p.cropIsFull}>
            Reset crop
          </button>
        </div>
      </section>

      <section className="panel">
        <div className="panel-title">
          <h3>Rotate &amp; flip</h3>
          <span className="readout" data-testid="rotation">
            {p.transform.quarterTurns * 90 + p.transform.angle}°
          </span>
        </div>
        <div className="btn-row btn-row-4">
          <button type="button" className="btn" onClick={() => rotateBy(-1)} title="Rotate 90° counter-clockwise">
            ⟲ 90°
          </button>
          <button type="button" className="btn" onClick={() => rotateBy(1)} title="Rotate 90° clockwise">
            ⟳ 90°
          </button>
          <button
            type="button"
            className={`btn${p.transform.flipH ? ' btn-on' : ''}`}
            onClick={() => p.onTransform({ flipH: !p.transform.flipH })}
            aria-pressed={p.transform.flipH}
            title="Flip horizontal"
          >
            ⇋ Flip H
          </button>
          <button
            type="button"
            className={`btn${p.transform.flipV ? ' btn-on' : ''}`}
            onClick={() => p.onTransform({ flipV: !p.transform.flipV })}
            aria-pressed={p.transform.flipV}
            title="Flip vertical"
          >
            ⥮ Flip V
          </button>
        </div>
        <Slider
          id="angle"
          label="Straighten"
          value={p.transform.angle}
          min={-45}
          max={45}
          unit="°"
          defaultValue={0}
          onChange={(angle) => p.onTransform({ angle })}
        />
      </section>

      <section className="panel">
        <div className="panel-title">
          <h3>Adjust</h3>
          <button
            type="button"
            className="link"
            onClick={() => p.onFilters(DEFAULT_FILTERS)}
            disabled={filtersAreDefault(p.filters)}
          >
            Reset
          </button>
        </div>
        {FILTER_DEFS.map((def) => (
          <Slider
            key={def.key}
            id={def.key}
            label={def.label}
            value={p.filters[def.key]}
            min={def.min}
            max={def.max}
            unit={def.unit}
            defaultValue={DEFAULT_FILTERS[def.key]}
            onChange={(v) => p.onFilters({ ...p.filters, [def.key]: v })}
          />
        ))}
        <button
          type="button"
          className={`btn btn-block${p.compare ? ' btn-on' : ''}`}
          onClick={() => p.onCompare(!p.compare)}
          aria-pressed={p.compare}
          data-testid="compare-toggle"
        >
          {p.compare ? 'Showing before — click for after' : 'Compare before / after'}
        </button>
      </section>
    </aside>
  )
}
