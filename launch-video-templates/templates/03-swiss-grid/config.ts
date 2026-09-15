export const design = {
  font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
  sizes: {headline: 112, body: 48, label: 24},
  ink: '#191919',
  paper: '#fcfcfc',
  accent: '#1971c2',
  muted: '#747474',
  margin: 96,
  column: 122,
  gutter: 24,
  entranceFrames: 18,
  transitionFrames: 12,
} as const;

export const scenes = [
  {
    id: 'hook',
    seconds: 4.5,
    section: 1,
    label: 'DEVIN / NATIVE DEVELOPMENT',
    headline: 'Devin runs\nMac + iOS.',
    detail: 'Your apps. Now within reach.',
    footer: 'Managed Mac VMs',
  },
  {
    id: 'context',
    seconds: 4,
    section: 1,
    label: 'THE OLD FEEDBACK LOOP',
    headline: 'Manual QA.\nOr wait for CI.',
    detail: 'Before the next fix.',
    footer: 'Prior workflow context',
  },
  {
    id: 'build',
    seconds: 5.5,
    section: 2,
    label: 'A / BUILD + RUN',
    headline: 'Build it.\nRun it.',
    detail: 'On a managed Mac VM.',
    footer: 'Illustrative workflow · supplied iOS screenshot',
  },
  {
    id: 'interact',
    seconds: 6,
    section: 2,
    label: 'B / IOS SIMULATOR',
    headline: 'Tap.\nType.\nScroll.',
    detail: 'Devin works in the app.',
    footer: 'Illustrative workflow · supplied iOS screenshots',
  },
  {
    id: 'repair',
    seconds: 6,
    section: 2,
    label: 'C / REPRODUCE + FIX + RETEST',
    headline: 'Find it.\nFix it.\nRetest.',
    detail: 'Keep the findings visible.',
    footer: 'Illustrative workflow · source includes failed checks',
  },
  {
    id: 'evidence',
    seconds: 5.5,
    section: 2,
    label: 'D / RECORDED EVIDENCE',
    headline: 'Review\nwhat\nhappened.',
    detail: 'See the actions.',
    footer: 'Source recording · generic web QA',
  },
  {
    id: 'outcome',
    seconds: 4.5,
    section: 3,
    label: 'THE RESULT',
    headline: 'A working app.\nIn your session.',
    detail: 'Same price as Linux.',
    footer: 'Live iPhone Simulator in the session',
  },
  {
    id: 'end',
    seconds: 4,
    section: 3,
    label: 'DEVIN / NOW ON MAC',
    headline: 'macOS + iOS.',
    detail: 'Build. Run. See it.',
    footer: 'Managed Mac VMs · same price as Linux',
  },
] as const;

export type Scene = (typeof scenes)[number];

export const media = {
  wispStart: {
    src: 'assets/devin-web-11.png',
    width: 2986,
    height: 1630,
    crop: {x: 680, y: 239, width: 580, height: 1185},
  },
  wispChat: {
    src: 'assets/devin-web-10.png',
    width: 2990,
    height: 1624,
    crop: {x: 682, y: 236, width: 580, height: 1185},
  },
  maze: {
    src: 'assets/devin-web-14.png',
    width: 2986,
    height: 1626,
    crop: {x: 699, y: 252, width: 555, height: 1100},
  },
  charts: {
    src: 'assets/devin-web-18.png',
    width: 2978,
    height: 1626,
    crop: {x: 682, y: 236, width: 580, height: 1190},
  },
  nativeEvidence: {
    src: 'assets/devin-web-10.png',
    width: 2990,
    height: 1624,
    crop: {x: 1981, y: 155, width: 1009, height: 1074},
  },
  qaVideo: 'assets/devin-testing-2.mp4',
  qaStartSeconds: 14,
  logo: 'assets/logo-black.png',
} as const;

export type CropSource = typeof media.wispStart | typeof media.wispChat |
  typeof media.maze | typeof media.charts | typeof media.nativeEvidence;
