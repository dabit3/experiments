export const config = {
  transitionFrames: 20,
  copyFadeFrames: 10,
  featureRevealFrame: 48,
  featureRevealDuration: 24,
  featureTitleFadeFrames: 12,
  featureMediaDelayFrames: 8,
  pushIn: 1.04,
  background: '#fcfcfc',
  font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
  scenes: [
    {id: 'hook', seconds: 5, headline: 'Devin.\nNow for Mac.\nAnd iPhone.'},
    {id: 'context', seconds: 4, headline: 'Manual QA.\nOr 20+ minutes\nwaiting for CI.'},
    {
      id: 'build',
      seconds: 6,
      headline: 'Build it.\nRun it.',
      subline: 'On a managed Mac VM.',
      asset: 'assets/devin-web-14.png',
    },
    {
      id: 'interact',
      seconds: 6,
      headline: 'Tap. Type. Scroll.',
      subline: 'In iOS Simulator.',
      asset: 'assets/devin-web-10.png',
    },
    {
      id: 'fix',
      seconds: 6,
      headline: 'Reproduce.\nFix. Retest.',
      subline: '',
      asset: 'assets/devin-web-11.png',
    },
    {
      id: 'evidence',
      seconds: 6,
      headline: 'Review the evidence.',
      subline: '',
      asset: 'assets/devin-testing-2.mp4',
      videoStartSeconds: 7,
    },
    {
      id: 'outcome',
      seconds: 6,
      headline: 'A working app.\nLive in your\nsession.',
      priceHeadline: 'Same price\nas Linux VMs.',
      priceRevealFrame: 90,
    },
    {id: 'end', seconds: 5, headline: 'macOS + iOS', cta: 'Build. Run. See it.'},
  ],
} as const;

export type Scene = (typeof config.scenes)[number];
