import React from 'react';
import {Page} from '../components/Page';
import {Cursor} from '../components/Cursor';
import {Figure} from '../components/Figure';
import {Caption, Headline, Kicker, Reveal} from '../components/Type';
import {REVEAL, scenes} from '../scenes';
import {MARGIN, sec} from '../tokens';

const FIG_W = 1000;
const FIG_H = 628;
const FIG_TOP = 226;

export const Live: React.FC = () => (
  <Page page={scenes.live.page} section="02 · Live Simulator">
    <div style={{position: 'absolute', left: MARGIN, width: 640, top: FIG_TOP}}>
      <Reveal at={REVEAL}>
        <Kicker accent>Feature 02</Kicker>
      </Reveal>
      <Headline
        lines={['A live Simulator in the session.', 'Devin taps, types and scrolls.']}
        at={REVEAL + 6}
        size={38}
        style={{marginTop: 28}}
      />
    </div>

    <div style={{position: 'absolute', left: MARGIN, width: 620, top: FIG_TOP + FIG_H - 62}}>
      <Reveal at={REVEAL + sec(0.9)}>
        <Caption n={2}>A native iPhone game running in the Simulator. Watch along, or tap it yourself.</Caption>
      </Reveal>
    </div>

    <div style={{position: 'absolute', right: MARGIN, top: FIG_TOP}}>
      <Figure
        width={FIG_W}
        height={FIG_H}
        aspect={3024 / 1898}
        at={REVEAL + sec(0.3)}
        duration={scenes.live.duration}
        push={[1, 1.05]}
        plates={[{src: 'screens/devin-desktop-9.png', at: 0}]}
      >
        <Cursor
          from={{x: 0.74, y: 0.52}}
          to={{x: 0.345, y: 0.69}}
          at={REVEAL + sec(1.4)}
          moveAt={REVEAL + sec(1.8)}
          arriveAt={sec(4.4)}
          clickAt={sec(4.7)}
        />
      </Figure>
    </div>
  </Page>
);
