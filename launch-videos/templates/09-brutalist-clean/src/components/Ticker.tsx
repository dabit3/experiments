import React, { useEffect, useRef, useState } from "react";
import { continueRender, delayRender, useCurrentFrame, useVideoConfig } from "remotion";
import { color, font, fontsReady, TICKER_HEIGHT, WIDTH } from "../theme";

const ITEMS = [
  "Build & run in Xcode",
  "Live iPhone Simulator",
  "Tap · Type · Scroll",
  "Reproduce & fix bugs",
  "Re-run UI tests",
  "Open the PR",
  "iPhone + iPad sizes",
  "Dark mode",
  "Pixel-for-pixel diffs",
  "Swift upgrades",
  "React Native · Flutter · Expo",
  "macOS child sessions",
  "Devin API",
];

const SPEED_PX_PER_SEC = 140;

export const Ticker: React.FC<{ invertFrom: number }> = ({ invertFrom }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const ref = useRef<HTMLDivElement>(null);
  const [copyWidth, setCopyWidth] = useState<number | null>(null);
  const [handle] = useState(() => delayRender("Measuring ticker"));

  useEffect(() => {
    let cancelled = false;
    fontsReady.then(() => {
      if (cancelled) return;
      if (ref.current) setCopyWidth(ref.current.getBoundingClientRect().width);
      continueRender(handle);
    });
    return () => {
      cancelled = true;
    };
  }, [handle]);

  const inverted = frame >= invertFrom;
  const bg = inverted ? color.paper : color.ink;
  const fg = inverted ? color.ink : color.paper;

  const offset = (frame / fps) * SPEED_PX_PER_SEC;
  const shift = copyWidth ? offset % copyWidth : 0;
  const copies = copyWidth ? Math.ceil(WIDTH / copyWidth) + 2 : 2;

  const copy = (key: string, measure = false) => (
    <div
      key={key}
      ref={measure ? ref : undefined}
      style={{ display: "flex", alignItems: "center", flexShrink: 0, whiteSpace: "nowrap" }}
    >
      {ITEMS.map((item, i) => (
        <React.Fragment key={i}>
          <span style={{ padding: "0 28px" }}>{item}</span>
          <span style={{ width: 10, height: 10, background: color.accent, flexShrink: 0 }} />
        </React.Fragment>
      ))}
    </div>
  );

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 0,
        height: TICKER_HEIGHT,
        background: bg,
        color: fg,
        overflow: "hidden",
        fontFamily: font.mono,
        fontSize: 20,
        fontWeight: 500,
        letterSpacing: font.tracking.caps,
        textTransform: "uppercase",
        display: "flex",
        alignItems: "center",
      }}
    >
      <div
        style={{
          display: "flex",
          transform: `translateX(${-shift}px)`,
          willChange: "transform",
        }}
      >
        {Array.from({ length: copies }, (_, i) => copy(`c${i}`, i === 0))}
      </div>
    </div>
  );
};
