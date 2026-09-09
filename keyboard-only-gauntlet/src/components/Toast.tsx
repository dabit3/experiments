interface Props {
  visible: boolean
  toastKey: number
}

export function Toast({ visible, toastKey }: Props) {
  return (
    <div className="toast-region" role="alert" aria-live="assertive">
      {visible && (
        <div key={toastKey} className="toast" data-testid="mouse-toast">
          <svg className="toast-icon" viewBox="0 0 24 24" aria-hidden="true">
            <rect x="6" y="2.5" width="12" height="19" rx="6" fill="none" stroke="currentColor" strokeWidth="2" />
            <path d="M12 2.5v7" stroke="currentColor" strokeWidth="2" />
            <path d="M4 4l16 16" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" />
          </svg>
          Mouse disabled - keyboard only!
        </div>
      )}
    </div>
  )
}
