import React from "react";
import { AbsoluteFill, interpolate } from "remotion";
import { DrawPath, useDraw, useEnter } from "../components/Draw";
import { Label } from "../components/Text";
import { FONT_SANS, HEIGHT, MARGIN, WIDTH, bp, type } from "../theme";

export const Hook: React.FC = () => {
  const label = useEnter(4);
  const title = useEnter(10);
  const rule = useDraw(24);
  const rise = interpolate(title, [0, 1], [16, 0]);
  const baseline = 560;
  return (
    <AbsoluteFill>
      <div style={{ position: "absolute", left: MARGIN, top: baseline - 200, opacity: label }}>
        <Label color={bp.textDim}>New · macOS cloud sessions</Label>
      </div>
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: baseline - 130,
          fontFamily: FONT_SANS,
          fontWeight: 500,
          fontSize: type.sizes1080p.hero,
          lineHeight: type.leading.tight,
          letterSpacing: type.tracking.hero,
          color: bp.text,
          opacity: title,
          transform: `translateY(${rise}px)`,
          whiteSpace: "nowrap",
        }}
      >
        Devin now runs on Mac.
      </div>
      <svg width={WIDTH} height={HEIGHT} style={{ position: "absolute", inset: 0 }}>
        <DrawPath d={`M${MARGIN},${baseline + 24} H${MARGIN + 1180}`} progress={rule} width={1.5} />
        <DrawPath d={`M${MARGIN},${baseline + 16} V${baseline + 32}`} progress={Math.min(1, rule * 4)} width={1.5} />
        <DrawPath
          d={`M${MARGIN + 1180},${baseline + 16} V${baseline + 32}`}
          progress={Math.max(0, (rule - 0.7) * 3.3)}
          width={1.5}
        />
      </svg>
      <div style={{ position: "absolute", left: MARGIN, top: baseline + 48, opacity: useEnter(40) }}>
        <Label color={bp.textFaint} size={18}>
          Writes and tests code for Mac and iOS apps
        </Label>
      </div>
    </AbsoluteFill>
  );
};
