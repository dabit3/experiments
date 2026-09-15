import React from 'react';
import {Easing, interpolate} from 'remotion';

type Point = {frame: number; x: number; y: number};
type CameraPoint = Point & {scale: number};

const move = Easing.inOut(Easing.cubic);
export const enter = (frame: number, duration = 24) =>
  interpolate(frame, [0, duration], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

const sample = (frame: number, frames: readonly number[], values: readonly number[]) =>
  interpolate(frame, [...frames], [...values], {
    easing: move,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

export const cameraTransform = (frame: number, points: readonly CameraPoint[]) => {
  const frames = points.map((point) => point.frame);
  const scale = sample(frame, frames, points.map((point) => point.scale));
  const x = sample(frame, frames, points.map((point) => point.x));
  const y = sample(frame, frames, points.map((point) => point.y));
  return `translate(${x}px, ${y}px) scale(${scale})`;
};

export const Cursor: React.FC<{
  frame: number;
  points: readonly Point[];
  clicks?: readonly number[];
}> = ({frame, points, clicks = []}) => {
  const frames = points.map((point) => point.frame);
  const x = sample(frame, frames, points.map((point) => point.x));
  const y = sample(frame, frames, points.map((point) => point.y));
  const click = clicks.find((at) => frame >= at && frame < at + 20);
  const progress = click === undefined ? 0 : enter(frame - click, 20);
  return (
    <div style={{position: 'absolute', left: x, top: y, zIndex: 5, pointerEvents: 'none'}}>
      {click !== undefined ? (
        <div style={{
          position: 'absolute', width: 58, height: 58, left: -29, top: -29,
          border: '3px solid #1971c2', borderRadius: '50%',
          opacity: 0.55 * (1 - progress), transform: `scale(${0.4 + progress})`,
        }} />
      ) : null}
      {x > 850 ? (
        <div style={{
          position: 'absolute', left: -11, top: -11, width: 22, height: 22,
          background: '#76b7f377', border: '2px solid #d0e7fa', borderRadius: '50%',
          boxShadow: '0 0 0 9px #8ac3f41f',
        }} />
      ) : (
        <svg width="33" height="42" viewBox="0 0 33 42" style={{filter: 'drop-shadow(0 3px 3px #0005)'}}>
          <path d="M3 2 L3 31 L11 24 L18 38 L24 35 L17 21 L29 20 Z" fill="#20242b" stroke="white" strokeWidth="2.5" strokeLinejoin="round" />
        </svg>
      )}
    </div>
  );
};
