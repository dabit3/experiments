import React from "react";
import { Cursor } from "../components/Cursor";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** The platform picker: a cursor settles on macOS while the camera pushes in. */
export const ChoosePlatform: React.FC<{ duration: number }> = ({ duration }) => {
  const s = SCREENS.web4;
  return (
    <>
      <MacroShot
        src={s.src}
        imgWidth={s.w}
        imgHeight={s.h}
        from={{ x: 934, y: 1150, scale: 2.15 }}
        to={{ x: 934, y: 1185, scale: 2.5 }}
        moveDuration={duration}
        focus={{ x: 900, y: 1189 }}
        focusRadius={240}
        blur={12}
      >
        {(project) => (
          <Cursor
            project={project}
            keys={[
              { frame: 0, x: 1180, y: 1060 },
              { frame: 62, x: 985, y: 1200 },
            ]}
            clicks={[70]}
          />
        )}
      </MacroShot>
      <Grade />
      <LowerThird
        label="01 · Mac VM"
        text="Pick macOS. Devin runs in a Mac VM."
        from={26}
        duration={duration - 26 - XFADE}
        exit={16}
      />
    </>
  );
};
