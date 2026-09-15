import React from "react";
import { AbsoluteFill } from "remotion";
import { TerminalWindow } from "../components/TerminalWindow";
import { Blank, HistoryLine, OutputLine, TypedCommand } from "../components/Prompt";
import { typeFrames } from "../scenes";
import { HOOK_COMMAND } from "./Hook";

export const CONTEXT_COMMAND = "cat BEFORE.md";

/** Problem / context: four short lines, shown two at a time. */
export const Context: React.FC = () => {
  const typeAt = 6;
  const submitAt = typeAt + typeFrames(CONTEXT_COMMAND) + 12;
  const a = submitAt + 4;
  const b = a + 18;
  const c = b + 58;
  const d = c + 18;
  const size = 30;

  return (
    <AbsoluteFill>
      <TerminalWindow>
        <HistoryLine text={HOOK_COMMAND} />
        <TypedCommand text={CONTEXT_COMMAND} at={typeAt} submitAt={submitAt} />
        <Blank h={28} />
        <OutputLine at={a} dimAt={c} size={size}>
          Before: iOS teams QA&apos;d the app by hand,
        </OutputLine>
        <OutputLine at={b} dimAt={c} size={size}>
          or waited 20+ minutes on CI.
        </OutputLine>
        <Blank h={28} />
        <OutputLine at={c} size={size}>
          No coding agent could build, run
        </OutputLine>
        <OutputLine at={d} size={size}>
          and tap through an iPhone app on its own.
        </OutputLine>
      </TerminalWindow>
    </AbsoluteFill>
  );
};
