# shop-checkout — Multi-step e-commerce checkout

A small online store built with Vite + React + TypeScript. Nine products with generated SVG artwork and size/color variant pickers, a slide-out cart with quantity steppers and a promo-code field (`DEVIN20` = 20% off), and a three-step checkout wizard (Shipping → Payment → Review) with realistic inline validation: required fields, email and ZIP format, Luhn card-number check with auto-spacing every 4 digits, MM/YY expiry that must be in the future, and a 3-digit CVV. Placing the order clears the cart and shows a confirmation page with a generated order number.

## Run it

```bash
cd shop-checkout
npm install
npm run dev
```

Then open the URL Vite prints (default http://localhost:5173).

## Computer-use showcase

_Recording and screenshots are added after the browser run._
