export function SnakeMascot() {
  return (
    <svg className="snake-mascot" viewBox="0 0 360 255" fill="none" aria-hidden="true">
      <defs>
        <linearGradient
          id="snake-skin"
          x1="110"
          y1="65"
          x2="225"
          y2="215"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#edff94" />
          <stop offset=".45" stopColor="#b8ed53" />
          <stop offset="1" stopColor="#668f24" />
        </linearGradient>
        <linearGradient
          id="snake-head"
          x1="215"
          y1="62"
          x2="245"
          y2="134"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#f2ffaf" />
          <stop offset="1" stopColor="#a6d944" />
        </linearGradient>
        <radialGradient id="apple-skin" cx=".3" cy=".2" r=".8">
          <stop stopColor="#ffb08e" />
          <stop offset=".45" stopColor="#ff7455" />
          <stop offset="1" stopColor="#c84330" />
        </radialGradient>
        <filter id="mascot-shadow" x="-30%" y="-30%" width="170%" height="190%">
          <feDropShadow dx="0" dy="12" stdDeviation="8" floodColor="#090e07" floodOpacity=".6" />
        </filter>
      </defs>
      <ellipse cx="180" cy="224" rx="113" ry="12" fill="#080e08" opacity=".35" />
      <g filter="url(#mascot-shadow)">
        <path
          d="M72 208h95c35 0 36-46 0-46h-45c-41 0-43-60-1-60h95"
          stroke="#4b6d24"
          strokeWidth="48"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M72 201h95c35 0 36-46 0-46h-45c-41 0-43-60-1-60h95"
          stroke="url(#snake-skin)"
          strokeWidth="43"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M78 188h87c17 0 20-19 0-20h-44c-53 0-54-85 0-85h76"
          stroke="#f1ffb1"
          strokeOpacity=".4"
          strokeWidth="5"
          strokeLinecap="round"
        />
        <path
          d="m90 193-5 20m31-20-5 20m31-20-5 20M107 80l-9 28m32-28-8 29m33-29-8 29"
          stroke="#719934"
          strokeWidth="3"
          strokeLinecap="round"
          opacity=".3"
        />
        <rect
          x="185"
          y="60"
          width="88"
          height="71"
          rx="32"
          fill="url(#snake-head)"
          transform="rotate(-8 229 95)"
        />
        <ellipse cx="230" cy="75" rx="12" ry="17" fill="#faffdf" transform="rotate(-8 230 75)" />
        <ellipse cx="254" cy="73" rx="10" ry="15" fill="#faffdf" transform="rotate(-8 254 73)" />
        <ellipse cx="235" cy="77" rx="5" ry="9" fill="#172719" />
        <ellipse cx="258" cy="75" rx="4.5" ry="8" fill="#172719" />
        <circle cx="237" cy="74" r="2" fill="white" />
        <circle cx="260" cy="72" r="1.6" fill="white" />
        <path d="M238 112c12 3 22-1 26-9" stroke="#467328" strokeWidth="3" strokeLinecap="round" />
        <path
          d="m268 109 15 2 8-6m-8 6 7 7"
          stroke="#ff866c"
          strokeWidth="4"
          strokeLinecap="round"
        />
        <ellipse cx="216" cy="106" rx="7" ry="4" fill="#88b442" opacity=".6" />
      </g>
      <g className="mascot-apple">
        <path
          d="M302 156c-18-15-33 1-24 21s22 21 29 7c12 4 21-14 18-26-3-13-15-11-23-2Z"
          fill="url(#apple-skin)"
        />
        <path d="m301 153 2-13" stroke="#956b43" strokeWidth="4" strokeLinecap="round" />
        <path d="M303 145c2-15 14-18 23-13-3 13-12 17-23 13Z" fill="#b8e779" />
        <path d="M286 159c-4 2-5 6-3 11" stroke="#ffd5bf" strokeWidth="4" strokeLinecap="round" />
      </g>
      <path d="m64 58 3-11 3 11 11 3-11 3-3 11-3-11-11-3 11-3Z" fill="#e5f4a3" />
      <path d="m308 64 2-7 2 7 7 2-7 2-2 7-2-7-7-2 7-2Z" fill="#e5f4a3" opacity=".6" />
      <circle cx="43" cy="153" r="3" fill="#e5f4a3" opacity=".4" />
    </svg>
  )
}
