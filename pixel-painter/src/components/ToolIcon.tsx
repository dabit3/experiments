import type { Tool } from '../types'

const PATHS: Record<Tool, string> = {
  brush:
    'M4 20c1.5-.5 3.2-1 4-2.5 1-1.8-.3-3.8 1.3-5L18 4l2 2-8.5 8.7c-1.2 1.6-3.2.3-5 1.3C5 17 4.5 18.5 4 20z',
  eraser: 'M3 16l8-8 6 6-4 4H9l-6-6zM12.5 7.5l3-3 6 6-3 3',
  line: 'M4 20L20 4',
  rect: 'M4 6h16v12H4z',
  circle: 'M12 4a8 8 0 1 0 0 16 8 8 0 1 0 0-16z',
  fill: 'M6 3l8 8-6 6-6-6 4-8zM14 11l3 3M19 15c0 1.5-1 3-1 3s-1-1.5-1-3c0-.6.5-1 1-1s1 .4 1 1z',
}

export function ToolIcon({ tool }: { tool: Tool }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width="20"
      height="20"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={PATHS[tool]} />
    </svg>
  )
}
