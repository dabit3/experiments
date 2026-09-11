import { useEffect, useRef, useState, type ChangeEvent } from 'react'
import { Icon } from './Icon'

export function ReferencePanel() {
  const fileRef = useRef<HTMLInputElement>(null)
  const [reference, setReference] = useState<{
    url: string
    name: string
  } | null>(null)
  const [error, setError] = useState('')
  useEffect(
    () => () => {
      if (reference) URL.revokeObjectURL(reference.url)
    },
    [reference],
  )
  const load = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (
      !['image/png', 'image/jpeg', 'image/webp'].includes(file.type) ||
      file.size > 20 * 1024 * 1024
    ) {
      setError('Choose a PNG, JPG or WebP under 20 MB.')
      return
    }
    setError('')
    setReference({ url: URL.createObjectURL(file), name: file.name })
    e.target.value = ''
  }
  return (
    <section className="inspector-section reference-section">
      <div className="section-heading">
        <h2>Reference</h2>
        <button
          className="icon-button"
          title="Load reference image"
          aria-label="Load reference image"
          onClick={() => fileRef.current?.click()}
        >
          <Icon name="plus" size={15} />
        </button>
      </div>
      <input
        ref={fileRef}
        className="sr-only"
        type="file"
        accept="image/png,image/jpeg,image/webp"
        aria-label="Reference image file"
        onChange={load}
      />
      {reference ? (
        <>
          <div className="reference-image">
            <img
              src={reference.url}
              alt={`Reference: ${reference.name}`}
              onError={() => {
                setError('This image could not be opened.')
                setReference(null)
              }}
            />
          </div>
          <div className="reference-caption">
            <span>{reference.name}</span>
            <button
              aria-label="Remove reference"
              className="icon-button"
              onClick={() => setReference(null)}
            >
              <Icon name="close" size={13} />
            </button>
          </div>
        </>
      ) : (
        <button
          className="reference-empty"
          onClick={() => fileRef.current?.click()}
        >
          <Icon name="image" size={25} />
          <strong>A little inspiration</strong>
          <span>Add a reference to draw from</span>
          <small>PNG, JPG, WEBP</small>
        </button>
      )}
      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
    </section>
  )
}
