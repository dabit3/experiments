import { useCallback, useMemo, useState } from 'react'
import type { Product } from '../data/products'
import { computeTotals, itemKey, lookupPromo, type CartItem, type Promo, type Selection } from '../lib/cart'

export type PromoStatus = { kind: 'idle' } | { kind: 'applied'; promo: Promo } | { kind: 'invalid'; code: string }

export function useCart() {
  const [items, setItems] = useState<CartItem[]>([])
  const [promoStatus, setPromoStatus] = useState<PromoStatus>({ kind: 'idle' })

  const promo = promoStatus.kind === 'applied' ? promoStatus.promo : null
  const totals = useMemo(() => computeTotals(items, promo), [items, promo])
  const count = items.reduce((n, i) => n + i.quantity, 0)

  const addItem = useCallback((product: Product, selection: Selection) => {
    const key = itemKey(product, selection)
    setItems((prev) => {
      const existing = prev.find((i) => i.key === key)
      if (existing) {
        return prev.map((i) => (i.key === key ? { ...i, quantity: i.quantity + 1 } : i))
      }
      return [...prev, { key, product, selection, quantity: 1 }]
    })
  }, [])

  const setQuantity = useCallback((key: string, quantity: number) => {
    setItems((prev) =>
      quantity <= 0 ? prev.filter((i) => i.key !== key) : prev.map((i) => (i.key === key ? { ...i, quantity } : i)),
    )
  }, [])

  const removeItem = useCallback((key: string) => setQuantity(key, 0), [setQuantity])

  const applyPromo = useCallback((code: string) => {
    const found = lookupPromo(code)
    setPromoStatus(found ? { kind: 'applied', promo: found } : { kind: 'invalid', code })
  }, [])

  const clearPromo = useCallback(() => setPromoStatus({ kind: 'idle' }), [])

  const clear = useCallback(() => {
    setItems([])
    setPromoStatus({ kind: 'idle' })
  }, [])

  return { items, count, totals, promo, promoStatus, addItem, setQuantity, removeItem, applyPromo, clearPromo, clear }
}

export type Cart = ReturnType<typeof useCart>
