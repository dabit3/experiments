export const studio = {
  fadeFrames: 24,
  font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
  colors: {
    cream: '#F4F1EA',
    ink: '#302F2B',
    muted: '#726E65',
    stone: '#E7E4DB',
    sage: '#D7DFD1',
    clay: '#BC927A',
    light: '#FCFAF5',
    line: '#D7D2C7',
  },
  scenes: [
    {
      key: 'hook',
      seconds: 5,
      label: 'A LITTLE MORE POSSIBILITY',
      title: 'Your next app.\nNow with Devin.',
      detail: 'Your macOS + iOS workflow, together.',
    },
    {
      key: 'context',
      seconds: 4,
      label: 'A FAMILIAR FEELING',
      title: 'You know the wait.',
      detail: 'Manual QA. Long CI feedback loops.',
    },
    {
      key: 'build',
      seconds: 5.5,
      label: '01 / BUILD & RUN',
      title: 'You bring the idea.\nDevin builds and runs.',
      detail: 'Native macOS + iOS apps.\nOn a managed Mac VM.',
    },
    {
      key: 'interact',
      seconds: 6,
      label: '02 / INTERACT',
      title: 'You can see\nevery interaction.',
      detail: 'Inside iOS Simulator.',
    },
    {
      key: 'fix',
      seconds: 5.5,
      label: '03 / WORK IT THROUGH',
      title: 'You spot a rough edge.\nDevin works it through.',
      detail: 'Reproduce. Fix. Retest.',
    },
    {
      key: 'evidence',
      seconds: 6,
      label: '04 / REVIEW',
      title: 'You get\nthe evidence.',
      detail: 'Review the recording.\nSee what happened.',
    },
    {
      key: 'outcome',
      seconds: 5,
      label: 'RIGHT HERE IN YOUR SESSION',
      title: 'Your working app.\nRight here with you.',
      detail: 'A live iPhone Simulator you can inspect.',
    },
    {
      key: 'end',
      seconds: 5,
      label: 'DEVIN FOR MACOS + IOS',
      title: 'Your next app starts here.',
      detail: 'Build. Run. See it.',
    },
  ],
} as const;

export type Scene = (typeof studio.scenes)[number];
