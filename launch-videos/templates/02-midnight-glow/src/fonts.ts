import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

const inter = loadInter("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

const geistMono = loadGeistMono("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

export const SANS = `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`;
export const MONO = `${geistMono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`;
