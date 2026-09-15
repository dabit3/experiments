import React from 'react';
import {Page} from '../components/Page';
import {Figure} from '../components/Figure';
import {Caption, Headline, Kicker, Reveal} from '../components/Type';
import {REVEAL, scenes} from '../scenes';
import {MARGIN, sec, sizes} from '../tokens';

const FIG_W = 957;
const FIG_H = 520;
const FIG_TOP = 378;

export const Fix: React.FC = () => (
  <Page page={scenes.fix.page} section="03 · Reproduce, fix, ship">
    <div style={{position: 'absolute', left: MARGIN, right: MARGIN, top: 168}}>
      <Reveal at={REVEAL}>
        <Kicker accent>Feature 03</Kicker>
      </Reveal>
      <Headline
        lines={['Reproduce the bug. Fix it.', 'Re-run the UI tests. Open a PR.']}
        at={REVEAL + 6}
        size={sizes.h2}
        style={{marginTop: 28}}
      />
    </div>

    <div style={{position: 'absolute', left: MARGIN, top: FIG_TOP}}>
      <Figure
        width={FIG_W}
        height={FIG_H}
        aspect={2990 / 1624}
        at={REVEAL + sec(0.4)}
        duration={scenes.fix.duration}
        push={[1, 1.03]}
        plates={[
          {src: 'screens/devin-web-10.png', at: 0},
          {src: 'screens/devin-web-9.png', at: sec(4.0)},
        ]}
        fade={sec(0.5)}
      />
    </div>

    <div style={{position: 'absolute', right: MARGIN, width: 600, top: FIG_TOP + FIG_H - 62}}>
      <Reveal at={REVEAL + sec(0.9)}>
        <Caption n={3}>The Simulator run, its checks — and the pull request that followed.</Caption>
      </Reveal>
    </div>
  </Page>
);
