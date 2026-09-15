import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Loaded at module level so Remotion's delayRender handle blocks the first
// frame until both faces are available.
export const inter = loadInter("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

export const geistMono = loadGeistMono("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});
