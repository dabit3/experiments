interface VesselProps {
  kind: string
  className?: string
}

export function Vessel({ kind, className = '' }: VesselProps) {
  const carrier = kind === 'carrier'
  const submarine = kind === 'submarine'
  return (
    <svg
      className={`vessel ${className}`}
      viewBox="0 0 200 48"
      preserveAspectRatio="none"
      aria-hidden="true"
    >
      <path
        d="M3 24 25 5h161l10 9v20l-10 9H25Z"
        fill="#062b3d"
        opacity=".6"
        transform="translate(0 3)"
      />
      <path
        d="M3 24 25 4h161l10 9v20l-10 9H25Z"
        fill={submarine ? '#8ebbbf' : '#d5ece3'}
        stroke="#f0fff2"
        strokeWidth="1.5"
      />
      <path
        d="M11 24 29 10h150l10 8v10l-10 8H29Z"
        fill={carrier ? '#255569' : '#527889'}
      />
      {carrier ? (
        <>
          <path
            d="M24 24h156M45 13v22M159 13v22"
            stroke="#fff0c0"
            strokeWidth="1"
            strokeDasharray="6 4"
          />
          <path
            d="M65 7h62v9H65Z"
            fill="#a6d4d1"
            stroke="#132e40"
            strokeWidth="2"
          />
          <path d="m92 19 10 4-10 4 3-4Z" fill="#ffca63" />
          <path d="m131 19 10 4-10 4 3-4Z" fill="#ffca63" />
        </>
      ) : (
        <>
          <path
            d="M78 13h41l10 11-10 10H78Z"
            fill="#b5d9d7"
            stroke="#203d50"
            strokeWidth="2"
          />
          <path d="M88 17h22v14H88Z" fill="#19485d" />
          <path d="M89 18h20v4H89Z" fill="#60e8e0" />
          {!submarine && (
            <path
              d="M36 18h18v12H36Zm108 0h18v12h-18Z"
              fill="#aecbcc"
              stroke="#244759"
              strokeWidth="2"
            />
          )}
          {!submarine && (
            <path d="M21 22h25v4H21Zm134 0h27v4h-27Z" fill="#ffcd69" />
          )}
          {submarine && (
            <path d="M41 24h28m63 0h37" stroke="#193e50" strokeWidth="3" />
          )}
        </>
      )}
      <path d="M29 39h145" stroke="#efac4b" strokeWidth="2" />
    </svg>
  )
}
