import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

/**
 * Deterministic fallbacks for the licensed brand faces. `brand.fontFamily` and
 * `brand.monoFontFamily` stay editable; if NB International Pro is available via
 * @font-face (see README) the browser picks it first.
 */
export const loadFonts = () => {
  loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
  loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
};
