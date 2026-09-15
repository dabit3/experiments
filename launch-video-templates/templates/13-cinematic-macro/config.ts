export const film = {
  aperture: {width: 1920, height: 804, top: 138},
  fadeFrames: 18,
  font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
  mono: '"SFMono-Regular", Menlo, monospace',
  colors: {
    background: '#060b10',
    white: '#fcfcfc',
    muted: '#a7b4bf',
    ice: '#a8d5e8',
    blue: '#1971c2',
    green: '#0ca678',
  },
  scenes: [
    {id: 'hook', start: 0, seconds: 4.5, eyebrow: 'DEVIN / macOS + iOS', headline: 'Devin goes native.', detail: 'Your Mac and iPhone apps. In focus.'},
    {id: 'context', start: 4.5, seconds: 4, eyebrow: 'BEFORE / THE FEEDBACK LOOP', headline: 'Manual QA. Or a CI wait.', detail: '20+ minutes for feedback.'},
    {id: 'build', start: 8.5, seconds: 5, eyebrow: '01 / BUILD + RUN', headline: 'A managed Mac. Ready to build.', detail: 'Build and run native apps with Devin.'},
    {id: 'interact', start: 13.5, seconds: 5.5, eyebrow: '02 / iOS SIMULATOR', headline: 'Tap. Type. Scroll.', detail: 'A live iPhone in your session.'},
    {id: 'fix', start: 19, seconds: 5.5, eyebrow: '03 / REPRODUCE + FIX + RETEST', headline: 'Close the loop.', detail: 'Reproduce the bug. Fix it. Test again.'},
    {id: 'evidence', start: 24.5, seconds: 5.5, eyebrow: '04 / RECORDED EVIDENCE', headline: 'See what happened.', detail: 'Review the recording and test evidence.'},
    {id: 'outcome', start: 30, seconds: 5.5, eyebrow: 'THE OUTCOME', headline: 'A working app. Yours to inspect.', detail: 'Same price as Linux VMs.'},
    {id: 'end', start: 35.5, seconds: 5, eyebrow: '', headline: 'macOS + iOS', detail: 'Build. Run. See it.'},
  ],
} as const;

export type Scene = (typeof film.scenes)[number];
