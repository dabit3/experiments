import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** iPad Simulator dissolves to the dark PR review grid of iPhone screenshots. */
export const DeviceMatrix: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const cut = Math.round(duration * 0.5);
  const xfade = 16;
  const b = interpolate(frame, [cut - xfade / 2, cut + xfade / 2], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const ipad = SCREENS.web19;
  const grid = SCREENS.web17;

  return (
    <>
      {b < 1 ? (
        <MacroShot
          src={ipad.src}
          imgWidth={ipad.w}
          imgHeight={ipad.h}
          from={{ x: 974, y: 720, scale: 1.3 }}
          to={{ x: 974, y: 790, scale: 1.4 }}
          moveDuration={cut + xfade}
          focusRadius={400}
          blur={10}
        />
      ) : null}
      {b > 0 ? (
        <MacroShot
          src={grid.src}
          imgWidth={grid.w}
          imgHeight={grid.h}
          from={{ x: 1198, y: 830, scale: 1.12 }}
          to={{ x: 1198, y: 1060, scale: 1.2 }}
          moveDelay={cut - xfade / 2}
          moveDuration={duration - cut + xfade}
          focusRadius={520}
          blur={9}
          opacity={b}
        />
      ) : null}
      <Grade />
      <LowerThird
        label="05 · Every screen"
        text="iPhone and iPad. Light and dark."
        from={10}
        duration={cut - 18}
      />
      <LowerThird
        label="05 · Every screen"
        text="Screens compared pixel for pixel."
        from={cut + 6}
        duration={duration - cut - 6 - XFADE}
        exit={16}
      />
    </>
  );
};
