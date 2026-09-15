import React from "react";
import { Caret } from "../components/Caret";
import { Grade } from "../components/FilmLayer";
import { LowerThird } from "../components/LowerThird";
import { MacroShot } from "../components/MacroShot";
import { SCREENS } from "../screens";
import { XFADE } from "../scenes";

/** Slow lateral dolly along the empty prompt field while a caret blinks. */
export const Context: React.FC<{ duration: number }> = ({ duration }) => {
  const s = SCREENS.web1;
  const half = Math.round(duration / 2);
  return (
    <>
      <MacroShot
        src={s.src}
        imgWidth={s.w}
        imgHeight={s.h}
        from={{ x: 930, y: 690, scale: 3.0 }}
        to={{ x: 1010, y: 690, scale: 3.0 }}
        moveDuration={duration}
        focusRadius={320}
        blur={12}
      >
        {(project, scale) => <Caret x={672} y={681} project={project} scale={scale} />}
      </MacroShot>
      <Grade />
      <LowerThird text="Before, iOS apps were QA'd by hand." from={10} duration={half - 16} />
      <LowerThird text="Or waited 20 minutes for CI." from={half} duration={duration - half - XFADE} />
    </>
  );
};
