import React from "react";
import { staticFile } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import type { Brand } from "./schema";

// Inter is the deterministic fallback for NB International Pro; Geist Mono for mono.
loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

// Licensed fonts dropped into assets/fonts are declared through brand.fontFaces.
export const FontFaces: React.FC<{ faces: Brand["fontFaces"] }> = ({ faces }) => {
  if (faces.length === 0) {
    return null;
  }
  const css = faces
    .map(
      (f) =>
        `@font-face{font-family:"${f.family}";src:url("${staticFile(f.src)}") format("woff2");font-weight:${f.weight};font-display:block;}`,
    )
    .join("\n");
  return <style>{css}</style>;
};
