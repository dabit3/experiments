import { useEffect, useMemo, useState } from 'react'
import { PRODUCTS } from './data/products'
import { useLocalStorage } from './hooks/useLocalStorage'
import { useWindowResized } from './hooks/useWindowResized'
import { addToCart, itemCount, removeLine, setQty } from './lib/cart'
import { filterProducts, pageCount, paginate, sortProducts, type CatalogQuery } from './lib/catalog'
import { TOTAL_BUGS, type CartLine, type Product } from './types'
import { BugReporter } from './components/BugReporter'
import { CartDrawer } from './components/CartDrawer'
import { CheckoutModal } from './components/CheckoutModal'
import { Header } from './components/Header'
import { HeroScreen } from './components/HeroScreen'
import { Pagination } from './components/Pagination'
import { ProductCard } from './components/ProductCard'
import { Scoreboard } from './components/Scoreboard'
import { Toolbar } from './components/Toolbar'
import './App.css'

const DEFAULT_QUERY: CatalogQuery = { search: '', category: 'All', topRatedOnly: false, sort: 'featured' }

export default function App() {
  const [query, setQuery] = useState<CatalogQuery>(DEFAULT_QUERY)
  const [page, setPage] = useState(1)
  const [cart, setCart] = useLocalStorage<CartLine[]>('bug-hunt.cart', [])
  const [found, setFound] = useLocalStorage<string[]>('bug-hunt.found', [])
  const [cartOpen, setCartOpen] = useState(false)
  const [checkoutOpen, setCheckoutOpen] = useState(false)
  const [scoreboardOpen, setScoreboardOpen] = useState(false)
  const [toast, setToast] = useState<string | null>(null)
  const dealRevealed = useWindowResized()

  const results = useMemo(() => sortProducts(filterProducts(PRODUCTS, query), query.sort), [query])
  const pages = pageCount(results.length)
  const currentPage = Math.min(page, pages)
  const visible = useMemo(() => paginate(results, currentPage), [results, currentPage])

  useEffect(() => {
    if (!toast) return
    const id = window.setTimeout(() => setToast(null), 2200)
    return () => window.clearTimeout(id)
  }, [toast])

  const updateQuery = (patch: Partial<CatalogQuery>) => {
    setQuery((q) => ({ ...q, ...patch }))
    setPage(1)
  }

  const handleAdd = (product: Product) => {
    setCart((lines) => addToCart(lines, product))
    setToast(`${product.name} added to cart`)
  }

  const markFound = (bugId: string) => {
    setFound((ids) => (ids.includes(bugId) ? ids : [...ids, bugId]))
  }

  const resetHunt = () => {
    setFound([])
    setScoreboardOpen(false)
  }

  const cartCount = itemCount(cart)
  const allFound = found.length >= TOTAL_BUGS

  return (
    <div className={cartOpen ? 'app cart-open' : 'app'}>
      <Header
        search={query.search}
        cartCount={cartCount}
        bugsFound={found.length}
        onSearch={(search) => updateQuery({ search })}
        onOpenCart={() => setCartOpen(true)}
        onOpenScoreboard={() => setScoreboardOpen(true)}
      />

      <div className="promo">
        Autumn sale — use code <strong>SAVE10</strong> for 10% off your order at checkout · Free shipping over $100
      </div>

      <main className="main">
        <Toolbar query={query} resultCount={results.length} onChange={updateQuery} />

        {visible.length === 0 ? (
          <div className="empty">
            <h2>No products match “{query.search}”</h2>
            <p className="muted">Try a different search or clear the filters.</p>
            <button type="button" className="btn btn-ghost" onClick={() => updateQuery(DEFAULT_QUERY)}>
              Clear everything
            </button>
          </div>
        ) : (
          <section className="grid" aria-label="Products">
            {visible.map((product) => (
              <ProductCard
                key={product.id}
                product={product}
                inCart={cart.find((l) => l.product.id === product.id)?.qty ?? 0}
                dealRevealed={dealRevealed}
                onAdd={handleAdd}
              />
            ))}
          </section>
        )}

        <Pagination page={currentPage} pages={pages} total={results.length} onChange={setPage} />
      </main>

      <CartDrawer
        open={cartOpen}
        lines={cart}
        onClose={() => setCartOpen(false)}
        onSetQty={(id, qty) => setCart((lines) => setQty(lines, id, qty))}
        onRemove={(line) => setCart((lines) => removeLine(lines, line))}
        onCheckout={() => {
          setCartOpen(false)
          setCheckoutOpen(true)
        }}
      />

      {checkoutOpen && (
        <CheckoutModal lines={cart} onClose={() => setCheckoutOpen(false)} onPlaceOrder={() => setCart([])} />
      )}

      {scoreboardOpen && <Scoreboard found={found} onClose={() => setScoreboardOpen(false)} onReset={resetHunt} />}

      <BugReporter found={found} onFound={markFound} />

      {allFound && <HeroScreen onReset={resetHunt} />}

      <div className={`toast ${toast ? 'toast-show' : ''}`} role="status" aria-live="polite">
        {toast}
      </div>
    </div>
  )
}
