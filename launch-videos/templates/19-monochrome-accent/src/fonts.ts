import { loadFont as loadSpaceGrotesk } from "@remotion/google-fonts/SpaceGrotesk";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

const grotesk = loadSpaceGrotesk("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});
const mono = loadGeistMono("normal", {
  weights: ["400", "500"],
  subsets: ["latin"],
});

export const SANS = `${grotesk.fontFamily}, Inter, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`;
export const MONO = `${mono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`;
