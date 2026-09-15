import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand } from "../schema";

type Props = {
  brand: Brand;
  on: "light" | "dark";
  height: number;
  style?: React.CSSProperties;
};

/** Devin lockup. Only ever faded/slid as a whole; geometry is never touched. */
export const Logo: React.FC<Props> = ({ brand, on, height, style }) => (
  <Img
    src={staticFile(on === "light" ? brand.logoLight : brand.logoDark)}
    style={{ height, width: "auto", display: "block", ...style }}
  />
);
