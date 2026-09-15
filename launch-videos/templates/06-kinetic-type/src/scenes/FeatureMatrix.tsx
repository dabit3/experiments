import React from "react";
import { Beat } from "../components/Beat";
import { Shot } from "../components/Shot";
import { Word } from "../components/Word";

/** 13 beats. Feature 4 — every size, dark mode, orientation; pixel-for-pixel compare. */
export const FeatureMatrix: React.FC = () => (
  <>
    <Beat at={0} len={1}>
      <Word text="iPhone." size={240} align="center" />
    </Beat>
    <Beat at={1} len={1}>
      <Word text="iPad." size={240} align="center" tone="light" />
    </Beat>
    <Beat at={2} len={1}>
      <Word text="Dark mode." size={240} align="center" />
    </Beat>
    <Beat at={3} len={1}>
      <Word text="Landscape." size={240} align="center" tone="light" />
    </Beat>
    <Beat at={4} len={3}>
      <Shot
        src="screens/devin-web-17.png"
        imgW={2978}
        imgH={1620}
        from={{ x: 99, y: 331, w: 2200 }}
        to={{ x: 349, y: 620, w: 1700 }}
        label="05 · Every size and mode"
      />
    </Beat>
    <Beat at={7} len={2}>
      <Word text={["Screenshots compared", "pixel for pixel."]} />
    </Beat>
    <Beat at={9} len={4}>
      <Shot
        src="screens/devin-web-19.png"
        imgW={2982}
        imgH={1626}
        from={{ x: 0, y: 222, w: 2100 }}
        to={{ x: 135, y: 348, w: 1650 }}
        label="iPad Pro 13-inch · iOS 26.5"
      />
    </Beat>
  </>
);
