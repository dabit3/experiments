import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import { staticFile } from "remotion";
import type { Brand } from "./schema";

loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

/**
 * Optional licensed brand face. When `brand.brandFontFiles` points at woff2
 * files under the shared assets dir they are registered here; otherwise the
 * font stack falls through to Inter, which is always loaded above.
 */
export const brandFontFace = (brand: Brand) => {
  const files = brand.brandFontFiles;
  if (!files) return "";
  const face = (weight: number, file: string) => `
@font-face {
  font-family: "NB International Pro";
  font-weight: ${weight};
  font-display: swap;
  src: url("${staticFile(file)}") format("woff2");
}`;
  return face(400, files.regular) + face(500, files.medium);
};
