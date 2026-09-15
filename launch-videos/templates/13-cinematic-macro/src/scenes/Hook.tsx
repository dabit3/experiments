import React from "react";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** Extreme close-up on the macOS platform chip of the new-session screen. */
export const Hook: React.FC<{ duration: number }> = ({ duration }) => {
  const s = SCREENS.web1;
  const chip = { x: 760, y: 977 };
  return (
    <>
      <MacroShot
        src={s.src}
        imgWidth={s.w}
        imgHeight={s.h}
        from={{ ...chip, scale: 3.3 }}
        to={{ ...chip, scale: 3.75 }}
        moveDuration={duration}
        focusRadius={230}
        blur={16}
      />
      <Grade />
      <LowerThird text="Devin now runs on Mac." from={22} duration={duration - 22 - XFADE} exit={16} />
    </>
  );
};
