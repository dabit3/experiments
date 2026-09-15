import React from "react";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** Vertical dolly down the iPhone Simulator running the built app. */
export const BuildRun: React.FC<{ duration: number }> = ({ duration }) => {
  const s = SCREENS.desktop9;
  return (
    <>
      <MacroShot
        src={s.src}
        imgWidth={s.w}
        imgHeight={s.h}
        from={{ x: 1013, y: 640, scale: 1.75 }}
        to={{ x: 1013, y: 1180, scale: 1.95 }}
        moveDuration={duration}
        focusRadius={330}
        blur={12}
      />
      <Grade />
      <LowerThird
        label="02 · Build & run"
        text="Builds the app. Runs it in the Simulator."
        from={20}
        duration={duration - 20 - XFADE}
        exit={16}
      />
    </>
  );
};
