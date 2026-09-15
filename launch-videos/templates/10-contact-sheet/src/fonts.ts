import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Inter is the deterministic fallback for NB International Pro; Geist Mono for
// indices and metadata. Both resolve before the first frame is rendered.
const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const fontsReady = Promise.all([inter.waitUntilDone(), geistMono.waitUntilDone()]);
