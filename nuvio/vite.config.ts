import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: './',
  plugins: [react()],
  build: {
    rollupOptions: {
      output: { manualChunks: { three: ['three', 'three/addons/controls/OrbitControls.js', 'three/addons/objects/Reflector.js', 'three/addons/environments/RoomEnvironment.js'] } },
    },
    chunkSizeWarningLimit: 750,
  },
});
