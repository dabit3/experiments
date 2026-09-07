import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const serverPort = process.env.PORT ?? '3001'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: Number(process.env.WEB_PORT ?? 5173),
    strictPort: true,
    proxy: {
      '/ws': { target: `ws://127.0.0.1:${serverPort}`, ws: true },
    },
  },
})
