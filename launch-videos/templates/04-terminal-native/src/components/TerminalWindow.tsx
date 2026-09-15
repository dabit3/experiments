import React from "react";
import { AbsoluteFill } from "remotion";
import { color, font, radius, shadow, terminal } from "../tokens";

const lights = ["#EC6765", "#E4B001", "#5FBF48"];

export const TerminalWindow: React.FC<{
  title?: string;
  opacity?: number;
  scale?: number;
  children?: React.ReactNode;
}> = ({ title = "devin — macOS", opacity = 1, scale = 1, children }) => {
  return (
    <AbsoluteFill style={{ backgroundColor: color.darkBg }}>
      <div
        style={{
          position: "absolute",
          left: terminal.margin,
          top: terminal.margin,
          width: terminal.width,
          height: terminal.height,
          backgroundColor: terminal.bg,
          border: `1px solid ${color.darkBorder}`,
          borderRadius: radius.md,
          boxShadow: shadow.dark,
          overflow: "hidden",
          opacity,
          transform: `scale(${scale})`,
          transformOrigin: "50% 50%",
        }}
      >
        <div
          style={{
            height: terminal.titleBar,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            position: "relative",
          }}
        >
          <div style={{ position: "absolute", left: 18, display: "flex", gap: 8 }}>
            {lights.map((c) => (
              <div key={c} style={{ width: 13, height: 13, borderRadius: 999, backgroundColor: c }} />
            ))}
          </div>
          <span
            style={{
              fontFamily: font.mono,
              fontSize: 15,
              color: color.gray500,
              letterSpacing: "0.01em",
            }}
          >
            {title}
          </span>
        </div>
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: terminal.titleBar,
            bottom: 0,
            padding: `${terminal.padY}px ${terminal.padX}px`,
          }}
        >
          {children}
        </div>
      </div>
    </AbsoluteFill>
  );
};
