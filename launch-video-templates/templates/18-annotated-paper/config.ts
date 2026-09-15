export const design = {
  surface: '#e9e7e1',
  paper: '#fffefb',
  ink: '#191919',
  muted: '#696962',
  blue: '#1971c2',
  highlighter: '#f5df79',
  mint: '#d5f0e8',
  coral: '#b44d3d',
  font: '"Helvetica Neue", Arial, sans-serif',
  handwriting: '"Chalkboard SE", "Comic Sans MS", cursive',
} as const;

export const scenes = [
  {id: 'hook', seconds: 4, eyebrow: 'A NEW CHAPTER', headline: 'Devin.\nNow on Mac.', detail: 'For your macOS and iOS apps.'},
  {id: 'context', seconds: 4, eyebrow: 'THE OLD LOOP', headline: 'QA meant\nwaiting.', detail: 'Manual checks. Long CI queues.'},
  {id: 'build', seconds: 5, eyebrow: '01 / BUILD + RUN', headline: 'Build it.\nRun it.', detail: 'In a managed Mac VM.'},
  {id: 'interact', seconds: 6, eyebrow: '02 / INTERACT', headline: 'Tap. Type.\nScroll.', detail: 'Devin works in iOS Simulator.'},
  {id: 'fix', seconds: 6, eyebrow: '03 / ITERATE', headline: 'Reproduce.\nFix. Retest.', detail: 'Work through the failure.'},
  {id: 'evidence', seconds: 6, eyebrow: '04 / REVIEW', headline: 'Review the\nrecording.', detail: 'See the action and the evidence.'},
  {id: 'outcome', seconds: 6, eyebrow: 'THE NEW LOOP', headline: 'A working app.\nYours to inspect.', detail: 'A live iPhone in your session.'},
  {id: 'end', seconds: 5, eyebrow: 'MACOS + IOS', headline: 'Build. Run. See it.', detail: 'macOS + iOS'},
] as const;

export const copy = {
  series: 'DEVIN / NATIVE APP FIELD NOTES',
  edition: '18 — ANNOTATED PAPER',
  illustrative: 'Illustrative workflow · supplied iOS stills',
  phoneNote: 'your iPhone app',
  contextNote: 'feedback comes later',
  manual: 'Manual QA',
  wait: '20+ min',
  waitCaption: 'waiting for CI feedback',
  priorContext: 'Prior workflow context · not a demo benchmark',
  managedNote: 'managed Mac',
  buildNote: 'build + test here',
  sourceReport: 'SOURCE REPORT / WISP SIMULATOR CHECKS',
  failureNote: 'a real failure',
  fixSteps: ['Reproduce the failure', 'Change the code', 'Run the check again'],
  failureCaveat: 'Source report includes failed and untested checks.',
  videoLabel: 'REAL RECORDING / WEB APP QA',
  videoCaveat: 'Generic web QA excerpt · not iOS footage',
  evidenceNote: 'review each step',
  price: 'Same price\nas Linux.',
  outcomeNote: 'inspect the app',
  sourceStill: 'SOURCE STILL / IPHONE SIMULATOR',
} as const;

export const interactions = [
  {label: 'Tap', note: 'start button', source: 'game', seconds: 2, focus: [970, 1188]},
  {label: 'Type', note: 'message field', source: 'wisp', seconds: 2, focus: [970, 1310]},
  {label: 'Scroll', note: 'charts list', source: 'charts', seconds: 2, focus: [975, 700]},
] as const;

export const media = {
  charts: {src: 'assets/devin-web-18.png', width: 2978, height: 1626, crop: [660, 212, 630, 1220]},
  game: {src: 'assets/devin-web-14.png', width: 2986, height: 1626, crop: [660, 247, 630, 1130]},
  wisp: {src: 'assets/devin-web-10.png', width: 2990, height: 1624, crop: [660, 212, 630, 1220]},
  session: {src: 'assets/devin-web-13.png', width: 2982, height: 1620},
  testingVideo: 'assets/devin-testing-2.mp4',
  videoStartSeconds: 12,
  logo: 'assets/logo-black.png',
} as const;

export const phoneLayout = {
  x: 1120, y: 154, width: 535, height: 836, angle: 1.5,
  imageX: 82, imageY: 64, imageWidth: 370,
} as const;

export const timing = {
  fps: 30,
  entranceFrames: 18,
  inkFrames: 24,
  noteFrames: 12,
} as const;

export const durationSeconds = scenes.reduce((total, scene) => total + scene.seconds, 0);
