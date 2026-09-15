import React, { useLayoutEffect, useMemo, useRef, useState } from "react";
import { continueRender, delayRender, useCurrentFrame } from "remotion";
import { easeIn, easeInOut, easeOut, ms, prog } from "../anim";
import { color } from "../tokens";
import { roughRect } from "./rough";

type Props = {
  children: React.ReactNode;
  style: React.CSSProperties;
  /** relative frame at which the sketch starts drawing */
  from: number;
  /** relative frame at which the sketch resolves into real text */
  resolveAt: number;
  /** relative frame at which everything has faded out (optional) */
  to?: number;
  /** `outline` draws a rough box around the text; `bar` is a filled placeholder */
  mode?: "outline" | "bar";
  seed?: number;
};

/**
 * Text that first appears as a hand-drawn wireframe placeholder, then resolves
 * into the real typeset line over 600ms. The placeholder is sized from the
 * rendered text so the two always line up.
 */
export const SketchText: React.FC<Props> = ({
  children,
  style,
  from,
  resolveAt,
  to,
  mode = "outline",
  seed = 3,
}) => {
  const frame = useCurrentFrame();
  const ref = useRef<HTMLDivElement>(null);
  const [box, setBox] = useState<{ w: number; h: number } | null>(null);
  const [handle] = useState(() => delayRender("Measuring sketch text"));

  // Re-measure on every render: the composition container can still be 0x0
  // during the very first layout pass, and fonts may swap in a frame later.
  useLayoutEffect(() => {
    if (ref.current) {
      const r = ref.current.getBoundingClientRect();
      if (!box || Math.abs(box.w - r.width) > 0.5 || Math.abs(box.h - r.height) > 0.5) {
        setBox({ w: r.width, h: r.height });
      }
    }
    continueRender(handle);
  });

  const pad = 14;
  const path = useMemo(() => {
    if (!box) return null;
    return roughRect(pad, pad, box.w, box.h, 3, seed, 1.4);
  }, [box, seed]);

  const draw = prog(frame, from, ms(700), easeInOut);
  const resolve = prog(frame, resolveAt, ms(600), easeOut);
  const out = to === undefined ? 0 : prog(frame, to - ms(300), ms(300), easeIn);

  const w = box ? box.w + pad * 2 : 0;
  const h = box ? box.h + pad * 2 : 0;

  return (
    <div style={{ position: "relative", display: "inline-block", opacity: 1 - out }}>
      <div ref={ref} style={{ ...style, width: "max-content", opacity: resolve }}>
        {children}
      </div>
      {box && path ? (
        <svg
          width={w}
          height={h}
          viewBox={`0 0 ${w} ${h}`}
          style={{
            position: "absolute",
            left: -pad,
            top: -pad,
            overflow: "visible",
            opacity: 1 - resolve,
          }}
        >
          {mode === "bar" ? (
            <rect
              x={pad}
              y={pad + box.h * 0.18}
              width={box.w * draw}
              height={box.h * 0.64}
              rx={box.h * 0.32}
              fill={color.gray300}
            />
          ) : (
            <path
              d={path.d}
              fill="none"
              stroke={color.gray400}
              strokeWidth={2}
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeDasharray={path.len}
              strokeDashoffset={path.len * (1 - draw)}
            />
          )}
        </svg>
      ) : null}
    </div>
  );
};
