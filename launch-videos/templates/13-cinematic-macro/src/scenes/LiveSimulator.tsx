import React from "react";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** Push in on the live Simulator player until the "typing..." indicator and cursor fill the frame. */
export const LiveSimulator: React.FC<{ duration: number }> = ({ duration }) => {
  const s = SCREENS.web10;
  const half = Math.round(duration / 2);
  return (
    <>
      <MacroShot
        src={s.src}
        imgWidth={s.w}
        imgHeight={s.h}
        from={{ x: 990, y: 1140, scale: 1.7 }}
        to={{ x: 1010, y: 1240, scale: 2.3 }}
        moveDuration={duration}
        focus={{ x: 1010, y: 1270 }}
        focusRadius={300}
        blur={13}
      />
      <Grade />
      <LowerThird
        label="03 · Live Simulator"
        text="A live iPhone Simulator, inside the session."
        from={10}
        duration={half - 16}
      />
      <LowerThird
        label="03 · Live Simulator"
        text="Devin taps, types and scrolls. So can you."
        from={half}
        duration={duration - half - XFADE}
        exit={16}
      />
    </>
  );
};
