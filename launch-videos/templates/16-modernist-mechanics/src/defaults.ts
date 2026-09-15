import type {LaunchProps} from './schema';

// Devin brand tokens — see launch-videos/brief/brand.md
export const defaultBrand: LaunchProps['brand'] = {
  paper: '#F7F6F5',
  surface: '#EFEFEF',
  line: '#E7E7E7',
  ink: '#191919',
  inkMuted: '#7D7D7D',
  inkSubtle: '#919191',
  accent: '#2200FF',
  white: '#FFFFFF',
  fontFamily: '"NB International Pro", "Inter", "Helvetica Neue", Arial, sans-serif',
  monoFontFamily: '"Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  logoLight: 'logos/devin-lockup-horizontal-black.png',
  logoDark: 'logos/devin-lockup-horizontal-white.png',
};

// Test launch copy — see launch-videos/brief/launch-mac-vm.md (verbatim)
export const defaultContent: LaunchProps['content'] = {
  featureName: 'Devin on Mac',
  eyebrow: 'New',
  headline: 'Devin now runs in a Mac VM',
  headlineAccent: 'Mac VM',
  subhead:
    'Build, run, and test Mac and iOS apps in a cloud Mac — with a live iPhone Simulator in your session.',
  captions: [
    'Pick macOS when you start a session — same price as Linux.',
    'Devin builds the app in Xcode and runs the full test suite.',
    'It taps, types, and scrolls through the app like a person.',
    'Watch it live in the iPhone Simulator tab — and tap in yourself.',
    'Reproduce a bug, fix it, and prove the fix on screen.',
    'Check iPhone and iPad sizes, dark mode, and orientations.',
    'Ship with a PR that shows the app working — not a 20-minute CI wait.',
  ],
  useCases: [
    'Build & test a feature',
    'Reproduce & fix a bug',
    'QA before shipping',
    'Screens, sizes & dark mode',
    'Upgrade Swift & dependencies',
  ],
  stages: ['Request', 'Build', 'Run & test', 'Verify', 'PR'],
  cta: {label: 'Start a Mac session', url: 'app.devin.ai'},
  outroLine: 'The only coding agent with a cloud Mac.',
  speedBadge: '3x',
};

// Media slots — every path is relative to launch-videos/assets (see brief/assets.md).
// Crops are fractions of the source; they only trim, never redraw.
export const defaultMedia: LaunchProps['media'] = [
  {
    name: 'pick',
    src: 'screenshots/devin-web-4.png',
    kind: 'image',
    width: 2988,
    height: 1622,
    crop: {x: 0.17, y: 0.2, w: 0.66, h: 0.64},
  },
  {
    name: 'work',
    src: 'screenshots/devin-web-13.png',
    kind: 'image',
    width: 2982,
    height: 1620,
  },
  {
    name: 'simulator',
    // macOS desktop with iPhone Simulator + Android emulator; cropped to the iPhone.
    src: 'recordings/androidios.mp4',
    kind: 'video',
    width: 1920,
    height: 1148,
    startFrom: 0,
    crop: {x: 0.163, y: 0.145, w: 0.19, h: 0.645},
  },
  {
    name: 'verify',
    src: 'recordings/devin-testing-2.mp4',
    kind: 'video',
    width: 1918,
    height: 1080,
    startFrom: 0,
  },
  {
    name: 'ipad',
    src: 'screenshots/devin-web-19.png',
    kind: 'image',
    width: 2982,
    height: 1626,
    crop: {x: 0.07, y: 0.13, w: 0.515, h: 0.735},
  },
  {
    name: 'darkPhone',
    src: 'screenshots/devin-web-18.png',
    kind: 'image',
    width: 2978,
    height: 1626,
    crop: {x: 0.225, y: 0.125, w: 0.2, h: 0.76},
  },
  {
    name: 'result',
    src: 'screenshots/devin-web-12.png',
    kind: 'image',
    width: 2978,
    height: 1622,
    crop: {x: 0, y: 0, w: 1, h: 0.84},
  },
];

// 1350 frames = 45s at 30fps
export const defaultScenes: LaunchProps['scenes'] = [
  {id: 'open', type: 'open', durationInFrames: 135},
  {
    id: 'pick',
    type: 'demo',
    durationInFrames: 150,
    composition: 'media-right',
    media: ['pick'],
    caption: 0,
    stage: 0,
    label: 'Choose macOS',
  },
  {
    id: 'build',
    type: 'demo',
    durationInFrames: 180,
    composition: 'media-left',
    media: ['work'],
    caption: 1,
    stage: 1,
    label: 'Build & test',
  },
  {
    id: 'taps',
    type: 'demo',
    durationInFrames: 225,
    composition: 'media-right',
    media: ['simulator'],
    caption: 2,
    stage: 2,
    label: 'iPhone Simulator',
    split: 0.5,
  },
  {
    id: 'verify',
    type: 'demo',
    durationInFrames: 210,
    composition: 'media-left',
    media: ['verify'],
    caption: 4,
    stage: 3,
    label: 'Test recording',
  },
  {
    id: 'sizes',
    type: 'demo',
    durationInFrames: 150,
    composition: 'tiles',
    media: ['ipad', 'darkPhone'],
    caption: 5,
    stage: 3,
    label: 'iPad · dark mode',
    split: 0.78,
  },
  {
    id: 'result',
    type: 'result',
    durationInFrames: 180,
    media: 'result',
    caption: 6,
    stage: 4,
    label: 'Ready to merge',
  },
  {id: 'outro', type: 'outro', durationInFrames: 120, media: 'result'},
];

export const defaultShapes: LaunchProps['shapes'] = {
  frame: {fill: '#191919', border: '#E7E7E7', borderWidth: 1},
  rule: {color: '#E7E7E7', progressColor: '#2200FF', thickness: 2, y: 920},
  tiles: {size: 14, fill: '#D6D6D6', activeFill: '#191919'},
  plane: {fill: '#191919', text: '#FFFFFF', textMuted: '#919191', padding: 40, captionSize: 34},
};

export const defaultMotion: LaunchProps['motion'] = {
  transitionFrames: 20,
  entranceFrames: 14,
  slideDistance: 48,
  stagger: 3,
};

export const defaultLayout: LaunchProps['layout'] = {
  margin: 96,
  gutter: 24,
  radius: 16,
  defaultSplit: 0.68,
  maxPlaneWidth: 640,
};

export const defaultProps: LaunchProps = {
  brand: defaultBrand,
  content: defaultContent,
  media: defaultMedia,
  scenes: defaultScenes,
  shapes: defaultShapes,
  motion: defaultMotion,
  layout: defaultLayout,
};
