import React from "react";
import { Beat } from "../components/Beat";
import { Shot } from "../components/Shot";
import { Word } from "../components/Word";

/** 13 beats. Feature 3 — reproduce, fix, re-test, open a PR. */
export const FeatureFix: React.FC = () => (
  <>
    <Beat at={0} len={1.5}>
      <Word text="Reproduces a bug." />
    </Beat>
    <Beat at={1.5} len={1.5}>
      <Word text="Fixes it." />
    </Beat>
    <Beat at={3} len={1.5}>
      <Word text="Re-runs the UI tests." />
    </Beat>
    <Beat at={4.5} len={3.5}>
      <Shot
        src="screens/devin-web-9.png"
        imgW={2988}
        imgH={1628}
        from={{ x: 0, y: 368, w: 1400 }}
        to={{ x: 1588, y: 235, w: 1400 }}
        label="04 · 12 passed → PR opened"
      />
    </Beat>
    <Beat at={8} len={2}>
      <Word text="Opens a PR." highlight="PR" />
    </Beat>
    <Beat at={10} len={3}>
      <Shot
        src="screens/devin-web-8.png"
        imgW={2990}
        imgH={1618}
        from={{ x: 57, y: 0, w: 2876 }}
        to={{ x: 1190, y: 66, w: 1800 }}
        label="Merged"
      />
    </Beat>
  </>
);
