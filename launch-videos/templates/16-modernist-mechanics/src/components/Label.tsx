import React from 'react';
import type {Brand} from '../schema';

/** Eyebrow / literal label in mono, uppercase, tracked. */
export const Eyebrow: React.FC<{
  brand: Brand;
  color: string;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({brand, color, children, style}) => (
  <div
    style={{
      fontFamily: brand.monoFontFamily,
      fontSize: 14,
      lineHeight: '20px',
      letterSpacing: 1.4,
      textTransform: 'uppercase',
      fontWeight: 500,
      color,
      ...style,
    }}
  >
    {children}
  </div>
);

/** Headline with an optional accent substring in brand.accent. */
export const AccentText: React.FC<{text: string; accent: string; accentColor: string}> = ({
  text,
  accent,
  accentColor,
}) => {
  const i = accent ? text.indexOf(accent) : -1;
  if (i < 0) {
    return <>{text}</>;
  }
  return (
    <>
      {text.slice(0, i)}
      <span style={{color: accentColor}}>{accent}</span>
      {text.slice(i + accent.length)}
    </>
  );
};
