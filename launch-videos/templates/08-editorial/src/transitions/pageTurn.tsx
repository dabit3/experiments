import React from 'react';
import {AbsoluteFill} from 'remotion';
import type {TransitionPresentation, TransitionPresentationComponentProps} from '@remotion/transitions';

export type PageTurnProps = Record<string, never>;

const SHADOW_WIDTH = 160;

// The incoming page wipes in from the right edge, like turning a leaf: its
// leading edge casts a soft paper shadow onto the page underneath.
const PageTurnPresentation: React.FC<TransitionPresentationComponentProps<PageTurnProps>> = ({
  children,
  presentationDirection,
  presentationProgress,
}) => {
  if (presentationDirection === 'exiting') {
    return <AbsoluteFill>{children}</AbsoluteFill>;
  }

  const edge = (1 - presentationProgress) * 100;

  return (
    <AbsoluteFill>
      <AbsoluteFill
        style={{
          left: `${edge}%`,
          width: SHADOW_WIDTH,
          transform: `translateX(-${SHADOW_WIDTH}px)`,
          background: 'linear-gradient(to right, rgba(25,25,25,0) 0%, rgba(25,25,25,0.10) 100%)',
          opacity: presentationProgress < 0.02 ? 0 : 1,
        }}
      />
      <AbsoluteFill style={{clipPath: `inset(0 0 0 ${edge}%)`}}>{children}</AbsoluteFill>
      <AbsoluteFill
        style={{
          left: `${edge}%`,
          width: 1,
          background: 'rgba(25,25,25,0.16)',
          opacity: presentationProgress < 0.02 || presentationProgress > 0.98 ? 0 : 1,
        }}
      />
    </AbsoluteFill>
  );
};

export const pageTurn = (): TransitionPresentation<PageTurnProps> => ({
  component: PageTurnPresentation,
  props: {},
});
