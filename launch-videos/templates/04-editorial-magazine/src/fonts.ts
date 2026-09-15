import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Deterministic fallbacks for NB International Pro / Geist Mono. Both are loaded
// eagerly so every frame renders with the same metrics.
export const inter = loadInter("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

export const geistMono = loadGeistMono("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});
