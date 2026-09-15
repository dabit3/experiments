import React from 'react';
import type {LaunchProps} from '../schema';
import {CANVAS_W} from '../geometry';
import {easeOut, enterStyle} from '../motion';

export const stageNodeX = (props: LaunchProps, stage: number) => {
  const {margin} = props.layout;
  const count = props.content.stages.length;
  const usable = CANVAS_W - margin * 2 - 180;
  return margin + (usable / Math.max(1, count - 1)) * stage;
};

/**
 * The progression line: one rule across the safe width, one tile per stage.
 * The accent segment advances to the active stage; nothing else on it moves.
 */
export const Rail: React.FC<{
  props: LaunchProps;
  /** Active stage as a continuous value (interpolated during moves); -1 = none. */
  progress: number;
  /** Frame index used for the introductory build (open scene); pass a large number to skip. */
  introFrame: number;
}> = ({props, progress, introFrame}) => {
  const {rule, tiles} = props.shapes;
  const {brand, content, motion, layout} = props;
  const count = content.stages.length;
  const lineT = easeOut(introFrame, 4, 26);
  const lineW = CANVAS_W - layout.margin * 2;

  const activeStage = Math.round(progress);
  const progressEnd =
    progress < 0
      ? layout.margin
      : stageNodeX(props, Math.min(progress, count - 1)) + tiles.size / 2;
  const progressW = Math.max(0, progressEnd - layout.margin);

  return (
    <div style={{position: 'absolute', inset: 0, pointerEvents: 'none'}}>
      <div
        style={{
          position: 'absolute',
          left: layout.margin,
          top: rule.y - rule.thickness / 2,
          width: lineW,
          height: rule.thickness,
          background: rule.color,
          transform: `scaleX(${lineT})`,
          transformOrigin: 'left center',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: layout.margin,
          top: rule.y - rule.thickness / 2,
          width: progressW * lineT,
          height: rule.thickness,
          background: rule.progressColor,
        }}
      />
      {content.stages.map((label, i) => {
        const t = easeOut(introFrame, 14 + i * motion.stagger, motion.entranceFrames);
        const active = progress >= 0 && i <= activeStage;
        const current = progress >= 0 && i === activeStage;
        const x = stageNodeX(props, i);
        return (
          <div
            key={label}
            style={{
              position: 'absolute',
              left: x,
              top: rule.y - tiles.size / 2 - 34,
              display: 'flex',
              flexDirection: 'column',
              gap: 12,
              ...enterStyle(t, -motion.slideDistance / 2, 'y'),
            }}
          >
            <div style={{display: 'flex', alignItems: 'baseline', whiteSpace: 'nowrap'}}>
              <span
                style={{
                  fontFamily: brand.fontFamily,
                  fontSize: 18,
                  lineHeight: '22px',
                  letterSpacing: -0.2,
                  fontWeight: current ? 500 : 400,
                  color: current ? brand.ink : brand.inkMuted,
                }}
              >
                {label}
              </span>
            </div>
            <div
              style={{
                width: tiles.size,
                height: tiles.size,
                background: active ? tiles.activeFill : tiles.fill,
                outline: `${rule.thickness}px solid ${brand.paper}`,
              }}
            />
          </div>
        );
      })}
    </div>
  );
};
