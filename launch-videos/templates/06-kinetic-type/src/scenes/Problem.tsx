import React from "react";
import { Beat } from "../components/Beat";
import { Word } from "../components/Word";

/** 11 beats. The old way, cut on the beat, then "Until now." */
export const Problem: React.FC = () => (
  <>
    <Beat at={0} len={2}>
      <Word text="iOS teams QA'd by hand." />
    </Beat>
    <Beat at={2} len={2}>
      <Word
        text="Or waited 20+ minutes"
        sub="for CI to say whether the app worked."
        highlight="20+"
      />
    </Beat>
    <Beat at={4} len={1}>
      <Word text="No coding agent could" />
    </Beat>
    <Beat at={5} len={0.5}>
      <Word text="build," size={220} />
    </Beat>
    <Beat at={5.5} len={0.5}>
      <Word text="run," size={220} />
    </Beat>
    <Beat at={6} len={2}>
      <Word text={["or tap through", "an iPhone app."]} />
    </Beat>
    <Beat at={8} len={3}>
      <Word text="Until now." tone="accent" align="center" size={220} />
    </Beat>
  </>
);
