interface Props {
  id: string
  label: string
  sublabel: string
  value: number
  min: number
  max: number
  onChange: (n: number) => void
}

export function CountStepper({ id, label, sublabel, value, min, max, onChange }: Props) {
  return (
    <div className="count-stepper">
      <div className="count-stepper-text">
        <span className="count-stepper-label">{label}</span>
        <span className="count-stepper-sub">{sublabel}</span>
      </div>
      <div className="count-stepper-controls">
        <button
          type="button"
          className="count-btn"
          aria-label={`Fewer ${label.toLowerCase()}`}
          disabled={value <= min}
          onClick={() => onChange(value - 1)}
        >
          −
        </button>
        <output id={id} className="count-value" aria-live="polite">
          {value}
        </output>
        <button
          type="button"
          className="count-btn"
          aria-label={`More ${label.toLowerCase()}`}
          disabled={value >= max}
          onClick={() => onChange(value + 1)}
        >
          +
        </button>
      </div>
    </div>
  )
}
