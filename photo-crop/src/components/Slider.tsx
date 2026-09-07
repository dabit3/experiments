interface Props {
  id: string
  label: string
  value: number
  min: number
  max: number
  step?: number
  unit?: string
  defaultValue?: number
  onChange: (value: number) => void
}

export function Slider({ id, label, value, min, max, step = 1, unit = '', defaultValue, onChange }: Props) {
  const changed = defaultValue !== undefined && value !== defaultValue
  return (
    <div className="slider">
      <div className="slider-head">
        <label htmlFor={id}>{label}</label>
        <button
          type="button"
          className={`slider-value${changed ? ' slider-value-changed' : ''}`}
          onClick={() => defaultValue !== undefined && onChange(defaultValue)}
          title={defaultValue !== undefined ? 'Reset' : undefined}
          disabled={!changed}
        >
          {value}
          {unit}
        </button>
      </div>
      <input
        id={id}
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
      />
    </div>
  )
}
