import React from "react";
import { Beat } from "../components/Beat";
import { Cursor } from "../components/Cursor";
import { Shot } from "../components/Shot";
import { Word } from "../components/Word";
import { beats } from "../tokens";

/** 13 beats. Feature 1 — pick macOS, Devin builds and runs the app in the Simulator. */
export const FeatureBuild: React.FC = () => (
  <>
    <Beat at={0} len={2}>
      <Word text="Pick macOS." />
    </Beat>
    <Beat at={2} len={3}>
      <Shot
        src="screens/devin-web-4.png"
        imgW={2988}
        imgH={1622}
        from={{ x: 287, y: 221, w: 2400 }}
        to={{ x: 432, y: 569, w: 1500 }}
        label="01 · Choose a Mac VM"
      >
        <Cursor
          from={{ x: 1715, y: 476 }}
          to={{ x: 820, y: 1190 }}
          moveStart={beats(0.4)}
          moveEnd={beats(1.8)}
          clickAt={beats(2)}
        />
      </Shot>
    </Beat>
    <Beat at={5} len={2}>
      <Word text={["Devin builds the app", "in Xcode."]} />
    </Beat>
    <Beat at={7} len={2}>
      <Word text={["Runs it in the", "iOS Simulator."]} />
    </Beat>
    <Beat at={9} len={4}>
      <Shot
        src="screens/devin-desktop-9.png"
        imgW={3024}
        imgH={1898}
        from={{ x: 0, y: 0, w: 3024 }}
        to={{ x: 263, y: 566, w: 1500 }}
        label="02 · Simulator, inside the session"
      />
    </Beat>
  </>
);
