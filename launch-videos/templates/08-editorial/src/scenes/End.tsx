import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {Page} from '../components/Page';
import {Reveal} from '../components/Type';
import {sans} from '../fonts';
import {REVEAL, scenes} from '../scenes';
import {color, ms, sizes, tracking} from '../tokens';

export const End: React.FC = () => (
  <Page page={scenes.end.page} section="Fin">
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
      <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 36, marginTop: -16}}>
        <Reveal at={REVEAL} rise={16}>
          <Img src={staticFile('brand/devin-lockup-horizontal-black.png')} style={{width: 520, display: 'block'}} />
        </Reveal>
        <Reveal at={REVEAL + ms(350)} rise={16}>
          <div
            style={{
              fontFamily: sans,
              fontWeight: 400,
              fontSize: sizes.body,
              letterSpacing: tracking.body,
              color: color.gray500,
            }}
          >
            Build, run and test iOS apps in the cloud.
          </div>
        </Reveal>
      </div>
    </AbsoluteFill>
  </Page>
);
