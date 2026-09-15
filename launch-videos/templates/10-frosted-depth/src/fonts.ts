import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Module-level loads: Remotion's google-fonts helper wraps these in delayRender/continueRender,
// so text is guaranteed to be rendered with the right face in the final MP4.
export const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
export const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
