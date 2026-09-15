import React from 'react';
import {Page} from '../components/Page';
import {Figure} from '../components/Figure';
import {Caption, Headline, Kicker, Reveal} from '../components/Type';
import {REVEAL, scenes} from '../scenes';
import {MARGIN, sec, sizes} from '../tokens';

const FIG_W = 800;
const FIG_H = 560;
const FIG_TOP = 338;
const LEFT_H = 520;
const GAP = 80;

export const Matrix: React.FC = () => (
  <Page page={scenes.matrix.page} section="04 · Every screen">
    <div style={{position: 'absolute', left: MARGIN, right: MARGIN, top: 150}}>
      <Reveal at={REVEAL}>
        <Kicker accent>Feature 04</Kicker>
      </Reveal>
      <Headline
        lines={['Every size, dark mode, every orientation —', 'compared pixel for pixel.']}
        at={REVEAL + 6}
        size={sizes.h2}
        style={{marginTop: 24}}
      />
    </div>

    {/* Bottom-aligned with the iPad figure so both captions share a baseline. */}
    <div style={{position: 'absolute', left: MARGIN, top: FIG_TOP + (FIG_H - LEFT_H)}}>
      <Figure
        width={FIG_W}
        height={LEFT_H}
        aspect={2978 / 1620}
        crop={{x: 0.135, y: 0.36, w: 0.535}}
        at={REVEAL + sec(0.4)}
        duration={scenes.matrix.duration}
        push={[1, 1.05]}
        dark
        plates={[{src: 'screens/devin-web-17.png', at: 0}]}
      />
      <Reveal at={REVEAL + sec(1.0)} style={{marginTop: 20, width: FIG_W}}>
        <Caption n={4}>Six iPhone states, including dark mode, in one review.</Caption>
      </Reveal>
    </div>

    <div style={{position: 'absolute', left: MARGIN + FIG_W + GAP, top: FIG_TOP}}>
      <Figure
        width={FIG_W}
        height={FIG_H}
        aspect={2982 / 1626}
        crop={{x: 0.02, y: 0.15, w: 0.595}}
        at={REVEAL + sec(0.7)}
        duration={scenes.matrix.duration}
        push={[1, 1.05]}
        plates={[{src: 'screens/devin-web-19.png', at: 0}]}
      />
      <Reveal at={REVEAL + sec(1.3)} style={{marginTop: 20, width: FIG_W}}>
        <Caption n={5}>The same acceptance flow on iPad Pro.</Caption>
      </Reveal>
    </div>
  </Page>
);
