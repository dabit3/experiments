import React from "react";
import { Beat } from "../components/Beat";
import { Word } from "../components/Word";

/** 12 beats. Outcome / metrics, one claim per beat pair. */
export const Outcome: React.FC = () => (
  <>
    <Beat at={0} len={3}>
      <Word text="Minutes." tone="light" size={260} sub="Not 20+ minute CI round-trips." />
    </Beat>
    <Beat at={3} len={2}>
      <Word text={["The only coding agent", "with a Mac cloud agent."]} highlight="Mac" />
    </Beat>
    <Beat at={5} len={2}>
      <Word text={["Same security as", "Linux and Windows VMs."]} />
    </Beat>
    <Beat at={7} len={2}>
      <Word text="No price increase." tone="accent" />
    </Beat>
    <Beat at={9} len={3}>
      <Word
        text={["Child sessions, API, automations.", "All on Mac."]}
        highlight="Mac"
      />
    </Beat>
  </>
);
