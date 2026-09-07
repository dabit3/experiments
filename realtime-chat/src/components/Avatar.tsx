interface AvatarProps {
  name: string
  color: string
  size?: number
}

export function Avatar({ name, color, size = 36 }: AvatarProps) {
  return (
    <span
      className="avatar"
      style={{ background: color, width: size, height: size, fontSize: size * 0.45 }}
      aria-hidden="true"
    >
      {name.trim().charAt(0).toUpperCase()}
    </span>
  )
}
