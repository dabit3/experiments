export type ArtKind =
  | 'hoodie'
  | 'sneaker'
  | 'headphones'
  | 'watch'
  | 'backpack'
  | 'bottle'
  | 'mug'
  | 'sunglasses'
  | 'tee'

export interface VariantGroup {
  name: string
  options: string[]
}

export interface Product {
  id: string
  name: string
  tagline: string
  price: number
  art: ArtKind
  variants: VariantGroup[]
}

/** Hex fills used both for swatch dots and to tint the generated artwork. */
export const colorSwatches: Record<string, string> = {
  Charcoal: '#3b3f46',
  Sky: '#6fb6ff',
  Rose: '#f28ca6',
  White: '#f4f4f2',
  Black: '#1d1f24',
  Midnight: '#243055',
  Sand: '#d9c3a3',
  Silver: '#c9ced6',
  Graphite: '#565b66',
  Olive: '#7c8b4f',
  Navy: '#2c3e6b',
  Rust: '#b95b3a',
  Teal: '#2c9d9a',
  Coral: '#ff7a5c',
  Cream: '#f3e9d6',
  Slate: '#6b7a8c',
  Tortoise: '#8a5a2b',
  Sage: '#a8bfa0',
}

export const products: Product[] = [
  {
    id: 'aurora-hoodie',
    name: 'Aurora Hoodie',
    tagline: 'Brushed fleece, relaxed fit',
    price: 68,
    art: 'hoodie',
    variants: [
      { name: 'Size', options: ['S', 'M', 'L', 'XL'] },
      { name: 'Color', options: ['Charcoal', 'Sky', 'Rose'] },
    ],
  },
  {
    id: 'drift-sneakers',
    name: 'Drift Sneakers',
    tagline: 'Featherweight knit runner',
    price: 120,
    art: 'sneaker',
    variants: [
      { name: 'Size', options: ['8', '9', '10', '11'] },
      { name: 'Color', options: ['White', 'Black'] },
    ],
  },
  {
    id: 'echo-headphones',
    name: 'Echo Headphones',
    tagline: '40h battery, active noise cancelling',
    price: 199,
    art: 'headphones',
    variants: [{ name: 'Color', options: ['Midnight', 'Sand'] }],
  },
  {
    id: 'orbit-watch',
    name: 'Orbit Watch',
    tagline: 'Sapphire glass, 5 ATM',
    price: 249,
    art: 'watch',
    variants: [
      { name: 'Case', options: ['Silver', 'Graphite'] },
      { name: 'Band', options: ['Leather', 'Steel'] },
    ],
  },
  {
    id: 'trail-backpack',
    name: 'Trail Backpack',
    tagline: '24L, weatherproof canvas',
    price: 89,
    art: 'backpack',
    variants: [{ name: 'Color', options: ['Olive', 'Navy', 'Rust'] }],
  },
  {
    id: 'summit-bottle',
    name: 'Summit Bottle',
    tagline: 'Insulated steel, keeps cold 24h',
    price: 32,
    art: 'bottle',
    variants: [
      { name: 'Size', options: ['500 ml', '750 ml'] },
      { name: 'Color', options: ['Teal', 'Coral'] },
    ],
  },
  {
    id: 'ember-mug',
    name: 'Ember Mug',
    tagline: 'Hand-glazed stoneware, 12 oz',
    price: 24,
    art: 'mug',
    variants: [{ name: 'Color', options: ['Cream', 'Slate'] }],
  },
  {
    id: 'solstice-sunglasses',
    name: 'Solstice Sunglasses',
    tagline: 'Polarized, acetate frame',
    price: 140,
    art: 'sunglasses',
    variants: [{ name: 'Frame', options: ['Tortoise', 'Black'] }],
  },
  {
    id: 'loft-tee',
    name: 'Loft Tee',
    tagline: 'Heavyweight organic cotton',
    price: 28,
    art: 'tee',
    variants: [
      { name: 'Size', options: ['S', 'M', 'L'] },
      { name: 'Color', options: ['White', 'Black', 'Sage'] },
    ],
  },
]

export const PROMO_CODES: Record<string, number> = {
  DEVIN20: 0.2,
}
