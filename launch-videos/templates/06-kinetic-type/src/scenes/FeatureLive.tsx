import React from "react";
import { Beat } from "../components/Beat";
import { Shot } from "../components/Shot";
import { Word } from "../components/Word";

/** 14 beats. Feature 2 — the live iPhone Simulator tab. */
export const FeatureLive: React.FC = () => (
  <>
    <Beat at={0} len={2}>
      <Word text={["A live iPhone Simulator", "in your session."]} />
    </Beat>
    {/* Sequential frames of the same player: loading → typing. Hard cut on the beat. */}
    <Beat at={2} len={1.5}>
      <Shot
        src="screens/devin-web-11.png"
        imgW={2986}
        imgH={1630}
        from={{ x: 0, y: 168, w: 2300 }}
        to={{ x: 40, y: 250, w: 2100 }}
        label="03 · Live Simulator tab"
      />
    </Beat>
    <Beat at={3.5} len={1.5}>
      <Shot
        src="screens/devin-web-10.png"
        imgW={2990}
        imgH={1624}
        from={{ x: 40, y: 250, w: 2100 }}
        to={{ x: 122, y: 361, w: 1700 }}
        label="03 · Live Simulator tab"
      />
    </Beat>
    <Beat at={5} len={1}>
      <Word text="Taps." size={240} align="center" />
    </Beat>
    <Beat at={6} len={1}>
      <Word text="Types." size={240} align="center" />
    </Beat>
    <Beat at={7} len={1}>
      <Word text="Scrolls." size={240} align="center" />
    </Beat>
    <Beat at={8} len={2}>
      <Word text="Like a person." tone="light" />
    </Beat>
    <Beat at={10} len={2}>
      <Word text={["You can watch.", "And tap, too."]} highlight="tap" />
    </Beat>
    <Beat at={12} len={2}>
      <Shot
        src="screens/devin-web-14.png"
        imgW={2990}
        imgH={1624}
        from={{ x: 22, y: 266, w: 1900 }}
        to={{ x: 222, y: 378, w: 1500 }}
        label="Tap along in the browser"
      />
    </Beat>
  </>
);
