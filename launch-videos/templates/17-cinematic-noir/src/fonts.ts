import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Inter is the deterministic fallback for NB International Pro. If a licensed
// NBInternationalPro-*.woff2 is dropped into launch-videos/assets/fonts/, the
// @font-face rules in Root.tsx pick it up automatically because the brand
// fontFamily stack lists "NB International Pro" first.
loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
