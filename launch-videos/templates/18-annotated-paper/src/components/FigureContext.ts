import { createContext } from "react";

export type FigureCtx = {
  /** Map normalised source-image coords to figure px. */
  toPx: (nx: number, ny: number) => { x: number; y: number };
  width: number;
  height: number;
  /** Image px per normalised unit. */
  scaleX: number;
  scaleY: number;
};

export const FigureContext = createContext<FigureCtx | null>(null);
