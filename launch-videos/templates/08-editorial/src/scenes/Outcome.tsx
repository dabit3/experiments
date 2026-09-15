import React from 'react';
import {Page} from '../components/Page';
import {Kicker, Reveal} from '../components/Type';
import {mono, serif} from '../fonts';
import {REVEAL, scenes} from '../scenes';
import {color, MARGIN, ms, sizes, tracking} from '../tokens';

const rows = [
  'Minutes, not 20+ minute CI round-trips.',
  'The only coding agent with a Mac cloud agent.',
  'Same security as Linux and Windows VMs.',
  'No price increase — same as Linux cloud sessions.',
];

const STAGGER = ms(380);

// Table-of-contents style ledger of outcomes.
export const Outcome: React.FC = () => (
  <Page page={scenes.outcome.page} section="The outcome">
    <div style={{position: 'absolute', left: MARGIN, right: MARGIN, top: 220}}>
      <Reveal at={REVEAL}>
        <Kicker accent>What changes</Kicker>
      </Reveal>
      <div style={{marginTop: 40}}>
        {rows.map((row, i) => (
          <Reveal key={row} at={REVEAL + ms(300) + i * STAGGER} rise={20}>
            <div
              style={{
                display: 'flex',
                alignItems: 'baseline',
                gap: 64,
                padding: '42px 0',
                borderTop: `1px solid ${color.border}`,
                borderBottom: i === rows.length - 1 ? `1px solid ${color.border}` : undefined,
              }}
            >
              <span
                style={{
                  fontFamily: mono,
                  fontSize: sizes.label,
                  fontWeight: 500,
                  letterSpacing: tracking.caps,
                  color: color.gray500,
                  width: 48,
                  flexShrink: 0,
                }}
              >
                {String(i + 1).padStart(2, '0')}
              </span>
              <span
                style={{
                  fontFamily: serif,
                  fontWeight: 500,
                  fontSize: sizes.h3,
                  letterSpacing: tracking.heading,
                  lineHeight: 1.1,
                }}
              >
                {row}
              </span>
            </div>
          </Reveal>
        ))}
      </div>
    </div>
  </Page>
);
