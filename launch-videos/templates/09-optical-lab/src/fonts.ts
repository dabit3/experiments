import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

let loaded = false;

/** Loads the deterministic fallbacks (Inter, Geist Mono) once per bundle. */
export const ensureFonts = () => {
  if (loaded) {
    return;
  }
  loaded = true;
  loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
  loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
};

export const SANS_STACK =
  '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif';
export const MONO_STACK =
  '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace';
