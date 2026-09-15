export const edit = {
  fps: 30,
  durationSeconds: 42,
  accent: '#1971c2',
  font: '"Arial Black", "Helvetica Neue", Arial, sans-serif',
  bodyFont: '"Helvetica Neue", Arial, sans-serif',
  scenes: [
    {id: 'hook', start: 0, end: 4.5, label: 'DEVIN / macOS + iOS', title: 'Your apps.\nNow in reach.'},
    {id: 'context', start: 4.5, end: 8.5, label: 'THE OLD WORKFLOW', title: 'Manual QA.\nOr 20+ min\nof CI.'},
    {id: 'build', start: 8.5, end: 14, label: '01 / BUILD + RUN', title: 'Native apps.\nManaged\nMac VMs.'},
    {id: 'interact', start: 14, end: 19.5, label: '02 / INTERACT', title: 'Tap.\nType.\nScroll.'},
    {id: 'repair', start: 19.5, end: 25.5, label: '03 / ITERATE', title: 'Reproduce.\nFix.\nRetest.'},
    {id: 'evidence', start: 25.5, end: 32, label: '04 / REVIEW', title: 'Watch the\nwork.'},
    {id: 'outcome', start: 32, end: 38, label: 'THE OUTCOME', title: 'A working app.\nIn your session.'},
    {id: 'end', start: 38, end: 42, label: 'macOS + iOS', title: 'Build. Run. See it.'},
  ],
  entranceFrames: 19,
  wipeFrames: 13,
  evidenceVideoStartSeconds: 6,
  labels: {
    illustrative: 'Illustrative workflow · supplied iOS screenshot',
    sourceVideo: 'Actual recording · web-app QA example',
    sourceNative: 'Supplied native iPhone review',
    price: 'Same price as Linux VMs.',
  },
} as const;

export type Scene = (typeof edit.scenes)[number];
