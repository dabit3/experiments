import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile } from "remotion";
import { Crosshair, DrawRect, useDraw, useEnter } from "../components/Draw";
import { Label } from "../components/Text";
import { FONT_SANS, HEIGHT, WIDTH, bp, type } from "../theme";

const LOCKUP_W = 560;
const LOCKUP_H = Math.round(LOCKUP_W / (2984 / 1024));
const PLATE_PAD = 36;

export const End: React.FC = () => {
  const plate = useDraw(2, 14);
  const logo = useEnter(10);
  const line = useEnter(30);
  const url = useEnter(44);
  const cx = WIDTH / 2;
  const cy = 470;
  const px = cx - LOCKUP_W / 2 - PLATE_PAD;
  const py = cy - LOCKUP_H / 2 - PLATE_PAD;
  const pw = LOCKUP_W + PLATE_PAD * 2;
  const ph = LOCKUP_H + PLATE_PAD * 2;
  return (
    <AbsoluteFill>
      <svg width={WIDTH} height={HEIGHT} style={{ position: "absolute", inset: 0 }}>
        <DrawRect x={px} y={py} w={pw} h={ph} progress={plate} width={1.5} />
        <Crosshair x={px} y={py} opacity={Math.min(1, plate * 4)} />
        <Crosshair x={px + pw} y={py} opacity={Math.max(0, (plate - 0.25) * 4)} />
        <Crosshair x={px + pw} y={py + ph} opacity={Math.max(0, (plate - 0.5) * 4)} />
        <Crosshair x={px} y={py + ph} opacity={Math.max(0, (plate - 0.75) * 4)} />
      </svg>
      <Img
        src={staticFile("brand/devin-lockup-horizontal-white.png")}
        style={{
          position: "absolute",
          left: cx - LOCKUP_W / 2,
          top: cy - LOCKUP_H / 2,
          width: LOCKUP_W,
          height: LOCKUP_H,
          opacity: logo,
          transform: `translateY(${interpolate(logo, [0, 1], [10, 0])}px)`,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: py + ph + 56,
          textAlign: "center",
          fontFamily: FONT_SANS,
          fontWeight: 500,
          fontSize: 46,
          letterSpacing: type.tracking.heading,
          color: bp.text,
          opacity: line,
          transform: `translateY(${interpolate(line, [0, 1], [12, 0])}px)`,
        }}
      >
        Build, run and test iOS apps in the cloud.
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: py + ph + 132, display: "flex", justifyContent: "center", opacity: url }}>
        <Label color={bp.textDim}>devin.ai</Label>
      </div>
    </AbsoluteFill>
  );
};
