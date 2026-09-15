import React from "react";
import { AbsoluteFill } from "remotion";
import { Sheet } from "./components/Sheet";
import { Shell } from "./components/Shell";
import { Context } from "./scenes/Context";
import { End } from "./scenes/End";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { Build, Fix, Matrix, Simulator } from "./scenes/features";

export const Main: React.FC = () => (
  <AbsoluteFill>
    <Sheet />
    <Shell id="hook">
      <Hook />
    </Shell>
    <Shell id="context">
      <Context />
    </Shell>
    <Shell id="build">
      <Build />
    </Shell>
    <Shell id="simulator">
      <Simulator />
    </Shell>
    <Shell id="fix">
      <Fix />
    </Shell>
    <Shell id="matrix">
      <Matrix />
    </Shell>
    <Shell id="outcome">
      <Outcome />
    </Shell>
    <Shell id="end">
      <End />
    </Shell>
  </AbsoluteFill>
);
