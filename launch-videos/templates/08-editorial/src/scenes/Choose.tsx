import React from 'react';
import {Page} from '../components/Page';
import {Cursor} from '../components/Cursor';
import {Figure} from '../components/Figure';
import {Caption, Headline, Kicker, Reveal} from '../components/Type';
import {REVEAL, scenes} from '../scenes';
import {MARGIN, sec, sizes} from '../tokens';

const FIG_W = 957;
const FIG_H = 520;
const FIG_TOP = 378;

export const Choose: React.FC = () => (
  <Page page={scenes.choose.page} section="01 · Build and run">
    <div style={{position: 'absolute', left: MARGIN, right: MARGIN, top: 168}}>
      <Reveal at={REVEAL}>
        <Kicker accent>Feature 01</Kicker>
      </Reveal>
      <Headline
        lines={['Choose macOS.', 'Devin builds and runs the app in Xcode and the Simulator.']}
        at={REVEAL + 6}
        size={sizes.h2}
        style={{marginTop: 28}}
      />
    </div>

    <div style={{position: 'absolute', left: MARGIN, top: FIG_TOP + FIG_H - 62, width: 600}}>
      <Reveal at={REVEAL + sec(0.9)}>
        <Caption n={1}>A new session on macOS. Devin plans the work and starts executing.</Caption>
      </Reveal>
    </div>

    <div style={{position: 'absolute', right: MARGIN, top: FIG_TOP}}>
      <Figure
        width={FIG_W}
        height={FIG_H}
        aspect={2988 / 1622}
        crop={{x: 0.17, y: 0.2, w: 0.66}}
        at={REVEAL + sec(0.4)}
        duration={scenes.choose.duration}
        push={[1, 1.03]}
        plates={[
          {src: 'screens/devin-web-4.png', at: 0},
          {src: 'screens/devin-web-1.png', at: sec(3.4)},
          {src: 'screens/devin-web-13.png', at: sec(5.6), crop: {x: 0.2, y: 0.37, w: 0.6}},
        ]}
        fade={sec(0.45)}
      >
        <Cursor
          from={{x: 0.6, y: 0.5}}
          to={{x: 0.262, y: 0.728}}
          at={REVEAL + sec(0.9)}
          moveAt={REVEAL + sec(1.2)}
          arriveAt={sec(2.7)}
          clickAt={sec(2.9)}
          hideAt={sec(3.25)}
        />
      </Figure>
    </div>
  </Page>
);
