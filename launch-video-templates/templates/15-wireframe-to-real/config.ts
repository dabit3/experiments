export const config = {
  fps: 30,
  durationSeconds: 40,
  resolveStart: 18,
  resolveFrames: 18,
  actionStart: 54,
  font: '"Helvetica Neue", Arial, sans-serif',
  mono: '"SFMono-Regular", Menlo, monospace',
  scenes: [
    {id: 'hook', start: 0, duration: 4, kicker: 'FROM IDEA TO APP', title: 'Your ideas.\nNow native.', detail: 'Devin on macOS + iOS.'},
    {id: 'context', start: 4, duration: 4, kicker: 'THE OLD WORKFLOW', title: 'Build. Wait.\nCheck by hand.', detail: 'Manual QA. Or 20+ minutes for CI feedback.'},
    {id: 'build', start: 8, duration: 6, kicker: '01 / BUILD + RUN', title: 'Make the\nidea run.', detail: 'Build and run in a managed Mac VM.'},
    {id: 'interact', start: 14, duration: 6, kicker: '02 / IOS SIMULATOR', title: 'Tap. Type.\nScroll.', detail: 'Devin interacts with your native app.'},
    {id: 'fix', start: 20, duration: 6, kicker: '03 / REPRODUCE + FIX + RETEST', title: 'Close the\nfeedback loop.', detail: 'Reproduce the bug. Fix it. Retest.'},
    {id: 'evidence', start: 26, duration: 6, kicker: '04 / RECORDED EVIDENCE', title: 'See what\nhappened.', detail: 'Review the recording and test notes.'},
    {id: 'outcome', start: 32, duration: 4, kicker: 'FROM IDEA TO INSPECTABLE', title: 'A working app.\nRight here.', detail: 'A live iPhone Simulator in your session.'},
    {id: 'end', start: 36, duration: 4, kicker: 'DEVIN ON MACOS + IOS', title: 'Build. Run. See it.', detail: 'Same price as Linux VMs.'},
  ],
  sourceVideo: {startSeconds: 14, sceneStartFrame: 66},
} as const;

export type Scene = (typeof config.scenes)[number];
