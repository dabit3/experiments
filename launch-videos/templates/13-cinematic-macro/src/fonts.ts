import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Loaded at module level; @remotion/google-fonts wraps this in delayRender/continueRender
// so the renderer waits for the font files before capturing frames.
const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geist = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const SANS = `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`;
export const MONO = `${geist.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`;
