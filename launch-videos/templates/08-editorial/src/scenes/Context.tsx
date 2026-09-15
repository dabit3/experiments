import React from 'react';
import {Page} from '../components/Page';
import {Headline, Kicker, Reveal} from '../components/Type';
import {REVEAL, scenes} from '../scenes';
import {MARGIN, sec} from '../tokens';

const SWAP = sec(3.1);

export const Context: React.FC = () => (
  <Page page={scenes.context.page} section="The problem">
    <div style={{position: 'absolute', left: MARGIN, right: MARGIN, top: 330}}>
      <Reveal at={REVEAL}>
        <Kicker accent>Before today</Kicker>
      </Reveal>
      <div style={{position: 'relative', marginTop: 56, height: 200}}>
        <Headline
          lines={['iOS teams QA’d the app by hand,', 'or waited 20+ minutes for CI.']}
          at={REVEAL + 6}
          out={SWAP}
          style={{position: 'absolute', inset: 0}}
        />
        <Headline
          lines={['No coding agent could build, run', 'and tap through an iPhone app.']}
          at={SWAP + sec(0.55)}
          style={{position: 'absolute', inset: 0}}
        />
      </div>
    </div>
  </Page>
);
