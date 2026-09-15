import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import { staticFile } from "remotion";
import type { Brand } from "./schema";

// Inter is the deterministic fallback for NB International Pro; Geist Mono for mono.
loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

// If licensed NB International Pro files are dropped into launch-videos/assets/fonts/ and
// listed in brand.licensedFontFiles, this @font-face hook makes brand.fontFamily use them.
export const licensedFontFace = (brand: Brand): string => {
  const f = brand.licensedFontFiles;
  if (!f) {
    return "";
  }
  return `
@font-face { font-family: "NB International Pro"; font-weight: 400; src: url("${staticFile(f.regular)}") format("woff2"); }
@font-face { font-family: "NB International Pro"; font-weight: 500; src: url("${staticFile(f.medium)}") format("woff2"); }
`;
};
