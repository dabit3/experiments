interface Props {
  size?: 'header' | 'hero'
}

export function Wordmark({ size = 'header' }: Props) {
  return (
    <span className={`wordmark wordmark-${size}`} aria-label="Kestrel">
      <span className="wordmark-text">Kestrel</span>
      <span className="wordmark-reg" aria-hidden="true">
        ®
      </span>
    </span>
  )
}
