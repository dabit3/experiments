import React from 'react';
import {AbsoluteFill} from 'remotion';
import {color, SAFE, MARGIN, sizes, tracking} from '../tokens';
import {mono} from '../fonts';
import {PAGE_COUNT} from '../scenes';

const pad = (n: number) => String(n).padStart(2, '0');

const meta: React.CSSProperties = {
  position: 'absolute',
  fontFamily: mono,
  fontSize: sizes.label,
  fontWeight: 400,
  letterSpacing: tracking.caps,
  textTransform: 'uppercase',
  color: color.gray500,
  lineHeight: 1,
  whiteSpace: 'nowrap',
};

const rule: React.CSSProperties = {
  position: 'absolute',
  left: MARGIN,
  right: MARGIN,
  height: 1,
  background: color.border,
};

type Props = {
  page: number;
  section: string;
  dark?: boolean;
  children: React.ReactNode;
};

// A magazine leaf: paper background, hairline rules, and page-number style
// metadata in the four corners. Content sits inside the 120px frame margin.
export const Page: React.FC<Props> = ({page, section, dark = false, children}) => {
  const ink = dark ? color.gray400 : color.gray500;
  const line = dark ? color.darkBorder : color.border;
  return (
    <AbsoluteFill style={{backgroundColor: dark ? color.darkBg : color.paper, color: dark ? color.paper : color.ink}}>
      <div style={{...rule, top: SAFE + 34, background: line}} />
      <div style={{...rule, bottom: SAFE + 34, background: line}} />

      <div style={{...meta, top: SAFE, left: MARGIN, color: ink}}>Devin — Issue 01</div>
      <div style={{...meta, top: SAFE, right: MARGIN, color: ink}}>{section}</div>
      <div style={{...meta, bottom: SAFE, left: MARGIN, color: ink}}>
        p. {pad(page)} <span style={{color: dark ? color.darkBorder : color.gray300}}>/</span> {pad(PAGE_COUNT)}
      </div>
      <div style={{...meta, bottom: SAFE, right: MARGIN, color: ink, textTransform: 'none'}}>devin.ai</div>

      <AbsoluteFill>{children}</AbsoluteFill>
    </AbsoluteFill>
  );
};
