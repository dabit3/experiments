import { useCallback, useMemo, useRef, useState } from 'react'
import type { ChangeEvent } from 'react'
import { DropZone } from './components/DropZone'
import { Sidebar } from './components/Sidebar'
import { Stage } from './components/Stage'
import { fitAspect, fullRect, moveInto, roundRect } from './lib/crop'
import type { Rect } from './lib/crop'
import {
  DEFAULT_FILTERS,
  DEFAULT_TRANSFORM,
  cropBitmap,
  downloadBlob,
  exportBlob,
  exportFilename,
  loadBitmap,
  transformedSize,
} from './lib/image'
import type { ExportFormat, Filters, Transform } from './lib/image'
import type { Sample } from './samples'
import './App.css'

interface Doc {
  name: string
  /** The image as it was opened, used by "Reset all". */
  original: ImageBitmap
  /** Current pixels; replaced whenever a crop is applied. */
  source: ImageBitmap
}

export default function App() {
  const fileInput = useRef<HTMLInputElement>(null)
  const [doc, setDoc] = useState<Doc | null>(null)
  const [transform, setTransform] = useState<Transform>(DEFAULT_TRANSFORM)
  const [filters, setFilters] = useState<Filters>(DEFAULT_FILTERS)
  const [ratio, setRatio] = useState<number | null>(null)
  const [crop, setCrop] = useState<Rect | null>(null)
  const [compare, setCompare] = useState(false)
  const [format, setFormat] = useState<ExportFormat>('png')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const imageSize = useMemo(
    () => (doc ? transformedSize(doc.source, transform) : { w: 0, h: 0 }),
    [doc, transform],
  )
  const cropRect = useMemo(
    () => crop ?? roundRect(fitAspect(fullRect(imageSize), ratio, imageSize)),
    [crop, ratio, imageSize],
  )
  const cropIsFull =
    cropRect.x === 0 && cropRect.y === 0 && cropRect.w === imageSize.w && cropRect.h === imageSize.h

  const openBlob = useCallback(async (blob: Blob, name: string) => {
    setBusy(true)
    setError(null)
    try {
      const bitmap = await loadBitmap(blob)
      setDoc({ name, original: bitmap, source: bitmap })
      setTransform(DEFAULT_TRANSFORM)
      setFilters(DEFAULT_FILTERS)
      setRatio(null)
      setCrop(null)
      setCompare(false)
    } catch {
      setError(`Could not open "${name}" — is it an image?`)
    } finally {
      setBusy(false)
    }
  }, [])

  const onFile = (file: File) => void openBlob(file, file.name)

  const onInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) onFile(file)
    e.target.value = ''
  }

  const onSample = async (sample: Sample) => {
    setBusy(true)
    try {
      const res = await fetch(`/samples/${sample.file}`)
      await openBlob(await res.blob(), sample.file)
    } catch {
      setError(`Could not load sample "${sample.name}"`)
      setBusy(false)
    }
  }

  const updateTransform = (patch: Partial<Transform>) => {
    setTransform((t) => ({ ...t, ...patch }))
    // The canvas changes shape, so any partial crop no longer lines up.
    setCrop(null)
  }

  const onRatio = (next: number | null) => {
    setRatio(next)
    setCrop(roundRect(fitAspect(cropRect, next, imageSize)))
  }

  const onCropChange = (rect: Rect) => setCrop(roundRect(moveInto(rect, imageSize)))

  const onApplyCrop = async () => {
    if (!doc || cropIsFull) return
    setBusy(true)
    try {
      const source = await cropBitmap(doc.source, transform, cropRect)
      setDoc({ ...doc, source })
      setTransform(DEFAULT_TRANSFORM)
      setCrop(null)
    } finally {
      setBusy(false)
    }
  }

  const onDownload = async () => {
    if (!doc) return
    setBusy(true)
    setError(null)
    try {
      const blob = await exportBlob(doc.source, transform, filters, format)
      downloadBlob(blob, exportFilename(doc.name, format))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Export failed')
    } finally {
      setBusy(false)
    }
  }

  const onResetAll = () => {
    if (!doc) return
    setDoc({ ...doc, source: doc.original })
    setTransform(DEFAULT_TRANSFORM)
    setFilters(DEFAULT_FILTERS)
    setRatio(null)
    setCrop(null)
    setCompare(false)
  }

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden />
          <h1>Photo Crop</h1>
          <span className="brand-sub">crop · rotate · adjust · export</span>
        </div>
        {doc && (
          <div className="topbar-actions">
            <button type="button" className="btn btn-ghost" onClick={() => setDoc(null)}>
              New image
            </button>
            <div className="segmented segmented-small" role="radiogroup" aria-label="Export format">
              {(['png', 'jpeg'] as ExportFormat[]).map((f) => (
                <button
                  key={f}
                  type="button"
                  role="radio"
                  aria-checked={format === f}
                  className={format === f ? 'active' : ''}
                  onClick={() => setFormat(f)}
                >
                  {f.toUpperCase()}
                </button>
              ))}
            </div>
            <button
              type="button"
              className="btn btn-primary"
              onClick={onDownload}
              disabled={busy}
              data-testid="download"
              title={`Exports ${imageSize.w} × ${imageSize.h} with rotation, flips and adjustments baked in`}
            >
              {busy ? 'Working…' : `Download ${format.toUpperCase()}`}
            </button>
          </div>
        )}
      </header>

      <input
        ref={fileInput}
        type="file"
        accept="image/*"
        className="visually-hidden"
        onChange={onInputChange}
        data-testid="file-input"
        aria-label="Choose an image"
      />

      {error && (
        <div className="toast" role="alert">
          {error}
        </div>
      )}

      {doc ? (
        <main className="editor">
          <Stage
            source={doc.source}
            transform={transform}
            transformedSize={imageSize}
            filters={filters}
            compare={compare}
            crop={cropRect}
            ratio={ratio}
            onCropChange={onCropChange}
          />
          <Sidebar
            fileName={doc.name}
            imageSize={imageSize}
            crop={cropRect}
            cropIsFull={cropIsFull}
            ratio={ratio}
            transform={transform}
            filters={filters}
            compare={compare}
            busy={busy}
            onRatio={onRatio}
            onResetCrop={() => setCrop(null)}
            onApplyCrop={onApplyCrop}
            onTransform={updateTransform}
            onFilters={setFilters}
            onCompare={setCompare}
            onBrowse={() => fileInput.current?.click()}
            onResetAll={onResetAll}
          />
        </main>
      ) : (
        <main className="landing">
          <DropZone
            onFile={onFile}
            onSample={onSample}
            onBrowse={() => fileInput.current?.click()}
            loading={busy}
          />
        </main>
      )}
    </div>
  )
}
