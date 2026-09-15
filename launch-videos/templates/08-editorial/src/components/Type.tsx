import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {color, easeIn, easeOut, ms, sizes, tracking} from '../tokens';
import {mono, serif} from '../fonts';

type RevealProps = {
  at: number;
  out?: number;
  rise?: number;
  duration?: number;
  style?: React.CSSProperties;
  children: React.ReactNode;
};

// Fade + rise entrance (ease-out). If `out` is given the element fades away
// again (ease-in) starting at that frame.
export const Reveal: React.FC<RevealProps> = ({at, out, rise = 28, duration = ms(800), style, children}) => {
  const frame = useCurrentFrame();
  const enter = interpolate(frame, [at, at + duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeOut,
  });
  const exit =
    out === undefined
      ? 1
      : interpolate(frame, [out, out + ms(400)], [1, 0], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
          easing: easeIn,
        });
  return (
    <div
      style={{
        opacity: enter * exit,
        transform: `translateY(${(1 - enter) * rise}px)`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

// Small-caps subhead, the editorial "kicker" above a headline.
export const Kicker: React.FC<{children: React.ReactNode; accent?: boolean; style?: React.CSSProperties}> = ({
  children,
  accent = false,
  style,
}) => (
  <div
    style={{
      fontFamily: mono,
      fontSize: sizes.label,
      fontWeight: 500,
      letterSpacing: tracking.caps,
      textTransform: 'uppercase',
      color: accent ? color.accent : color.gray500,
      lineHeight: 1,
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      ...style,
    }}
  >
    {accent ? <span style={{display: 'inline-block', width: 28, height: 1, background: color.accent}} /> : null}
    <span>{children}</span>
  </div>
);

type HeadlineProps = {
  lines: string[];
  at: number;
  out?: number;
  size?: number;
  stagger?: number;
  style?: React.CSSProperties;
};

// Serif headline revealed one line at a time. Medium weight, tight tracking.
export const Headline: React.FC<HeadlineProps> = ({lines, at, out, size = sizes.h1, stagger = ms(140), style}) => (
  <div
    style={{
      fontFamily: serif,
      fontWeight: 500,
      fontSize: size,
      lineHeight: 1.08,
      letterSpacing: size >= sizes.h1 ? tracking.hero : tracking.heading,
      color: 'inherit',
      ...style,
    }}
  >
    {lines.map((line, i) => (
      <Reveal key={line} at={at + i * stagger} out={out === undefined ? undefined : out + i * ms(60)}>
        {line}
      </Reveal>
    ))}
  </div>
);

// Photo-style caption: "Fig. 03" in mono, description in italic serif.
export const Caption: React.FC<{n: number; children: React.ReactNode; style?: React.CSSProperties}> = ({
  n,
  children,
  style,
}) => (
  <div style={{display: 'flex', alignItems: 'baseline', gap: 20, ...style}}>
    <span
      style={{
        fontFamily: mono,
        fontSize: sizes.label,
        fontWeight: 500,
        letterSpacing: tracking.caps,
        textTransform: 'uppercase',
        color: color.accent,
        whiteSpace: 'nowrap',
      }}
    >
      Fig. {String(n).padStart(2, '0')}
    </span>
    <span
      style={{
        fontFamily: serif,
        fontStyle: 'italic',
        fontWeight: 400,
        fontSize: sizes.caption,
        color: color.gray500,
        lineHeight: 1.35,
      }}
    >
      {children}
    </span>
  </div>
);
