import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Inter is the deterministic fallback for NB International Pro; Geist Mono for
// mono eyebrows. Drop licensed NBInternationalPro-*.woff2 files into
// launch-videos/assets/fonts/ and they are picked up by the @font-face rules
// in nbInternationalFontFace().
loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const nbInternationalFontFace = (base: (p: string) => string) => `
@font-face {
  font-family: "NB International Pro";
  font-weight: 400;
  src: url("${base("fonts/NBInternationalPro-Regular.woff2")}") format("woff2");
}
@font-face {
  font-family: "NB International Pro";
  font-weight: 500;
  src: url("${base("fonts/NBInternationalPro-Medium.woff2")}") format("woff2");
}
`;
