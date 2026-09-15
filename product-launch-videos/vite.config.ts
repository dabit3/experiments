import {defineConfig} from 'vite';

export default defineConfig({
  base: './',
  publicDir: 'public',
  build: {
    copyPublicDir: false,
    assetsInlineLimit: 0,
    rollupOptions: {output: {format: 'iife', name: 'LaunchGallery', inlineDynamicImports: true}},
  },
  server: {port: 5173, strictPort: true},
});
