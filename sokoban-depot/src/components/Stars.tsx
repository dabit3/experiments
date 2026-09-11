export function Stars({ count, size = 'md', label }: { count: 0 | 1 | 2 | 3; size?: 'sm' | 'md' | 'lg'; label?: string }) {
  return (
    <span className={`stars stars-${size}`} role="img" aria-label={label ?? `${count} of 3 stars`}>
      {[1, 2, 3].map((n) => (
        <svg key={n} viewBox="0 0 24 24" className={`star${n <= count ? ' star-on' : ''}`} aria-hidden="true">
          <path d="M12 2.5l2.9 6.2 6.7.8-4.9 4.6 1.3 6.7L12 17.5l-6 3.3 1.3-6.7L2.4 9.5l6.7-.8z" />
        </svg>
      ))}
    </span>
  )
}
