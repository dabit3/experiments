import React from "react";
import { SceneFrame } from "../components/SceneFrame";
import { ScreenCard, Shot } from "../components/ScreenCard";
import { Line, Narration } from "../components/Narration";

type Props = {
  sceneFrom: number;
  shots: Shot[];
  lines: Line[];
  /** True when the next scene is another Feature: the card holds while the next one dissolves over it. */
  holdCard?: boolean;
  /** True when the previous scene was a Feature: the card dissolves in place instead of rising. */
  continues?: boolean;
};

/** Shared layout for the four "product in action" moments: front-layer screen card, one narration line below. */
export const Feature: React.FC<Props> = ({ sceneFrom, shots, lines, holdCard = false, continues = false }) => (
  <>
    <SceneFrame fadeOut={!holdCard}>
      <ScreenCard shots={shots} sceneFrom={sceneFrom} rise={continues ? 0 : 40} />
    </SceneFrame>
    <SceneFrame>
      <Narration x={120} y={896} width={1680} align="center" lines={lines} />
    </SceneFrame>
  </>
);
