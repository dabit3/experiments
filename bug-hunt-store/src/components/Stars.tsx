interface Props {
  rating: number
  reviews: number
}

const STAR = 'M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.5L12 17.2 6.1 20.5l1.3-6.5L2.5 9.4l6.6-.8L12 2.5z'

export function Stars({ rating, reviews }: Props) {
  const starCount = rating >= 5 ? 6 : 5
  return (
    <div className="stars" aria-label={`${rating} out of 5 stars, ${reviews} reviews`}>
      {Array.from({ length: starCount }, (_, i) => {
        const fill = Math.max(0, Math.min(1, rating + (starCount - 5) - i))
        return (
          <svg key={i} viewBox="0 0 24 24" className="star">
            <defs>
              <linearGradient id={`star-${rating}-${i}`}>
                <stop offset={`${fill * 100}%`} stopColor="var(--star)" />
                <stop offset={`${fill * 100}%`} stopColor="var(--star-empty)" />
              </linearGradient>
            </defs>
            <path d={STAR} fill={`url(#star-${rating}-${i})`} />
          </svg>
        )
      })}
      <span className="stars-text">
        {rating.toFixed(1)} <span className="muted">({reviews.toLocaleString()})</span>
      </span>
    </div>
  )
}
