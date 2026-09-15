import {defineConfig} from 'vite';

export default defineConfig({
  publicDir: 'public',
  build: {copyPublicDir: false},
  server: {port: 5173, strictPort: true},
});
