import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {Page} from '../components/Page';
import {Headline, Kicker, Reveal} from '../components/Type';
import {scenes} from '../scenes';
import {ms, sizes} from '../tokens';

export const Hook: React.FC = () => (
  <Page page={scenes.hook.page} section="macOS · native iOS">
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
      <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 44, marginTop: -20}}>
        <Reveal at={2} rise={16}>
          <Img src={staticFile('brand/devin-mark-black.png')} style={{width: 44, height: 44, display: 'block'}} />
        </Reveal>
        <Reveal at={ms(200)} rise={16}>
          <Kicker>Issue 01 · Devin on Mac</Kicker>
        </Reveal>
        <Headline lines={['Devin now runs on Mac.']} at={ms(420)} size={sizes.hero} style={{textAlign: 'center'}} />
      </div>
    </AbsoluteFill>
  </Page>
);
