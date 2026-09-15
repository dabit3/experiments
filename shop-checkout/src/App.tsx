import { useEffect, useState } from 'react'
import { CartDrawer } from './components/CartDrawer'
import { Checkout } from './components/checkout/Checkout'
import { Confirmation } from './components/checkout/Confirmation'
import { ProductCard } from './components/ProductCard'
import { products, type Product } from './data/products'
import { useCart } from './hooks/useCart'
import type { Selection } from './lib/cart'
import type { Order } from './lib/order'
import './App.css'

type View = { name: 'shop' } | { name: 'checkout' } | { name: 'confirmation'; order: Order }

export default function App() {
  const cart = useCart()
  const [view, setView] = useState<View>({ name: 'shop' })
  const [cartOpen, setCartOpen] = useState(false)
  const [toast, setToast] = useState<string | null>(null)

  useEffect(() => {
    if (!toast) return
    const t = window.setTimeout(() => setToast(null), 2200)
    return () => window.clearTimeout(t)
  }, [toast])

  useEffect(() => {
    window.scrollTo({ top: 0 })
  }, [view.name])

  const handleAdd = (product: Product, selection: Selection) => {
    cart.addItem(product, selection)
    const variant = product.variants.map((v) => selection[v.name]).join(' · ')
    setToast(`${product.name} (${variant}) added to cart`)
  }

  const startCheckout = () => {
    setCartOpen(false)
    setView({ name: 'checkout' })
  }

  const handleOrderPlaced = (order: Order) => {
    cart.clear()
    setView({ name: 'confirmation', order })
  }

  return (
    <div className="app">
      <header className="topbar">
        <button type="button" className="brand" onClick={() => setView({ name: 'shop' })}>
          <span className="brand__mark" aria-hidden />
          Northwind Goods
        </button>
        {view.name === 'shop' && (
          <button type="button" className="cart-btn" onClick={() => setCartOpen(true)} aria-label={`Open cart, ${cart.count} items`}>
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="M6 6h15l-1.5 9h-12z" />
              <path d="M6 6 5 3H2" />
              <circle cx="9" cy="20" r="1.5" />
              <circle cx="18" cy="20" r="1.5" />
            </svg>
            Cart
            <span className={`cart-btn__count${cart.count ? ' is-visible' : ''}`} data-testid="cart-count" key={cart.count}>
              {cart.count}
            </span>
          </button>
        )}
        {view.name === 'checkout' && <span className="topbar__secure">Secure checkout</span>}
      </header>

      {view.name === 'shop' && (
        <main className="shop">
          <section className="hero">
            <p className="hero__eyebrow">New season</p>
            <h1>Everyday essentials, made to last.</h1>
            <p className="hero__sub">
              Free shipping on every order. Use code <code>DEVIN20</code> for 20% off.
            </p>
          </section>
          <section className="grid" aria-label="Products">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} onAdd={handleAdd} />
            ))}
          </section>
        </main>
      )}

      {view.name === 'checkout' && (
        <Checkout cart={cart} onBackToShop={() => setView({ name: 'shop' })} onOrderPlaced={handleOrderPlaced} />
      )}

      {view.name === 'confirmation' && <Confirmation order={view.order} onContinue={() => setView({ name: 'shop' })} />}

      <CartDrawer cart={cart} open={cartOpen} onClose={() => setCartOpen(false)} onCheckout={startCheckout} />

      <div className={`toast${toast ? ' is-visible' : ''}`} role="status" aria-live="polite">
        {toast}
      </div>
    </div>
  )
}
