import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { LaunchProps } from "../schema";
import { RouteMap } from "../components/RouteMap";
import { Headline, TopBar, Wipe } from "../components/Chrome";
import { SAFE, TYPE, ramp } from "../geometry";

type Props = { props: LaunchProps };

// The whole route is complete; closing line and CTA.
export const OutroScene: React.FC<Props> = ({ props }) => {
  const frame = useCurrentFrame();
  const { brand, content, route } = props;
  const head = ramp(frame, 6, 26);
  const cta = ramp(frame, 26, 22);
  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <TopBar brand={brand} content={content} />
      <div style={{ position: "absolute", left: SAFE, top: 196 }}>
        <Wipe t={head}>
          <Headline brand={brand} text={content.outroLine} accentWord="Mac" size={76} />
        </Wipe>
        <Wipe t={cta} style={{ marginTop: 40, display: "flex", alignItems: "center", gap: 20 }}>
          <div
            style={{
              height: 42,
              padding: "0 16px",
              borderRadius: 2,
              background: brand.ink,
              color: brand.white,
              fontFamily: brand.fontFamily,
              fontSize: TYPE.body.size,
              letterSpacing: TYPE.body.tracking,
              display: "flex",
              alignItems: "center",
              whiteSpace: "nowrap",
            }}
          >
            {content.cta.label}
          </div>
          <div style={{ fontFamily: brand.monoFontFamily, fontSize: TYPE.label.size, color: brand.inkMuted }}>{content.cta.url}</div>
        </Wipe>
      </div>
      <RouteMap brand={brand} route={route} progress={route.stations.length} />
    </AbsoluteFill>
  );
};
