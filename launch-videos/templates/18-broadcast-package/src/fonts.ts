import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Inter is the deterministic fallback for NB International Pro; Geist Mono for mono.
// Licensed NB International Pro files are wired in via brand.fontFaceCss (see README).
loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

/** Ready-made @font-face block for assets/fonts/NBInternationalPro-{Regular,Medium}.woff2. */
export const NB_INTERNATIONAL_PRO_FONT_FACE = `
@font-face {
  font-family: "NB International Pro";
  font-weight: 400;
  src: url("fonts/NBInternationalPro-Regular.woff2") format("woff2");
}
@font-face {
  font-family: "NB International Pro";
  font-weight: 500;
  src: url("fonts/NBInternationalPro-Medium.woff2") format("woff2");
}
`;
