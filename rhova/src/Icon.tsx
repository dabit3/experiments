export type IconName = 'new' | 'open' | 'save' | 'undo' | 'redo' | 'select' | 'curve' | 'points' | 'extrude' | 'loft' | 'move' | 'rotate' | 'scale' | 'fit' | 'orbit' | 'grid' | 'cube' | 'layers' | 'eye' | 'lock' | 'export' | 'delete' | 'four' | 'settings' | 'sun' | 'info' | 'copy' | 'line'
const paths: Record<IconName, string> = {
  new: 'M6 3h9l4 4v14H6z M14 3v5h5',
  open: 'M3 7h7l2 2h9l-3 11H3z M3 7V4h7l2 3h8v3',
  save: 'M4 3h14l3 3v15H4z M8 3v7h9V3 M8 21v-8h9v8 M14 5v3',
  undo: 'M8 5 3 10l5 5 M4 10h11c7 0 7 9 1 10',
  redo: 'M16 5l5 5-5 5 M20 10h-11c-7 0-7 9-1 10',
  select: 'm6 3 13 11-7 1-3 7z M12 15l4 6',
  curve: 'M3 19C5-6 17 29 21 4 M2 17h3v3H2z M19 2h3v3h-3z',
  points: 'M4 18 9 5l11 4-4 12 M2 16h4v4H2z M7 3h4v4H7z M18 7h4v4h-4z M14 19h4v4h-4z',
  extrude: 'm4 12 8-4 8 4-8 5z M4 12v8l8 3 8-3v-8 M12 17v6 M12 8V1 M8 5l4-4 4 4',
  loft: 'M3 19C9 12 15 23 21 16V5C15 12 9 1 3 8z M3 13c6-7 12 4 18-3 M9 5v12 M15 8v11',
  move: 'M12 2v20 M2 12h20 M9 5l3-3 3 3 M19 9l3 3-3 3 M9 19l3 3 3-3 M5 9l-3 3 3 3',
  rotate: 'M20 8A9 9 0 1 0 20 17 M20 3v6h-6 M10 9l6 3-6 3z',
  scale: 'M3 12h9v9H3z M11 3h10v10 M21 3 11 13',
  fit: 'M8 3H3v5 M16 3h5v5 M3 16v5h5 M21 16v5h-5 M6 12h12 M12 6v12',
  orbit: 'M3 12c0-8 18-8 18 0s-18 8-18 0 M12 2c-7 0-7 20 0 20s7-20 0-20 M9 12h6',
  grid: 'M3 3h18v18H3z M3 9h18 M3 15h18 M9 3v18 M15 3v18',
  cube: 'm3 7 9-5 9 5v11l-9 5-9-5z M3 7l9 5 9-5 M12 12v11',
  layers: 'm2 8 10-5 10 5-10 5z M2 12l10 5 10-5 M2 16l10 5 10-5',
  eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12 M15 12a3 3 0 1 1-6 0 3 3 0 1 1 6 0',
  lock: 'M5 10h14v11H5z M8 10V6a4 4 0 0 1 8 0v4 M12 14v3',
  export: 'M9 5H4v16h16v-6 M12 3h9v9 M21 3 10 14',
  delete: 'M3 6h18 M9 6V3h6v3 M6 6l1 16h10l1-16 M10 10v8 M14 10v8',
  four: 'M2 3h20v18H2z M12 3v18 M2 12h20',
  settings: 'M4 5h16 M4 12h16 M4 19h16 M8 2v6 M16 9v6 M10 16v6',
  sun: 'M16 12a4 4 0 1 1-8 0 4 4 0 1 1 8 0 M12 1v3 M12 20v3 M1 12h3 M20 12h3 M4 4l2 2 M18 18l2 2 M4 20l2-2 M18 6l2-2',
  info: 'M22 12a10 10 0 1 1-20 0 10 10 0 1 1 20 0 M12 10v7 M12 6v1',
  copy: 'M9 8h12v14H9z M15 8V2H3v14h6',
  line: 'M3 20 20 3 M2 18h4v4H2z M18 1h4v4h-4z',
}
export function Icon({ name, size = 20 }: { name: IconName; size?: number }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.45" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={paths[name]} /></svg>
}
