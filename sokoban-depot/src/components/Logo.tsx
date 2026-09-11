export function Emblem({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 56 56" className={className} aria-hidden="true">
      <rect x="2" y="2" width="52" height="52" rx="15" fill="currentColor" />
      <path
        d="M28 14H18a7 7 0 0 0 0 14h3a3 3 0 0 1 0 6H11v7h11a10 10 0 0 0 0-20h-3a1 1 0 0 1 0-2h9zM32 14v27h6c10 0 14-6 14-14s-4-13-14-13zm7 7c4 0 6 2 6 6s-2 7-6 7z"
        fill="#fff9e9"
      />
    </svg>
  )
}

export function Logo() {
  return (
    <span className="logo">
      <Emblem className="logo-emblem" />
      <span className="wordmark">
        Sokoban
        <span>
          Depot<span className="brand-period">.</span>
        </span>
      </span>
    </span>
  )
}
