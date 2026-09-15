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
      <ProductArt product={product} />
      <div className="card-body">
        <span className="card-category">{product.category}</span>
        <h3 className="card-title">{product.name}</h3>
        <p className="card-tagline">{product.tagline}</p>
        <div className="card-meta">
          <Stars rating={product.rating} reviews={product.reviews} />
          <span className="price">{money(product.price)}</span>
        </div>
      </div>
      <footer className="card-footer">
        <button type="button" className="btn btn-primary btn-block" onClick={() => onAdd(product)}>
          {inCart > 0 ? `Add another · ${inCart} in bag` : 'Add to bag'}
        </button>
        {product.featured && (
          <div className={`deal ${dealRevealed ? 'deal-revealed' : ''}`}>
            <span className="deal-badge">Editor's pick</span>
          </div>
        )}
      </footer>
    </article>
  )
}
