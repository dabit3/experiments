import { useState } from 'react'
import type { DragEvent } from 'react'
import { SAMPLES } from '../samples'
import type { Sample } from '../samples'

interface Props {
  onFile: (file: File) => void
  onSample: (sample: Sample) => void
  onBrowse: () => void
  loading: boolean
}

export function DropZone({ onFile, onSample, onBrowse, loading }: Props) {
  const [over, setOver] = useState(false)

  const onDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    setOver(false)
    const file = e.dataTransfer.files[0]
    if (file && file.type.startsWith('image/')) onFile(file)
  }

  return (
    <div
      className={`dropzone${over ? ' dropzone-over' : ''}`}
      onDragOver={(e) => {
        e.preventDefault()
        setOver(true)
      }}
      onDragLeave={() => setOver(false)}
      onDrop={onDrop}
    >
      <div className="dropzone-icon" aria-hidden>
        <svg viewBox="0 0 24 24" width="48" height="48" fill="none" stroke="currentColor" strokeWidth="1.5">
          <rect x="3" y="3" width="18" height="18" rx="3" />
          <circle cx="8.5" cy="8.5" r="1.5" />
          <path d="m21 15-5-5L5 21" />
        </svg>
      </div>
      <h2>Drop an image here</h2>
      <p>PNG, JPEG, WebP or GIF — everything stays in your browser.</p>
      <div className="dropzone-actions">
        <button type="button" className="btn btn-primary" onClick={onBrowse} disabled={loading}>
          Choose file…
        </button>
        <button
          type="button"
          className="btn"
          onClick={() => onSample(SAMPLES[0])}
          disabled={loading}
          data-testid="load-sample"
        >
          Load sample
        </button>
      </div>
      <div className="sample-grid">
        {SAMPLES.map((s) => (
          <button
            key={s.file}
            type="button"
            className="sample-card"
            onClick={() => onSample(s)}
            disabled={loading}
            title={`Load ${s.name}`}
          >
            <img src={`/samples/${s.file}`} alt={s.name} />
            <span>{s.name}</span>
          </button>
        ))}
      </div>
    </div>
  )
}
