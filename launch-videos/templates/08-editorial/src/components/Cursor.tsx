import React, {useContext} from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {easeInOut, easeOut, ms} from '../tokens';
import {FigureContext, toFrameSpace} from './Figure';

type Point = {x: number; y: number};

type Props = {
  // Positions as fractions of the screenshot (0..1), independent of crop.
  from: Point;
  to: Point;
  // Scene-local frames: appear, start moving, arrive, click.
  at: number;
  moveAt: number;
  arriveAt: number;
  clickAt?: number;
  hideAt?: number;
  size?: number;
};

// macOS-style arrow pointer that glides from `from` to `to` and dips on click.
export const Cursor: React.FC<Props> = ({from, to, at, moveAt, arriveAt, clickAt, hideAt, size = 30}) => {
  const frame = useCurrentFrame();
  const geometry = useContext(FigureContext);
  const a = geometry ? toFrameSpace(geometry, from) : from;
  const b = geometry ? toFrameSpace(geometry, to) : to;
  const appear = interpolate(frame, [at, at + ms(300)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeOut,
  });
  const hide =
    hideAt === undefined
      ? 1
      : interpolate(frame, [hideAt, hideAt + ms(300)], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const p = interpolate(frame, [moveAt, arriveAt], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeInOut,
  });
  const x = a.x + (b.x - a.x) * p;
  const y = a.y + (b.y - a.y) * p;
  const press =
    clickAt === undefined
      ? 1
      : interpolate(frame, [clickAt, clickAt + 3, clickAt + 8], [1, 0.86, 1], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
        });

  return (
    <div
      style={{
        position: 'absolute',
        left: `${x * 100}%`,
        top: `${y * 100}%`,
        width: size,
        height: size,
        opacity: appear * hide,
        transform: `scale(${press})`,
        transformOrigin: '20% 10%',
        filter: 'drop-shadow(0 2px 3px rgba(0,0,0,0.35))',
      }}
    >
      <svg viewBox="0 0 24 24" width={size} height={size}>
        <path
          d="M5.5 3.2 L18.6 13.1 L12.6 13.9 L16.1 20.7 L13.6 21.9 L10.2 15.1 L5.5 19.2 Z"
          fill="#FFFFFF"
          stroke="#191919"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};
