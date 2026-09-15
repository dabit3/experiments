export type Category = 'Audio' | 'Wearables' | 'Home' | 'Outdoor'

export const CATEGORIES: Category[] = ['Audio', 'Wearables', 'Home', 'Outdoor']

export interface Product {
  id: number
  name: string
  category: Category
  price: number
  rating: number
  reviews: number
  tagline: string
  hue: number
  featured?: boolean
}

export interface CartLine {
  product: Product
  qty: number
}

export type SortKey = 'featured' | 'price-asc' | 'price-desc' | 'name' | 'rating'

export const SORT_OPTIONS: { value: SortKey; label: string }[] = [
  { value: 'featured', label: 'Featured' },
  { value: 'price-asc', label: 'Price: Low to High' },
  { value: 'price-desc', label: 'Price: High to Low' },
  { value: 'name', label: 'Name: A to Z' },
  { value: 'rating', label: 'Top rated' },
]

export interface BugDefinition {
  id: string
  title: string
  area: string
  keywords: string[][]
}

export const PAGE_SIZE = 8
export const TOTAL_BUGS = 8
