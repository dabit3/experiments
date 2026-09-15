export type SceneKind = 'hook' | 'context' | 'build' | 'interact' | 'fix' | 'evidence' | 'outcome' | 'end';

export const config = {
  split: 800,
  font: '"Helvetica Neue", Arial, sans-serif',
  mono: '"SFMono-Regular", Menlo, Consolas, monospace',
  ink: '#191919',
  paper: '#fcfcfc',
  stage: '#102229',
  mint: '#bfe9d9',
  muted: '#63706f',
  scenes: [
    {kind: 'hook', seconds: 4, nav: 'INTRO', eyebrow: 'A NEW WORKSPACE', headline: 'Your app.\nNow in\nDevin’s hands.', prompt: 'Build my iPhone app.', foot: 'Devin on macOS + iOS', stageTitle: 'Native apps. Visible execution.'},
    {kind: 'context', seconds: 4, nav: 'BEFORE', eyebrow: 'THE OLD FEEDBACK LOOP', headline: 'Manual QA.\nOr another\nCI wait.', prompt: 'Is this ready to review?', foot: 'Before: 20+ minutes for CI feedback', stageTitle: 'The next step used to be yours.'},
    {kind: 'build', seconds: 5, nav: 'BUILD', eyebrow: '01 / BUILD + RUN', headline: 'A Mac VM.\nA running app.', prompt: 'Build and run this app\non a managed Mac VM.', foot: 'Native macOS + iOS development', stageTitle: 'A Mac workspace for Devin.'},
    {kind: 'interact', seconds: 6, nav: 'INTERACT', eyebrow: '02 / USE THE SIMULATOR', headline: 'Tap.\nType.\nScroll.', prompt: 'Try the app in iOS Simulator.', foot: 'A live iPhone inside the session', stageTitle: 'Devin interacts with the app.'},
    {kind: 'fix', seconds: 6, nav: 'ITERATE', eyebrow: '03 / CLOSE THE LOOP', headline: 'Reproduce.\nFix.\nRetest.', prompt: 'Reproduce the bug.\nFix it. Run the checks again.', foot: 'Keep the work in one session', stageTitle: 'Follow through on the finding.'},
    {kind: 'evidence', seconds: 6, nav: 'REVIEW', eyebrow: '04 / REVIEW THE EVIDENCE', headline: 'See what\nhappened.', prompt: 'Show me the recorded checks.', foot: 'Recordings and screenshots to inspect', stageTitle: 'Execution leaves a visible record.'},
    {kind: 'outcome', seconds: 5, nav: 'OUTCOME', eyebrow: 'FROM INTENT TO INSPECTION', headline: 'A working app.\nReady to\ninspect.', prompt: 'Let me see the app.', foot: 'Same price as Linux VMs', stageTitle: 'Your app, inside the session.'},
    {kind: 'end', seconds: 4, nav: 'DEVIN', eyebrow: 'DEVIN ON macOS + iOS', headline: 'Build.\nRun.\nSee it.', prompt: 'Start with your app.', foot: 'Same price as Linux VMs', stageTitle: 'macOS + iOS'},
  ] satisfies Array<{
    kind: SceneKind;
    seconds: number;
    nav: string;
    eyebrow: string;
    headline: string;
    prompt: string;
    foot: string;
    stageTitle: string;
  }>,
} as const;

export const media = {
  charts: {file: 'devin-web-18.png', width: 2978, height: 1626, x: 677, y: 227, cropWidth: 590, cropHeight: 1198},
  chat: {file: 'devin-web-10.png', width: 2990, height: 1624, x: 681, y: 228, cropWidth: 589, cropHeight: 1190},
  game: {file: 'devin-web-14.png', width: 2986, height: 1626, x: 697, y: 249, cropWidth: 549, cropHeight: 1113},
  session: 'devin-web-13.png',
  evidence: 'devin-testing-2.mp4',
  evidenceStartSeconds: 14,
} as const;
