import type { Product } from '../types'
import { money } from '../lib/format'
import { ProductArt } from './ProductArt'
import { Stars } from './Stars'

interface Props {
  product: Product
  inCart: number
  dealRevealed: boolean
  onAdd: (product: Product) => void
}

export function ProductCard({ product, inCart, dealRevealed, onAdd }: Props) {
  return (
    <article className="card" data-product-id={product.id}>
      <ProductArt category={product.category} hue={product.hue} />
      <div className="card-body">
        <div className="card-meta">
          <span className="chip chip-soft">{product.category}</span>
          <Stars rating={product.rating} reviews={product.reviews} />
        </div>
        <h3 className="card-title">{product.name}</h3>
        <p className="card-tagline">{product.tagline}</p>
      </div>
      <footer className="card-footer">
        <span className="price">{money(product.price)}</span>
        <button type="button" className="btn btn-primary" onClick={() => onAdd(product)}>
          {inCart > 0 ? `Add another (${inCart})` : 'Add to cart'}
        </button>
        {product.featured && (
          <div className={`deal ${dealRevealed ? 'deal-revealed' : ''}`}>
            <span className="deal-badge">Deal of the day</span>
          </div>
        )}
      </footer>
    </article>
  )
}
