import { useId, type ReactElement } from 'react'
import { colorSwatches, type ArtKind, type Product } from '../data/products'
import type { Selection } from '../lib/cart'

interface Props {
  product: Product
  selection: Selection
  className?: string
}

/** Generated SVG artwork for a product; the main fill follows the chosen color variant. */
export function ProductArt({ product, selection, className }: Props) {
  const tint = tintFor(product, selection)
  const outline = isLight(tint) ? '#2b2f36' : '#ffffff'
  const gradientId = useId()

  return (
    <svg viewBox="0 0 200 200" className={className} role="img" aria-label={product.name}>
      <defs>
        <linearGradient id={gradientId} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={mix(tint, '#ffffff', 0.7)} />
          <stop offset="100%" stopColor={mix(tint, '#ffffff', 0.35)} />
        </linearGradient>
      </defs>
      <rect width="200" height="200" fill={`url(#${gradientId})`} />
      <circle cx="150" cy="40" r="60" fill={tint} opacity="0.12" />
      <circle cx="40" cy="170" r="40" fill={tint} opacity="0.1" />
      <g fill={tint} stroke={outline} strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round">
        {shapes[product.art]({ tint, outline })}
      </g>
    </svg>
  )
}

interface ShapeProps {
  tint: string
  outline: string
}

const shapes: Record<ArtKind, (p: ShapeProps) => ReactElement> = {
  hoodie: ({ outline }) => (
    <>
      <path d="M64 72 L36 84 L28 130 L54 135 L58 170 L142 170 L146 135 L172 130 L164 84 L136 72 Q100 62 64 72 Z" />
      <path d="M68 74 Q66 34 100 32 Q134 34 132 74 Q118 66 100 68 Q82 66 68 74 Z" />
      <ellipse cx="100" cy="72" rx="16" ry="7" fill={outline} opacity="0.8" stroke="none" />
      <path d="M93 80 L90 108 M107 80 L110 108" />
      <rect x="78" y="132" width="44" height="26" rx="7" fill="none" />
    </>
  ),
  sneaker: () => (
    <>
      <path d="M30 130 Q35 105 70 100 L110 75 Q130 100 165 110 Q180 118 175 135 L30 135 Z" />
      <path d="M30 135 L175 135 Q178 150 160 150 L40 150 Q28 148 30 135 Z" fill="#ffffff" opacity="0.9" />
      <path d="M80 100 L92 112 M95 92 L108 105 M110 84 L124 100" fill="none" />
      <path d="M45 118 Q70 112 95 122" fill="none" />
    </>
  ),
  headphones: ({ tint }) => (
    <>
      <path d="M50 120 L50 95 Q50 45 100 45 Q150 45 150 95 L150 120" fill="none" strokeWidth="9" stroke={tint} />
      <path d="M50 120 L50 95 Q50 45 100 45 Q150 45 150 95 L150 120" fill="none" />
      <rect x="35" y="105" width="30" height="50" rx="10" />
      <rect x="135" y="105" width="30" height="50" rx="10" />
      <rect x="43" y="115" width="14" height="30" rx="6" fill="#ffffff" opacity="0.7" stroke="none" />
      <rect x="143" y="115" width="14" height="30" rx="6" fill="#ffffff" opacity="0.7" stroke="none" />
    </>
  ),
  watch: ({ tint }) => (
    <>
      <path d="M78 30 L122 30 L128 65 L72 65 Z" fill={mix(tint, '#000000', 0.25)} />
      <path d="M78 170 L122 170 L128 135 L72 135 Z" fill={mix(tint, '#000000', 0.25)} />
      <circle cx="100" cy="100" r="42" />
      <circle cx="100" cy="100" r="33" fill="#ffffff" opacity="0.92" stroke="none" />
      <path d="M100 100 L100 78 M100 100 L116 108" stroke="#1d1f24" strokeWidth="3" />
      <circle cx="100" cy="100" r="2.5" fill="#1d1f24" stroke="none" />
      <rect x="142" y="92" width="8" height="16" rx="2" />
    </>
  ),
  backpack: ({ outline }) => (
    <>
      <path d="M80 45 Q100 30 120 45 L120 60 L80 60 Z" fill="none" />
      <rect x="50" y="55" width="100" height="115" rx="26" />
      <rect x="65" y="110" width="70" height="45" rx="12" fill={outline} opacity="0.2" stroke="none" />
      <rect x="65" y="110" width="70" height="45" rx="12" fill="none" />
      <path d="M60 85 L140 85" />
      <rect x="88" y="120" width="24" height="8" rx="3" fill={outline} opacity="0.6" stroke="none" />
    </>
  ),
  bottle: () => (
    <>
      <rect x="86" y="30" width="28" height="18" rx="5" />
      <path d="M78 48 L122 48 L130 70 L130 165 Q130 175 120 175 L80 175 Q70 175 70 165 L70 70 Z" />
      <rect x="70" y="95" width="60" height="42" fill="#ffffff" opacity="0.85" stroke="none" />
      <path d="M70 95 L130 95 M70 137 L130 137" />
      <path d="M85 108 L115 108 M85 118 L108 118" stroke="#1d1f24" strokeWidth="2" opacity="0.5" />
    </>
  ),
  mug: () => (
    <>
      <path d="M60 70 L135 70 L130 160 Q130 170 120 170 L75 170 Q65 170 65 160 Z" />
      <path d="M135 85 Q170 85 168 115 Q166 145 132 145" fill="none" strokeWidth="9" />
      <ellipse cx="97" cy="70" rx="37" ry="9" fill="#ffffff" opacity="0.9" />
      <path d="M85 40 Q80 50 85 60 M100 35 Q95 47 100 58" fill="none" opacity="0.6" />
    </>
  ),
  sunglasses: ({ tint }) => (
    <>
      <path d="M25 90 L175 90" strokeWidth="5" />
      <path d="M30 90 Q30 130 60 132 Q90 132 92 100 L92 90 Z" />
      <path d="M170 90 Q170 130 140 132 Q110 132 108 100 L108 90 Z" />
      <path d="M40 98 Q50 100 60 120" fill="none" stroke="#ffffff" opacity="0.6" />
      <path d="M118 98 Q128 100 138 120" fill="none" stroke="#ffffff" opacity="0.6" />
      <path d="M92 92 Q100 82 108 92" fill="none" stroke={tint} strokeWidth="4" />
    </>
  ),
  tee: ({ outline }) => (
    <>
      <path d="M70 50 L35 70 L48 100 L65 92 L65 165 L135 165 L135 92 L152 100 L165 70 L130 50 Q100 70 70 50 Z" />
      <path d="M78 52 Q100 68 122 52" fill="none" />
      <circle cx="100" cy="115" r="16" fill={outline} opacity="0.15" stroke="none" />
    </>
  ),
}

function tintFor(product: Product, selection: Selection): string {
  for (const group of product.variants) {
    const swatch = colorSwatches[selection[group.name]]
    if (swatch) return swatch
  }
  return '#8a94a6'
}

function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.slice(1), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

function mix(a: string, b: string, amount: number): string {
  const [r1, g1, b1] = hexToRgb(a)
  const [r2, g2, b2] = hexToRgb(b)
  const ch = (x: number, y: number) => Math.round(x + (y - x) * amount)
  return `rgb(${ch(r1, r2)}, ${ch(g1, g2)}, ${ch(b1, b2)})`
}

function isLight(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex)
  return (r * 299 + g * 587 + b * 114) / 1000 > 165
}
