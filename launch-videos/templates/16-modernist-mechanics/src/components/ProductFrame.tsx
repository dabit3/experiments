import React from 'react';
import {Sequence} from 'remotion';
import type {LaunchProps} from '../schema';
import {CANVAS_W, findSlot, primaryMediaName} from '../geometry';
import type {FrameState} from '../timeline';
import {Media} from './Media';
import {easeOut, enterStyle} from '../motion';

/**
 * The product frame: one rectangle that travels between scene layouts.
 * Media inside it is anchored to its resting rectangle; a flat ink plane
 * (the shutter) slides across the frame at each boundary to divide and reveal.
 */
export const ProductFrame: React.FC<{props: LaunchProps; state: FrameState; frame: number}> = ({
  props,
  state,
  frame,
}) => {
  const {shapes, motion, layout, brand} = props;
  const {rect, spans, geos} = state;
  const first = spans[0];
  const isOpen = first.scene.type === 'open';

  // Opening: the plane slides into place from the right.
  const enter = isOpen ? easeOut(frame, 6, motion.entranceFrames + 6) : 1;
  const openFill = isOpen && state.index === 0 && frame < first.end - state.half;

  const shutterX = state.shutter === null ? null : state.shutter * rect.w;

  // From the result scene on, hairlines extend the frame's edges to the canvas.
  const resultIndex = spans.findIndex((s) => s.scene.type === 'result');
  const linesT =
    resultIndex >= 0 ? easeOut(frame, spans[resultIndex].start + state.half + 4, 22) : 0;

  return (
    <>
      {linesT > 0 && <ExtensionLines props={props} state={state} t={linesT} />}
      <div
        style={{
          position: 'absolute',
          left: rect.x,
          top: rect.y,
          width: rect.w,
          height: rect.h,
          overflow: 'hidden',
          borderRadius: layout.radius,
          background: openFill ? shapes.frame.fill : brand.paper,
          boxShadow: openFill ? 'none' : `0 0 0 ${shapes.frame.borderWidth}px ${shapes.frame.border}`,
          ...enterStyle(enter, motion.slideDistance * 2, 'x'),
        }}
      >
        {spans.map((span, i) => {
          const name = primaryMediaName(span.scene);
          if (!name) {
            return null;
          }
          const slot = findSlot(props.media, name);
          const prev = i > 0 ? primaryMediaName(spans[i - 1].scene) : null;
          if (!slot || prev === name) {
            // Same media continues from the previous scene; that Sequence covers it.
            return null;
          }
          let last = i;
          for (let j = i + 1; j < spans.length; j++) {
            if (primaryMediaName(spans[j].scene) !== name) {
              break;
            }
            last = j;
          }
          // Media stays anchored while a shutter divides scenes (the frame reveals it);
          // when the same media carries across a boundary it rescales with the frame.
          const owns = state.index >= i && state.index <= last;
          const rest = owns && state.shutter === null ? rect : geos[i].frames[0];
          return (
            <Sequence
              key={span.scene.id}
              from={span.start}
              durationInFrames={spans[last].end - span.start}
              layout="none"
            >
              <Media slot={slot} rest={rest} />
            </Sequence>
          );
        })}
        {shutterX !== null && (
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: shapes.frame.fill,
              transform: `translateX(${shutterX}px)`,
            }}
          />
        )}
        <SpeedBadge props={props} state={state} />
      </div>
    </>
  );
};

const SpeedBadge: React.FC<{props: LaunchProps; state: FrameState}> = ({props, state}) => {
  const scene = props.scenes[state.index];
  if (scene.type !== 'demo' || !scene.showSpeedBadge) {
    return null;
  }
  const {brand} = props;
  return (
    <div
      style={{
        position: 'absolute',
        top: 16,
        right: 16,
        padding: '4px 10px',
        borderRadius: 8,
        background: brand.ink,
        color: brand.white,
        fontFamily: brand.monoFontFamily,
        fontSize: 16,
        fontWeight: 500,
        opacity: easeOut(state.settled, 0, props.motion.entranceFrames),
      }}
    >
      {props.content.speedBadge}
    </div>
  );
};

const ExtensionLines: React.FC<{props: LaunchProps; state: FrameState; t: number}> = ({
  props,
  state,
  t,
}) => {
  const {rule} = props.shapes;
  const {rect} = state;
  const th = rule.thickness;
  const color = rule.color;
  const bottom = rect.y + rect.h;
  const railTop = rule.y - th / 2;
  const line = (style: React.CSSProperties, origin: string) => (
    <div
      style={{
        position: 'absolute',
        background: color,
        transformOrigin: origin,
        ...style,
      }}
    />
  );
  return (
    <div style={{position: 'absolute', inset: 0, pointerEvents: 'none'}}>
      {line(
        {left: 0, top: rect.y - th / 2, width: rect.x, height: th, transform: `scaleX(${t})`},
        'right center',
      )}
      {line(
        {
          left: rect.x + rect.w,
          top: rect.y - th / 2,
          width: CANVAS_W - rect.x - rect.w,
          height: th,
          transform: `scaleX(${t})`,
        },
        'left center',
      )}
      {line(
        {left: 0, top: bottom - th / 2, width: rect.x, height: th, transform: `scaleX(${t})`},
        'right center',
      )}
      {line(
        {
          left: rect.x + rect.w,
          top: bottom - th / 2,
          width: CANVAS_W - rect.x - rect.w,
          height: th,
          transform: `scaleX(${t})`,
        },
        'left center',
      )}
      {line(
        {
          left: rect.x - th / 2,
          top: bottom,
          width: th,
          height: Math.max(0, railTop - bottom),
          transform: `scaleY(${t})`,
        },
        'center top',
      )}
      {line(
        {
          left: rect.x + rect.w - th / 2,
          top: bottom,
          width: th,
          height: Math.max(0, railTop - bottom),
          transform: `scaleY(${t})`,
        },
        'center top',
      )}
    </div>
  );
};
