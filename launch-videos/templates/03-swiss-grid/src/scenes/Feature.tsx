import React from "react";
import { HEIGHT } from "../scenes";
import { Scene } from "../components/Scene";
import { Line } from "../components/Text";
import { grid } from "../theme";

export const WEB_ASPECT = 2990 / 1624;
export const FIGURE_COL = 4;
export const FIGURE_SPAN = 8;
export const FIGURE_TOP = Math.round((HEIGHT - grid.span(FIGURE_SPAN) / WEB_ASPECT) / 2);

export type Beat = {
  text: string;
  enterAt: number;
  exitAt?: number;
};

type Props = {
  number: string;
  beats: Beat[];
  children: React.ReactNode;
};

/**
 * Feature layout: narration in columns 1–4, figure snapped to columns 5–12.
 * Beats replace each other so only one idea is on screen at a time.
 */
export const Feature: React.FC<Props> = ({ number, beats, children }) => (
  <Scene number={number} title="Product in action">
    <div style={{ position: "absolute", left: grid.x(0), top: FIGURE_TOP - 4, width: grid.span(4) }}>
      {beats.map((beat) => (
        <div key={beat.text} style={{ position: "absolute", top: 0, left: 0, width: grid.span(4) }}>
          <Line size="text" enterAt={beat.enterAt} exitAt={beat.exitAt}>
            {beat.text}
          </Line>
        </div>
      ))}
    </div>
    {children}
  </Scene>
);
