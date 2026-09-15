import React from "react";
import { Headline } from "../components/Headline";
import { CROSSFADE } from "../scenes";
import { sec } from "../tokens";

const lines = [
  "Minutes, not 20+ minute CI round-trips.",
  "The only coding agent with a Mac cloud agent.",
  "Same security. No price increase.",
];

// The first line waits for the previous scene to finish dissolving so text never lands on a screenshot.
const START = CROSSFADE + 4;
const EACH = sec(2.1);

export const Metrics: React.FC = () => (
  <>
    {lines.map((line, i) => (
      <Headline
        key={line}
        size="h1"
        from={START + i * EACH}
        until={i === lines.length - 1 ? Number.POSITIVE_INFINITY : START + (i + 1) * EACH - 2}
        maxWidth={1600}
      >
        {line}
      </Headline>
    ))}
  </>
);
