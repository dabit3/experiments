import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Module-level loads: Remotion's delayRender is handled internally by
// @remotion/google-fonts, so frames are not captured before the fonts resolve.
export const inter = loadInter("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

export const geistMono = loadGeistMono("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});
