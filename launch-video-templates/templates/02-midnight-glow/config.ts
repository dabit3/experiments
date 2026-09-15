export const config = {
  transitionFrames: 18,
  colors: {
    background: '#050609',
    surface: '#0d1017',
    foreground: '#f5f5f7',
    secondary: '#a1a8b8',
    accent: '#b9a1ed',
    border: 'rgba(223,230,255,0.16)',
  },
  scenes: [
    {id: 'hook', seconds: 5, eyebrow: 'A NEW ENVIRONMENT', title: 'Devin goes\nnative.', detail: 'Your Mac and iPhone apps.\nNow in Devin.'},
    {id: 'context', seconds: 4, eyebrow: 'THE OLD LOOP', title: 'Build. Wait.\nTest by hand.', detail: 'Manual QA. Or 20+ minutes for CI feedback.'},
    {id: 'build', seconds: 6, eyebrow: '01 / BUILD + RUN', title: 'Build and run.\nOn macOS.', detail: 'A managed Mac VM.\nXcode and Simulator, together.'},
    {id: 'interact', seconds: 6, eyebrow: '02 / INTERACT', title: 'Tap.\nType.\nScroll.', detail: 'Inside iOS Simulator.'},
    {id: 'retest', seconds: 6, eyebrow: '03 / CLOSE THE LOOP', title: 'Reproduce.\nFix.\nRetest.', detail: 'Keep the failure in view.'},
    {id: 'evidence', seconds: 6, eyebrow: '04 / REVIEW', title: 'See what\nhappened.', detail: 'Review recorded evidence.'},
    {id: 'outcome', seconds: 5, eyebrow: 'THE RESULT', title: 'A working app.\nIn your session.', detail: 'Same price as Linux VMs.'},
    {id: 'end', seconds: 4, eyebrow: 'MACOS + IOS', title: 'Build. Run. See it.', detail: 'Devin on macOS + iOS'},
  ],
  labels: {
    native: 'Illustrative workflow · supplied iOS screenshot',
    staged: 'Illustrative workflow',
    video: 'Actual recording · web-app QA',
    livePhone: 'Live iPhone in session',
    mac: 'Managed Mac VM',
    simulator: 'Open in Simulator',
    review: 'Recorded steps',
  },
  video: {
    file: 'assets/devin-testing-2.mp4',
    startSeconds: 11,
  },
} as const;

export type Scene = (typeof config.scenes)[number];
