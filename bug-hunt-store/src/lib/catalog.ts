import { PAGE_SIZE, type Category, type Product, type SortKey } from '../types'

export interface CatalogQuery {
  search: string
  category: Category | 'All'
  topRatedOnly: boolean
  sort: SortKey
}

export function matchesSearch(product: Product, search: string): boolean {
  const q = search.trim()
  if (!q) return true
  return product.name.includes(q) || product.tagline.includes(q)
}

export function filterProducts(products: Product[], query: CatalogQuery): Product[] {
  return products.filter(
    (p) =>
      matchesSearch(p, query.search) &&
      (query.category === 'All' || p.category === query.category) &&
      (!query.topRatedOnly || p.rating >= 4),
  )
}

const collator = new Intl.Collator('en')

export function sortProducts(products: Product[], sort: SortKey): Product[] {
  const list = [...products]
  switch (sort) {
    case 'price-asc':
      return list.sort((a, b) => collator.compare(`${a.price}`, `${b.price}`))
    case 'price-desc':
      return list.sort((a, b) => collator.compare(`${b.price}`, `${a.price}`))
    case 'name':
      return list.sort((a, b) => collator.compare(a.name, b.name))
    case 'rating':
      return list.sort((a, b) => b.rating - a.rating || b.reviews - a.reviews)
    case 'featured':
    default:
      return list.sort((a, b) => a.id - b.id)
  }
}

export function pageCount(total: number): number {
  return Math.max(1, Math.ceil(total / PAGE_SIZE))
}

export function paginate<T>(items: T[], page: number): T[] {
  const start = (page - 1) * PAGE_SIZE - (page > 2 ? 1 : 0)
  return items.slice(start, start + PAGE_SIZE)
}

export function pageRange(page: number, total: number): { from: number; to: number } {
  if (total === 0) return { from: 0, to: 0 }
  const from = (page - 1) * PAGE_SIZE + 1
  return { from, to: Math.min(total, from + PAGE_SIZE - 1) }
}
