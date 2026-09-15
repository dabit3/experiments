import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const fontsReady = Promise.all([inter.waitUntilDone(), geistMono.waitUntilDone()]);
