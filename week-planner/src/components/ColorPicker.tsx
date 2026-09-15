import { COLORS, type ColorId } from '../types'

interface Props {
  value: ColorId
  onChange(color: ColorId): void
}

export function ColorPicker({ value, onChange }: Props) {
  return (
    <div className="color-picker" role="radiogroup" aria-label="Event color">
      {COLORS.map((color) => (
        <button
          key={color.id}
          type="button"
          role="radio"
          aria-checked={color.id === value}
          aria-label={color.name}
          title={color.name}
          className={`swatch ${color.id === value ? 'is-active' : ''}`}
          style={{ background: color.hex }}
          onClick={() => onChange(color.id)}
        />
      ))}
    </div>
  )
}
