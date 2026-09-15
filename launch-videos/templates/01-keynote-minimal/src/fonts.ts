import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Loaded at module level so every frame waits on the fonts (delayRender under the hood).
const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const sans = `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`;
export const mono = `${geistMono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`;
