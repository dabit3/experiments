import React from "react";
import { Headline } from "../components/Headline";
import { CROSSFADE } from "../scenes";
import { sec } from "../tokens";

export const Context: React.FC = () => (
  <>
    <Headline size="h1" from={CROSSFADE} until={sec(3.1)} maxWidth={1500}>
      iOS teams tested by hand,{"\n"}or waited 20+ minutes for CI.
    </Headline>
    <Headline size="h1" from={sec(3.2)} maxWidth={1500}>
      No coding agent could build, run{"\n"}and tap through an iPhone app.
    </Headline>
  </>
);
