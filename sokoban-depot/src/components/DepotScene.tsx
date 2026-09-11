function Cargo({ x, y, scale = 1 }: { x: number; y: number; scale?: number }) {
  return (
    <g transform={`translate(${x} ${y}) scale(${scale})`} stroke="#243b48" strokeWidth="2" strokeLinejoin="round">
      <path d="M0 0 33-18 66 0 33 19Z" fill="#ffe2a0" />
      <path d="M0 0 33 19V57L0 38Z" fill="#f5ad48" />
      <path d="M33 19 66 0V38L33 57Z" fill="#dc7b32" />
      <path d="m5 8 23 14v25L5 34Zm33 15 23-14v25L38 48Z" fill="none" stroke="#9c572d" />
      <path d="m5 8 23 39M5 34 28 22m10 1 23 11M38 48 61 9" stroke="#fff0c4" strokeWidth="4" />
      <path d="m26-14 12 7 10-6-12-6zM26-4l12 7 10-6-12-6Z" fill="#fff8dc" stroke="none" />
    </g>
  )
}

export function DepotScene() {
  return (
    <svg
      className="depot-scene"
      viewBox="0 0 600 410"
      role="img"
      aria-label="An illustrated miniature depot with crates, a delivery worker and a loading bay"
    >
      <circle cx="344" cy="188" r="170" fill="#f2b44d" />
      <circle cx="344" cy="188" r="148" fill="none" stroke="#fff8e7" strokeWidth="1" opacity=".5" />
      <path d="M68 332 322 190 564 324 310 399Z" fill="#c9c4ad" opacity=".65" />
      <path d="M56 248 310 101 554 243V268L302 414 56 272Z" fill="#1d3542" />
      <path
        d="M56 248 310 101 554 243 302 390Z"
        fill="#c8dad5"
        stroke="#243b48"
        strokeWidth="3"
        strokeLinejoin="round"
      />
      <g stroke="#8eaba8" strokeWidth="1.5">
        {[1, 2, 3, 4, 5].map((i) => (
          <g key={i}>
            <path d={`M${56 + i * 42} ${248 - i * 24.5}l244 142`} />
            <path d={`M${56 + i * 40.7} ${248 + i * 23.7}l254-147`} />
          </g>
        ))}
      </g>
      <path d="M56 248v-105L267 22v104Z" fill="#35566a" stroke="#243b48" strokeWidth="3" />
      <path d="m56 143 14 8L281 29 267 22Z" fill="#7fa1af" stroke="#243b48" strokeWidth="2" />
      <path d="M70 151v106l211-121V29Z" fill="#547c8c" />
      <g stroke="#86a3ad" strokeWidth="2" opacity=".5">
        <path d="M70 182l211-121M70 213l211-121M70 244l211-121M110 128v31m43-55v30m44-56v32m-65 52v30m43-55v30m44-55v31" />
      </g>
      <path d="M267 22 479 145V249L267 126Z" fill="#ee6345" stroke="#243b48" strokeWidth="3" />
      <path d="m267 22 12-7 211 122-11 8Z" fill="#ffa482" stroke="#243b48" strokeWidth="2" />
      <path d="m307 84 115 66v65l-115-66Z" fill="#243b48" />
      <path d="m314 98 99 57v43l-99-57Z" fill="#bbc9c5" />
      <g stroke="#71898c" strokeWidth="3">
        <path d="m314 110 99 57m-99-45 99 57m-99-45 99 57" />
      </g>
      <path d="m304 151 123 71-9 5-123-71Z" fill="#ffc658" stroke="#243b48" strokeWidth="2" />
      <path d="m321 162 6-4m12 15 6-4m12 14 6-4m12 15 6-4m12 14 6-4" stroke="#243b48" strokeWidth="6" />
      <g transform="matrix(.87 .5 0 1 328 68)">
        <rect width="75" height="27" rx="2" fill="#fff8e7" stroke="#243b48" strokeWidth="2" />
        <text x="37" y="20" textAnchor="middle" fill="#243b48" fontFamily="var(--display)" fontSize="21">
          DEPOT 01
        </text>
      </g>
      <g transform="matrix(.87 -.5 0 1 99 143)">
        <rect width="65" height="39" rx="2" fill="#fff2d0" stroke="#243b48" strokeWidth="2" />
        <path d="M11 20h42m-9-9 10 9-10 9" fill="none" stroke="#e75035" strokeWidth="6" />
      </g>
      <path d="m190 273 37-22 39 22-38 22Z" fill="none" stroke="#f6bb4c" strokeWidth="6" strokeDasharray="9 4" />
      <path d="m349 304 37-22 39 22-38 22Z" fill="none" stroke="#f6bb4c" strokeWidth="6" strokeDasharray="9 4" />
      <Cargo x={147} y={191} />
      <Cargo x={195} y={162} />
      <Cargo x={174} y={120} scale={0.95} />
      <g className="scene-cargo">
        <Cargo x={370} y={248} />
      </g>
      <g className="scene-worker" transform="translate(296 215)">
        <ellipse cy="77" rx="29" ry="12" fill="#254b52" opacity=".25" />
        <path d="m-15 61-5 12 15 6 5-16M9 61l-4 14 15 5 4-16" fill="#243b48" />
        <path d="M-15 35h32l4 30-19 3-20-6Z" fill="#2e6077" stroke="#243b48" strokeWidth="2" />
        <path d="M-16 26q16-9 33 0l7 24-24 9-23-12Z" fill="#ed5b3b" stroke="#243b48" strokeWidth="2" />
        <path d="m-16 37 15 6 20-6m-13-9 4 19" fill="none" stroke="#fff4d4" strokeWidth="5" />
        <path d="m-21 35-8 13 8 5 8-15M20 34l10 12-7 7-11-15" fill="#efb98b" stroke="#243b48" strokeWidth="2" />
        <rect x="-15" y="0" width="31" height="29" rx="13" fill="#efb98b" stroke="#243b48" strokeWidth="2" />
        <path d="M-19 8q-5-27 17-28 21 0 22 24Z" fill="#ffcc58" stroke="#243b48" strokeWidth="2" />
        <path d="M-22 7q22-11 46-1v8q-25-5-46 2Z" fill="#ffe298" stroke="#243b48" strokeWidth="2" />
        <path d="M-2-16V1" stroke="#fff1bd" strokeWidth="5" />
        <circle cx="3" cy="17" r="2" fill="#243b48" />
        <circle cx="12" cy="15" r="2" fill="#243b48" />
        <path d="m4 24 6-1" stroke="#ab6644" strokeWidth="2" strokeLinecap="round" />
      </g>
      <g transform="translate(487 290)">
        <path d="m-14 17 19-11 19 11-19 11Z" fill="#243b48" />
        <path d="M0 14 5-16 13 10Z" fill="#ee6345" stroke="#243b48" strokeWidth="2" />
        <path d="m2-3 8-1 2 7-11 1Z" fill="#fff4d4" />
      </g>
      <g fill="#243b48">
        <path d="m492 58 3 12 12 3-12 3-3 12-3-12-12-3 12-3Z" />
        <path d="m94 56 2 8 8 2-8 2-2 8-2-8-8-2 8-2Z" />
      </g>
    </svg>
  )
}
