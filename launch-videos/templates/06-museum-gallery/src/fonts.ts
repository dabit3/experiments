import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

// Inter is the deterministic fallback for NB International Pro; Geist Mono for mono.
// If a licensed NBInternationalPro-*.woff2 is dropped into launch-videos/assets/fonts/,
// the @font-face rule below picks it up because brand.fontFamily lists it first.
loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const nbInternationalFontFace = (resolve: (path: string) => string) => `
@font-face {
  font-family: "NB International Pro";
  font-weight: 400;
  src: url("${resolve("fonts/NBInternationalPro-Regular.woff2")}") format("woff2");
}
@font-face {
  font-family: "NB International Pro";
  font-weight: 500;
  src: url("${resolve("fonts/NBInternationalPro-Medium.woff2")}") format("woff2");
}
`;
