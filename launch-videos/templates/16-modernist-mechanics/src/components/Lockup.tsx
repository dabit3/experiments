import React from 'react';
import {Img, staticFile} from 'remotion';

/** Whole-lockup only: never animate or recolor the mark's geometry. */
export const Lockup: React.FC<{
  src: string;
  height: number;
  style?: React.CSSProperties;
}> = ({src, height, style}) => (
  <Img
    src={staticFile(src)}
    style={{height, width: 'auto', display: 'block', ...style}}
  />
);
