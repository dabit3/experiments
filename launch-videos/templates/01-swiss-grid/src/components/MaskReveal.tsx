import type { CSSProperties, ReactNode } from "react";
import { useCurrentFrame } from "remotion";
import { ENTER, easeInOut, progress } from "../layout";

type Props = {
  children: ReactNode;
  /** Frame (relative to the parent sequence) at which the reveal starts. */
  from?: number;
  /** Length of the reveal in frames. */
  length?: number;
  /** Frame at which the text starts leaving through the top of the mask. */
  exitAt?: number;
  exitLength?: number;
  style?: CSSProperties;
  /** Extra room so descenders and tight line-heights are not clipped. */
  bleed?: number;
};

/**
 * Reveals its children through a rectangular mask: the block starts fully
 * below the mask and moves up along its own baseline. No fades, no scaling.
 */
export const MaskReveal = ({
  children,
  from = 0,
  length = ENTER,
  exitAt,
  exitLength = 12,
  style,
  bleed = 0.15,
}: Props) => {
  const frame = useCurrentFrame();
  const enter = progress(frame, from, length);
  const exit = exitAt === undefined ? 0 : progress(frame, exitAt, exitLength, easeInOut);
  const offset = (1 - enter) * 100 - exit * 100;
  const pad = `${bleed}em`;
  return (
    <div
      style={{
        overflow: "hidden",
        margin: `-${pad} 0`,
        padding: `${pad} 0`,
        ...style,
      }}
    >
      <div style={{ transform: `translateY(${offset}%)` }}>{children}</div>
    </div>
  );
};
