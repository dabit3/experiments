import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

/**
 * Deterministic fallbacks for NB International Pro / Geist Mono. The brand
 * families come first in the `fontFamily` props; if a licensed NB
 * International Pro is installed on the render machine it is used, otherwise
 * the browser falls through to Inter.
 */
export const loadFonts = () => {
  loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
  loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
};
