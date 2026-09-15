import React from "react";
import { AbsoluteFill } from "remotion";
import { TerminalWindow } from "../components/TerminalWindow";
import { HistoryLine, OutputLine, Tone, TypedCommand } from "../components/Prompt";
import { EXIT_FRAMES, Pane } from "../components/Pane";
import { Caption } from "../components/Caption";
import { typeFrames } from "../scenes";

export type Output = { text: string; prefix?: string; tone?: Tone; prefixTone?: Tone };

export type FeatureSpec = {
  history: string;
  command: string;
  output: Output[];
  shots: string[];
  label: string;
  caption: string[];
  overlay?: React.ReactNode;
};

/**
 * Beat sheet (frames, 7 s scene):
 *   6   start typing the command
 *  +T   typing done, blink, Enter at T+12
 *  Enter+4, +16, +28   output lines
 *  Enter+8   pane fades in, docked
 *  Enter+52  pane expands to full frame
 *  Enter+78  caption in
 *  D-EXIT    pane + caption fade out, revealing the log
 */
export const Feature: React.FC<FeatureSpec & { duration: number }> = ({
  history,
  command,
  output,
  shots,
  label,
  caption,
  overlay,
  duration,
}) => {
  const typeAt = 6;
  const submitAt = typeAt + typeFrames(command) + 12;
  const paneAt = submitAt + 8;
  const expandAt = submitAt + 52;
  const captionAt = expandAt + 26;
  const exitAt = duration - EXIT_FRAMES;

  return (
    <AbsoluteFill>
      <TerminalWindow>
        <HistoryLine text={history} />
        <TypedCommand text={command} at={typeAt} submitAt={submitAt} />
        {output.map((o, i) => (
          <OutputLine key={o.text} at={submitAt + 4 + i * 12} tone={o.tone} prefix={o.prefix} prefixTone={o.prefixTone}>
            {o.text}
          </OutputLine>
        ))}
      </TerminalWindow>
      <Pane shots={shots} enterAt={paneAt} expandAt={expandAt} exitAt={exitAt}>
        {overlay}
      </Pane>
      <Caption label={label} lines={caption} at={captionAt} exitAt={exitAt} />
    </AbsoluteFill>
  );
};
