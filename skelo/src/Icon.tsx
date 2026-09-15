export type IconName = 'select' | 'rectangle' | 'pull' | 'paint' | 'orbit' | 'pan' | 'zoom' | 'fit' | 'undo' | 'redo' | 'save' | 'open' | 'group' | 'trash' | 'home' | 'top' | 'front' | 'right' | 'sun' | 'eye' | 'axes' | 'cube' | 'line' | 'info' | 'download'
const paths: Record<IconName, React.ReactNode> = {
  select: <><path d="m6 3 14 11-7 1-4 7Z" fill="#193e52"/><path d="m14 15 4 6" stroke="#193e52" strokeWidth="2.4"/></>,
  rectangle: <><path d="m3 18 5-12 15 1-5 13Z" fill="#d6edf3"/><path d="M7 6h3M3 17v3h3M20 7h3v3M16 20h3v-3" stroke="#d54040" strokeWidth="2"/></>,
  pull: <><path d="m3 17 8-4 11 4-8 5Z" fill="#a3d0df"/><path d="M6 13v5l8 3v-7" /><path d="M13 16V3m-4 4 4-4 4 4" stroke="#e24543" strokeWidth="2.5"/></>,
  paint: <><path d="m5 5 10-1 7 10-10 7L2 11Z" fill="#bbdfeb"/><path d="m5 5 9 10 8-1M13 4l4-2M3 17c-4 5 4 6 2 1" /><path d="M13 20h10" stroke="#d9a054" strokeWidth="3"/></>,
  orbit: <><path d="M4 17c-5-8 11-13 17-7M4 17l1-5M4 17h5" stroke="#df4540" strokeWidth="2"/><path d="M20 7c7 9-9 16-16 10M20 7l-5 1M20 7v5" strokeWidth="2"/></>,
  pan: <path d="M8 12V5c0-3 3-3 3 0v5-7c0-2 3-2 3 0v7-5c0-2 3-2 3 0v7-3c0-2 3-2 3 0v6c0 4-3 7-7 7-3 0-4-2-6-4l-4-5c-1-2 1-3 3-1l2 2" fill="#fff1d2"/>,
  zoom: <><circle cx="10" cy="9" r="6"/><path d="m14 14 7 8" strokeWidth="2"/></>,
  fit: <><circle cx="12" cy="11" r="5"/><path d="M3 8V3h5M16 3h5v5M3 16v5h5M16 21h5v-5" stroke="#e24543"/></>,
  undo: <><path d="M7 5 2 10l5 5M3 10h12c8 0 8 10 0 10" strokeWidth="2"/></>,
  redo: <><path d="m17 5 5 5-5 5M21 10H9c-8 0-8 10 0 10" strokeWidth="2"/></>,
  save: <><path d="M3 3h16l3 3v16H3Z" fill="#d5e5ed"/><path d="M7 3v7h10V3M7 22v-8h11v8M14 4v4"/></>,
  open: <><path d="M2 7h8l2 3h10l-4 11H3Z" fill="#edcf8c"/><path d="M3 7V4h8l3 3h7v3"/></>,
  group: <><path d="m6 8 6-3 7 3v8l-7 4-6-4Zm0 0 6 4 7-4m-7 4v8"/><path d="M2 7V2h5M17 2h5v5M2 17v5h5M17 22h5v-5" stroke="#3b77b9"/></>,
  trash: <><path d="M5 7h14l-1 15H6ZM3 7h18M9 7V3h6v4M10 10v8m4-8v8"/></>,
  home: <><path d="m2 12 10-9 10 9M5 10v12h14V10M10 22v-8h5v8" fill="#e1e7e8"/></>,
  top: <><path d="M4 4h16v16H4Z" fill="#dbe7ea"/><path d="m4 4 8 8 8-8m-8 8v8"/></>,
  front: <><path d="M4 9h16v12H4ZM2 9 12 2l10 7" fill="#dbe7ea"/><path d="M9 21v-8h6v8"/></>,
  right: <><path d="m5 7 12-4 4 3v14l-12 3-4-3Z" fill="#dbe7ea"/><path d="m5 7 4 3 12-4M9 10v13"/></>,
  sun: <><circle cx="12" cy="12" r="5" fill="#f2ce75" stroke="#ae8b37"/><path d="M12 1v3m0 16v3M1 12h3m16 0h3M4 4l2 2m12 12 2 2M4 20l2-2M18 6l2-2" stroke="#ae8b37"/></>,
  eye: <><path d="M2 12S6 5 12 5s10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3" fill="#487b89"/></>,
  axes: <><path d="M10 14V2" stroke="#327acf"/><path d="m10 14 12 6" stroke="#d3423d"/><path d="m10 14-8 6" stroke="#4f965e"/></>,
  cube: <><path d="m3 7 9-5 9 5v11l-9 5-9-5Zm0 0 9 5 9-5m-9 5v11" fill="#e7edef"/></>,
  line: <><path d="m3 21 16-16 3 3L6 24Z" fill="#db6151"/><path d="m19 5 2-2 3 3-2 2M3 21l-1 4 4-1"/></>,
  info: <><circle cx="12" cy="12" r="10"/><path d="M12 10v8m0-13v2" strokeWidth="2"/></>,
  download: <><path d="M12 2v14m-5-5 5 5 5-5M3 17v5h18v-5"/></>,
}
export function Icon({ name, size = 24 }: { name: IconName; size?: number }) {
  return <svg width={size} height={size} viewBox="0 0 26 26" fill="none" stroke="#285e78" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name]}</svg>
}
