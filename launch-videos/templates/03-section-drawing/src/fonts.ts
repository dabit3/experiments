import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Inter is the deterministic fallback for NB International Pro (see README for the @font-face hook).
export const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
export const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
