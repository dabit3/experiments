import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** Test tally (12 passed / 3 failed) dissolves to the opened PR, ready to merge. */
export const FixAndPr: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const cut = Math.round(duration * 0.47);
  const xfade = 16;
  const b = interpolate(frame, [cut - xfade / 2, cut + xfade / 2], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const tally = SCREENS.web10;
  const pr = SCREENS.web9;

  return (
    <>
      {b < 1 ? (
        <MacroShot
          src={tally.src}
          imgWidth={tally.w}
          imgHeight={tally.h}
          from={{ x: 2330, y: 200, scale: 2.7 }}
          to={{ x: 2330, y: 215, scale: 2.95 }}
          moveDuration={cut + xfade}
          focus={{ x: 2250, y: 187 }}
          focusRadius={280}
          blur={12}
        />
      ) : null}
      {b > 0 ? (
        <MacroShot
          src={pr.src}
          imgWidth={pr.w}
          imgHeight={pr.h}
          from={{ x: 2250, y: 460, scale: 1.4 }}
          to={{ x: 2250, y: 500, scale: 1.5 }}
          moveDelay={cut - xfade / 2}
          moveDuration={duration - cut + xfade}
          focus={{ x: 2250, y: 500 }}
          focusRadius={380}
          blur={12}
          opacity={b}
        />
      ) : null}
      <Grade />
      <LowerThird
        label="04 · Fix & ship"
        text="Reproduces the bug. Fixes it. Re-runs the tests."
        from={10}
        duration={cut - 18}
      />
      <LowerThird
        label="04 · Fix & ship"
        text="Then opens the PR."
        from={cut + 6}
        duration={duration - cut - 6 - XFADE}
        exit={16}
      />
    </>
  );
};
