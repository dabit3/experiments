import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Module-level loads: @remotion/google-fonts wraps these in delayRender so
// text is never rasterised before the face is available.
export const inter = loadInter("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

export const geistMono = loadGeistMono("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});
