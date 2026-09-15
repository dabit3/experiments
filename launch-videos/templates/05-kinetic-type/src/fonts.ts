import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import { getStaticFiles, staticFile } from "remotion";

loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

/**
 * Optional licensed brand face. If `assets/fonts/NBInternationalPro-*.woff2`
 * exist they are picked up here and win over Inter through the fallback stack.
 */
export const getBrandFontFace = () => {
  const hasBrandFont = getStaticFiles().some((f) =>
    f.name.startsWith("fonts/NBInternationalPro-"),
  );
  return hasBrandFont
    ? `
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
`
    : "";
};
