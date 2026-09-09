import type { CSSProperties, ReactNode } from 'react'
import type { Product } from '../types'

/*
 * Deterministic line illustrations, one per product, drawn in a 200×250 box.
 * Strokes inherit `currentColor`; the tinted backdrop comes from the product hue.
 */
const ART: Record<number, ReactNode> = {
  1: (
    <>
      <path d="M52 150v-30a48 48 0 0 1 96 0v30" />
      <rect x="40" y="130" width="30" height="52" rx="10" fill="#fff" />
      <rect x="130" y="130" width="30" height="52" rx="10" fill="#fff" />
      <rect x="62" y="140" width="10" height="32" rx="4" fill="currentColor" stroke="none" opacity="0.15" />
      <rect x="128" y="140" width="10" height="32" rx="4" fill="currentColor" stroke="none" opacity="0.15" />
    </>
  ),
  2: (
    <>
      <path d="M72 40h56l6 30H66l6-30Zm0 170h56l6-30H66l6 30Z" fill="#fff" />
      <circle cx="100" cy="125" r="50" fill="#fff" />
      <circle cx="100" cy="125" r="40" />
      <path d="M100 125V97m0 28 18 10" strokeWidth="4" />
      <circle cx="100" cy="125" r="3" fill="currentColor" stroke="none" />
      <rect x="152" y="112" width="8" height="26" rx="2" fill="#fff" />
    </>
  ),
  3: (
    <>
      <path d="M70 210h60" strokeWidth="5" />
      <path d="M100 210v-70L60 90" />
      <path d="M36 70h58l-14 34H50L36 70Z" fill="#fff" />
      <path d="M50 110h30" strokeWidth="4" />
      <path d="M66 126l-8 22M66 126l8 22" opacity="0.35" />
    </>
  ),
  4: (
    <>
      <path d="M70 90c0-40 60-40 60 0" />
      <path d="M40 90h120l-10 110H50L40 90Z" fill="#fff" />
      <path d="M40 90h120" />
      <path d="M62 128h76" opacity="0.35" />
      <circle cx="58" cy="96" r="3" fill="currentColor" stroke="none" />
      <circle cx="142" cy="96" r="3" fill="currentColor" stroke="none" />
    </>
  ),
  5: (
    <>
      <rect x="40" y="120" width="120" height="70" rx="26" fill="#fff" />
      <path d="M40 150h120" />
      <path d="M78 60a14 14 0 1 1 28 0c0 14-6 22-6 40h-16c0-18-6-26-6-40Z" fill="#fff" />
      <path d="M118 60a14 14 0 1 1 28 0c0 14-6 22-6 40h-16c0-18-6-26-6-40Z" fill="#fff" />
      <circle cx="100" cy="170" r="4" fill="currentColor" stroke="none" />
    </>
  ),
  6: (
    <>
      <rect x="70" y="30" width="60" height="190" rx="30" fill="#fff" />
      <rect x="82" y="88" width="36" height="74" rx="8" fill="currentColor" stroke="none" opacity="0.9" />
      <path d="M90 132c6-16 10 10 20-10" stroke="#fff" strokeWidth="2.5" />
      <path d="M84 52h32M84 198h32" opacity="0.4" />
    </>
  ),
  7: (
    <>
      <path d="M60 110h80l-8 90H68l-8-90Z" fill="#fff" />
      <path d="M60 110h80" />
      <path d="M140 116c30 6 40-10 44-44" />
      <path d="M60 120c-30 0-30 40 0 40" />
      <path d="M92 110c0-20 8-30 8-30s8 10 8 30" />
      <circle cx="100" cy="72" r="6" fill="#fff" />
    </>
  ),
  8: (
    <>
      <rect x="66" y="66" width="68" height="150" rx="16" fill="#fff" />
      <rect x="78" y="34" width="44" height="32" rx="6" fill="#fff" />
      <path d="M66 110h68M66 176h68" opacity="0.35" />
      <path d="M86 46h28" strokeWidth="4" />
    </>
  ),
  9: (
    <>
      <rect x="40" y="80" width="120" height="90" rx="20" fill="#fff" />
      {Array.from({ length: 5 }, (_, r) =>
        Array.from({ length: 8 }, (_, c) => (
          <circle key={`${r}-${c}`} cx={62 + c * 11} cy={106 + r * 11} r="2.4" fill="currentColor" stroke="none" opacity="0.7" />
        ))
      )}
      <path d="M70 80V64h60v16" />
      <path d="M90 64v-20" />
    </>
  ),
  10: (
    <>
      <ellipse cx="100" cy="126" rx="62" ry="50" fill="#fff" />
      <ellipse cx="100" cy="126" rx="40" ry="30" fill="#fff" />
      <path d="M62 140c20 14 56 14 76 0" opacity="0.4" />
      <circle cx="100" cy="88" r="2.5" fill="currentColor" stroke="none" />
      <circle cx="120" cy="90" r="2.5" fill="currentColor" stroke="none" />
      <circle cx="80" cy="90" r="2.5" fill="currentColor" stroke="none" />
    </>
  ),
  11: (
    <>
      <rect x="60" y="40" width="80" height="170" rx="30" fill="#fff" />
      <path d="M78 80v90M92 80v90M106 80v90M120 80v90" opacity="0.4" />
      <circle cx="100" cy="56" r="6" />
      <path d="M60 190h80" />
    </>
  ),
  12: (
    <>
      <path d="M100 60 28 190h144L100 60Z" fill="#fff" />
      <path d="M100 60v130" opacity="0.4" />
      <path d="M100 60 78 190h44L100 60Z" fill="#fff" />
      <path d="M22 190h156" />
      <path d="M100 60V40" />
    </>
  ),
  13: (
    <>
      <rect x="30" y="80" width="140" height="100" rx="6" fill="#fff" />
      <circle cx="86" cy="130" r="40" fill="#fff" />
      <circle cx="86" cy="130" r="26" opacity="0.45" />
      <circle cx="86" cy="130" r="5" fill="currentColor" stroke="none" />
      <circle cx="150" cy="100" r="8" fill="#fff" />
      <path d="M150 108l-22 42" />
      <rect x="120" y="148" width="14" height="6" rx="2" fill="currentColor" stroke="none" />
    </>
  ),
  14: (
    <>
      <path d="M30 116c0-24 20-24 40-20 20-4 40-4 60 0 20-4 40-4 40 20" />
      <rect x="36" y="100" width="56" height="40" rx="16" fill="#fff" />
      <rect x="108" y="100" width="56" height="40" rx="16" fill="#fff" />
      <path d="M92 116h16" />
      <path d="M36 110 20 150M164 110l16 40" />
    </>
  ),
  15: (
    <>
      <rect x="40" y="130" width="120" height="30" rx="10" fill="#fff" />
      <rect x="46" y="104" width="108" height="30" rx="10" fill="#fff" />
      <rect x="52" y="78" width="96" height="30" rx="10" fill="#fff" />
      <path d="M40 160v14M52 160v14M64 160v14M76 160v14M88 160v14M100 160v14M112 160v14M124 160v14M136 160v14M148 160v14M160 160v14" opacity="0.5" />
      <path d="M60 120h80M60 146h80" opacity="0.25" />
    </>
  ),
  16: (
    <>
      <circle cx="100" cy="130" r="42" fill="#fff" />
      <circle cx="100" cy="130" r="18" />
      <path d="M100 130V66m0 64 44 44m-44-44-44 44" />
      <path d="M100 100c-10-14 4-24 0-36 10 12 12 22 0 36Z" fill="currentColor" stroke="none" />
      <path d="M62 174h76" />
    </>
  ),
  17: (
    <>
      <rect x="72" y="36" width="56" height="96" rx="28" fill="#fff" />
      <path d="M84 60h32M84 76h32M84 92h32M84 108h32" opacity="0.4" />
      <path d="M100 132v50" />
      <path d="M60 204h80l-8-22H68l-8 22Z" fill="#fff" />
      <path d="M52 100c0 40 96 40 96 0" />
    </>
  ),
  18: (
    <>
      <path d="M20 130c40-40 120-40 160 0" />
      <path d="M20 160c40-40 120-40 160 0" />
      <rect x="66" y="98" width="68" height="50" rx="10" fill="#fff" />
      <path d="M66 112h68" />
      <circle cx="100" cy="132" r="4" fill="currentColor" stroke="none" />
    </>
  ),
  19: (
    <>
      <path d="M56 100h88v90a12 12 0 0 1-12 12H68a12 12 0 0 1-12-12v-90Z" fill="#fff" />
      <rect x="52" y="86" width="96" height="14" rx="4" fill="#fff" />
      <path d="M100 86V64" />
      <path d="M100 66c-10-12 2-22 0-32 8 10 10 20 0 32Z" fill="currentColor" stroke="none" />
      <path d="M72 140h56" opacity="0.3" />
    </>
  ),
  20: (
    <>
      <path d="M40 130c0-40 120-40 120 0s-120 40-120 0Z" fill="#fff" />
      <rect x="70" y="100" width="60" height="50" rx="10" fill="#fff" />
      <circle cx="100" cy="125" r="14" fill="#fff" />
      <circle cx="100" cy="125" r="6" fill="currentColor" stroke="none" />
      <path d="M100 72V56m30 26 12-12M70 82 58 70" opacity="0.5" />
    </>
  ),
  21: (
    <>
      <path d="M40 120c0-40 40-40 60-10s60 30 60 10-40-40-60-10-60 30-60 10Z" fill="none" />
      <path d="M40 132c0-40 40-40 60-10s60 30 60 10" opacity="0.4" />
      <rect x="28" y="106" width="26" height="14" rx="4" fill="#fff" />
      <rect x="146" y="106" width="26" height="14" rx="4" fill="#fff" />
      <path d="M60 170h80" strokeWidth="6" strokeLinecap="round" opacity="0.3" />
    </>
  ),
  22: (
    <>
      <path d="M20 130h160" strokeWidth="14" stroke="currentColor" opacity="0.15" />
      <path d="M20 123h160M20 137h160" />
      <rect x="70" y="106" width="60" height="48" rx="12" fill="#fff" />
      <path d="M82 130h10l6-12 8 24 6-12h6" strokeWidth="2.5" />
    </>
  ),
  23: (
    <>
      <path d="M66 46h68l-10 40H76l-10-40Z" fill="#fff" />
      <rect x="56" y="86" width="88" height="110" rx="10" fill="#fff" />
      <path d="M56 130h88" opacity="0.35" />
      <circle cx="100" cy="164" r="12" fill="#fff" />
      <path d="M100 152v12" />
      <rect x="70" y="86" width="60" height="16" fill="currentColor" stroke="none" opacity="0.15" />
    </>
  ),
  24: (
    <>
      <path d="M52 90c0-40 96-40 96 0v100a16 16 0 0 1-16 16H68a16 16 0 0 1-16-16V90Z" fill="#fff" />
      <path d="M60 66c10-18 70-18 80 0v20H60V66Z" fill="#fff" />
      <path d="M52 140h96" />
      <path d="M80 158h40v30H80z" fill="#fff" />
      <path d="M70 100v34M130 100v34" opacity="0.4" />
    </>
  ),
}

interface Props {
  product: Pick<Product, 'id' | 'hue' | 'name'>
  size?: 'card' | 'thumb' | 'line'
}

export function ProductArt({ product, size = 'card' }: Props) {
  const style = {
    '--tint': `hsl(${product.hue} 18% 91%)`,
    '--tint-deep': `hsl(${product.hue} 14% 84%)`,
  } as CSSProperties
  return (
    <div className={`art art-${size}`} style={style} aria-hidden="true">
      <svg viewBox="0 0 200 250" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round">
        <ellipse cx="100" cy="212" rx="64" ry="8" fill="var(--tint-deep)" stroke="none" />
        {ART[product.id]}
      </svg>
    </div>
  )
}
