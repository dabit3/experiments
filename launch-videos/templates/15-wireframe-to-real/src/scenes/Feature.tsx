import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { easeIn, easeInOut, easeOut, ms, prog } from "../anim";
import { Cursor, CursorKey } from "../components/Cursor";
import {
  CAPTION_Y,
  LABEL_Y,
  SIZE,
  STAGE_H,
  STAGE_W,
  STAGE_X,
  STAGE_Y,
} from "../components/Layout";
import { headlineStyle, labelStyle, Rise } from "../components/Text";
import { Typing } from "../components/Typing";
import { Prim, Wireframe } from "../components/Wireframe";
import { featureBeats } from "../scenes";
import { color, radius, shadow } from "../tokens";

export type Shot = {
  /** file under assets/screens, e.g. "devin-web-1.png" */
  file: string;
  /** relative frame at which this shot becomes visible (cross-fades in over 500ms) */
  at: number;
};

export type Caption = { text: string; from: number; to?: number };

export type TypingSpec = {
  text: string;
  from: number;
  x: number;
  y: number;
  w: number;
  h: number;
  fontSize: number;
  cover: string;
};

type Props = {
  index: number;
  title: string;
  wire: Prim[];
  shots: Shot[];
  /** slow push-in applied to the resolved screenshot */
  push: { scaleTo: number; origin: string };
  captions: Caption[];
  cursor?: { keys: CursorKey[]; from: number; to?: number };
  typing?: TypingSpec;
  duration: number;
};

const { drawDuration, resolveDuration, exitDuration } = featureBeats;

export const Feature: React.FC<Props> = ({
  index,
  title,
  wire,
  shots,
  push,
  captions,
  cursor,
  typing,
  duration,
}) => {
  const frame = useCurrentFrame();

  const draw = prog(frame, 0, drawDuration, easeInOut);
  const resolveAt = drawDuration;
  const resolve = prog(frame, resolveAt, resolveDuration, easeOut);
  const liveFrom = resolveAt + resolveDuration;
  const scale =
    1 + (push.scaleTo - 1) * prog(frame, resolveAt, duration - resolveAt, easeInOut);
  const exit = 1 - prog(frame, duration - exitDuration, exitDuration, easeIn);
  const enter = prog(frame, 0, ms(300), easeOut);

  return (
    <AbsoluteFill style={{ opacity: exit }}>
      {/* mono label: wireframe -> built */}
      <div style={{ position: "absolute", left: STAGE_X, top: LABEL_Y }}>
        <Rise from={0} to={resolveAt + ms(200)} style={labelStyle} rise={0}>
          {title} · Wireframe
        </Rise>
      </div>
      <div style={{ position: "absolute", left: STAGE_X, top: LABEL_Y }}>
        <Rise from={resolveAt + ms(100)} style={labelStyle} rise={0}>
          {title} · <span style={{ color: color.accent }}>Built</span>
        </Rise>
      </div>

      {/* stage */}
      <div
        style={{
          position: "absolute",
          left: STAGE_X,
          top: STAGE_Y,
          width: STAGE_W,
          height: STAGE_H,
          opacity: enter,
        }}
      >
        {/* wireframe artboard */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: radius.md,
            background: color.white,
            border: `1.5px solid ${color.gray300}`,
            backgroundImage: `radial-gradient(${color.gray300} 1px, transparent 1.2px)`,
            backgroundSize: "24px 24px",
            backgroundPosition: "12px 12px",
            opacity: 1 - resolve,
          }}
        >
          <Wireframe prims={wire} progress={draw} seed={index} />
        </div>

        {/* resolved screenshots */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: radius.md,
            overflow: "hidden",
            boxShadow: shadow.figure,
            opacity: resolve,
            background: color.white,
          }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              transform: `scale(${scale})`,
              transformOrigin: push.origin,
            }}
          >
            {shots.map((s, i) => {
              const o = i === 0 ? 1 : prog(frame, s.at, ms(500), easeInOut);
              if (o <= 0) return null;
              return (
                <Img
                  key={s.file}
                  src={staticFile(`screens/${s.file}`)}
                  style={{
                    position: "absolute",
                    inset: 0,
                    width: "100%",
                    height: "100%",
                    objectFit: "cover",
                    objectPosition: "top left",
                    opacity: o,
                  }}
                />
              );
            })}
            {typing && frame >= liveFrom ? (
              <Typing {...typing} stageW={STAGE_W} stageH={STAGE_H} />
            ) : null}
            {cursor ? (
              <Cursor
                keys={cursor.keys}
                from={cursor.from}
                to={cursor.to}
                stageW={STAGE_W}
                stageH={STAGE_H}
              />
            ) : null}
          </div>
        </div>
      </div>

      {/* narration */}
      {captions.map((c) => (
        <div
          key={c.text}
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: CAPTION_Y,
            display: "flex",
            justifyContent: "center",
            textAlign: "center",
          }}
        >
          <Rise from={c.from} to={c.to} style={headlineStyle(SIZE.caption)}>
            {c.text}
          </Rise>
        </div>
      ))}
    </AbsoluteFill>
  );
};
