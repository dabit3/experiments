import React from "react";
import { Beat } from "../components/Beat";
import { Shot } from "../components/Shot";
import { Word } from "../components/Word";

/** 8 beats. Devin / now runs / on Mac. → macOS chip on the real home screen. */
export const Hook: React.FC = () => (
  <>
    <Beat at={0} len={2}>
      <Word text="Devin" size={260} />
    </Beat>
    <Beat at={2} len={4}>
      <Word text="now runs on Mac." tone="light" highlight="Mac" />
    </Beat>
    <Beat at={6} len={2}>
      <Shot
        src="screens/devin-web-1.png"
        imgW={2990}
        imgH={1624}
        from={{ x: 287, y: 221, w: 2400 }}
        to={{ x: 687, y: 350, w: 1600 }}
        label="New · macOS cloud sessions"
      />
    </Beat>
  </>
);
