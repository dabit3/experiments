export const blueprint = {
  palette: {
    background: '#071c2b',
    panel: '#0b2838',
    ink: '#f3f8f9',
    secondary: '#adc6ce',
    accent: '#70dce8',
    rule: '#2b596b',
  },
  motion: {entranceFrames: 24, lineFrames: 12},
  recording: {source: 'assets/devin-testing-2.mp4', startSeconds: 15},
  scenes: [
    {
      key: 'hook',
      seconds: 5,
      label: 'Devin / macOS + iOS',
      headline: ['Devin.', 'Now native.'],
      detail: 'Your Mac and iPhone apps.\nInside the session.',
      drawing: 'Native workspace',
    },
    {
      key: 'context',
      seconds: 4,
      label: 'The prior workflow',
      headline: ['Manual QA.', 'Or a CI wait.'],
      detail: 'Feedback meant leaving the flow.',
      drawing: 'Before / feedback loop',
    },
    {
      key: 'build',
      seconds: 6,
      label: '01 / Build + run',
      headline: ['Build it.', 'Run it.'],
      detail: 'Managed Mac VMs.\nNative macOS and iOS apps.',
      drawing: 'Build / runtime assembly',
    },
    {
      key: 'interact',
      seconds: 6,
      label: '02 / Interact',
      headline: ['Tap.', 'Type. Scroll.'],
      detail: 'Devin works in iOS Simulator.',
      drawing: 'Simulator / input layer',
    },
    {
      key: 'iterate',
      seconds: 6,
      label: '03 / Reproduce + repair',
      headline: ['Reproduce.', 'Fix. Retest.'],
      detail: 'Keep the loop in the session.',
      drawing: 'Repair / closed loop',
    },
    {
      key: 'evidence',
      seconds: 6,
      label: '04 / Review evidence',
      headline: ['Review the', 'recording.'],
      detail: 'Inspect what happened.',
      drawing: 'Evidence / assembled view',
    },
    {
      key: 'outcome',
      seconds: 6,
      label: 'The outcome',
      headline: ['Working app.', 'In view.'],
      detail: 'A live iPhone in your session.',
      drawing: 'Native workspace / resolved',
    },
    {
      key: 'end',
      seconds: 5,
      label: 'macOS + iOS',
      headline: ['Build. Run. See it.'],
      detail: 'Same price as Linux VMs.',
      drawing: 'Devin / macOS + iOS',
    },
  ],
} as const;

export const FPS = 30;
export const durationInFrames = blueprint.scenes.reduce(
  (total, scene) => total + scene.seconds * FPS,
  0,
);
