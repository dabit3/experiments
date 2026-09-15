import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    // jspdf is a single large dependency; it is loaded once and cached.
    chunkSizeWarningLimit: 800,
  },
})
