import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import { staticFile } from "remotion";

loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

// Licensed NB International Pro is picked up automatically when the woff2 files are
// dropped into launch-videos/assets/fonts/. Missing files fall back to Inter.
export const brandFontFaceCss = `
@font-face {
  font-family: "NB International Pro";
  font-weight: 400;
  src: url("${staticFile("fonts/NBInternationalPro-Regular.woff2")}") format("woff2");
}
@font-face {
  font-family: "NB International Pro";
  font-weight: 500;
  src: url("${staticFile("fonts/NBInternationalPro-Medium.woff2")}") format("woff2");
}
`;
