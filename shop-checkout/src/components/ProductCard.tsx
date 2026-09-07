import { useState } from 'react'
import { colorSwatches, type Product } from '../data/products'
import { defaultSelection, formatMoney, type Selection } from '../lib/cart'
import { ProductArt } from './ProductArt'
import './ProductCard.css'

interface Props {
  product: Product
  onAdd: (product: Product, selection: Selection) => void
}

export function ProductCard({ product, onAdd }: Props) {
  const [selection, setSelection] = useState<Selection>(() => defaultSelection(product))
  const [justAdded, setJustAdded] = useState(false)

  const choose = (group: string, option: string) => setSelection((s) => ({ ...s, [group]: option }))

  const handleAdd = () => {
    onAdd(product, selection)
    setJustAdded(true)
    window.setTimeout(() => setJustAdded(false), 1200)
  }

  return (
    <article className="card" data-testid={`product-${product.id}`}>
      <div className="card__art">
        <ProductArt product={product} selection={selection} />
      </div>
      <div className="card__body">
        <div className="card__heading">
          <div>
            <h3 className="card__name">{product.name}</h3>
            <p className="card__tagline">{product.tagline}</p>
          </div>
          <span className="card__price">{formatMoney(product.price)}</span>
        </div>

        {product.variants.map((group) => (
          <div className="card__variant" key={group.name} role="group" aria-label={group.name}>
            <span className="card__variant-label">
              {group.name}: <strong>{selection[group.name]}</strong>
            </span>
            <div className="card__options">
              {group.options.map((option) => {
                const swatch = colorSwatches[option]
                const active = selection[group.name] === option
                return (
                  <button
                    key={option}
                    type="button"
                    title={option}
                    aria-label={`${group.name} ${option}`}
                    aria-pressed={active}
                    className={swatch ? 'swatch' : 'pill'}
                    style={swatch ? { background: swatch } : undefined}
                    onClick={() => choose(group.name, option)}
                  >
                    {swatch ? null : option}
                  </button>
                )
              })}
            </div>
          </div>
        ))}

        <button type="button" className={`btn btn--primary card__add${justAdded ? ' is-added' : ''}`} onClick={handleAdd}>
          {justAdded ? 'Added ✓' : 'Add to cart'}
        </button>
      </div>
    </article>
  )
}
