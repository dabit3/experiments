export type Scene = {
  id: string;
  beats: number;
  theme: 'ink' | 'paper' | 'mint';
  eyebrow: string;
  lines: string[];
  note: string;
  size: number;
  kind?: 'phone' | 'review' | 'video' | 'logo';
  phone?: 'maze' | 'wisp' | 'rescue';
  motion?: 'slam' | 'split';
};

export const config = {
  bpm: 120,
  framesPerBeat: 15,
  entranceFrames: 8,
  margin: 96,
  sourceVideoStartSeconds: 12,
  font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
  scenes: [
    {id: 'hook', beats: 5, theme: 'ink', eyebrow: 'A NEW CHAPTER FOR DEVIN', lines: ['YOUR NEXT', 'APP.'], note: 'The coding agent. Now for native apps.', size: 248, motion: 'slam'},
    {id: 'native-intro', beats: 5, theme: 'mint', eyebrow: 'DEVIN ON macOS + iOS', lines: ['MEET', 'DEVIN.'], note: 'Your iPhone app. In the session.', size: 238, kind: 'phone', phone: 'maze'},
    {id: 'manual', beats: 4, theme: 'paper', eyebrow: 'BEFORE / THE FEEDBACK LOOP', lines: ['MANUAL', 'QA.'], note: 'Test it yourself.', size: 252, motion: 'split'},
    {id: 'ci', beats: 4, theme: 'paper', eyebrow: 'BEFORE / THE FEEDBACK LOOP', lines: ['20+ MIN.'], note: 'Or wait for CI feedback.', size: 278, motion: 'slam'},
    {id: 'build', beats: 5, theme: 'ink', eyebrow: '01 / BUILD + RUN', lines: ['BUILD.', 'RUN.'], note: 'Native macOS + iOS apps. Managed Mac VMs.', size: 260, motion: 'split'},
    {id: 'run-insert', beats: 5, theme: 'mint', eyebrow: '01 / BUILD + RUN', lines: ['AN APP.', 'RUNNING.'], note: 'Built and run in a managed Mac VM.', size: 190, kind: 'phone', phone: 'maze'},
    {id: 'interact', beats: 4, theme: 'ink', eyebrow: '02 / iOS SIMULATOR', lines: ['TAP.', 'TYPE.', 'SCROLL.'], note: 'Devin interacts with your app.', size: 203, motion: 'split'},
    {id: 'simulator-insert', beats: 5, theme: 'paper', eyebrow: '02 / iOS SIMULATOR', lines: ['RIGHT', 'THERE.'], note: 'A live iPhone Simulator in the session.', size: 217, kind: 'phone', phone: 'wisp'},
    {id: 'reproduce', beats: 4, theme: 'ink', eyebrow: '03 / REPRODUCE → FIX → RETEST', lines: ['REPRODUCE.'], note: 'Find the bug in the app.', size: 206, motion: 'split'},
    {id: 'fix', beats: 2, theme: 'mint', eyebrow: '03 / REPRODUCE → FIX → RETEST', lines: ['FIX.'], note: 'Change the code.', size: 360, motion: 'slam'},
    {id: 'retest', beats: 3, theme: 'ink', eyebrow: '03 / REPRODUCE → FIX → RETEST', lines: ['RETEST.'], note: 'Run the workflow again.', size: 296, motion: 'slam'},
    {id: 'details-insert', beats: 5, theme: 'paper', eyebrow: '03 / REPRODUCE → FIX → RETEST', lines: ['SEE THE DETAILS.'], note: 'Inspect the actual checks. Including failures.', size: 98, kind: 'review'},
    {id: 'evidence', beats: 4, theme: 'ink', eyebrow: '04 / RECORDED EVIDENCE', lines: ['REVIEW THE', 'EVIDENCE.'], note: 'Watch what happened.', size: 213, motion: 'split'},
    {id: 'video-insert', beats: 5, theme: 'paper', eyebrow: '04 / RECORDED EVIDENCE', lines: ['WATCH IT BACK.'], note: 'Supplied web QA recording · Not iOS footage', size: 104, kind: 'video'},
    {id: 'outcome-insert', beats: 5, theme: 'mint', eyebrow: 'THE OUTCOME', lines: ['A WORKING', 'APP.'], note: 'An app you can inspect.', size: 174, kind: 'phone', phone: 'rescue'},
    {id: 'session', beats: 5, theme: 'ink', eyebrow: 'THE OUTCOME', lines: ['LIVE IN', 'YOUR SESSION.'], note: 'Build it. Run it. See it.', size: 199, motion: 'split'},
    {id: 'price', beats: 5, theme: 'mint', eyebrow: 'THE OUTCOME', lines: ['SAME PRICE', 'AS LINUX.'], note: 'Managed Mac VMs. Same price as Linux VMs.', size: 221, motion: 'slam'},
    {id: 'end', beats: 5, theme: 'ink', eyebrow: 'macOS + iOS', lines: ['Build. Run. See it.'], note: 'DEVIN', size: 64, kind: 'logo'},
  ] satisfies Scene[],
};

export const timeline = config.scenes.map((scene, index) => ({
  ...scene,
  from: config.scenes.slice(0, index).reduce((sum, item) => sum + item.beats * config.framesPerBeat, 0),
  duration: scene.beats * config.framesPerBeat,
}));
