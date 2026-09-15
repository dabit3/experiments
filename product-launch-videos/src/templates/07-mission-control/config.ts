import {defaultLaunchConfig, logos, type LaunchConfig, type SceneId} from '../../shared';

export type BayConfig = {
  number: string;
  title: string;
  detail: string;
  sourceNote: string;
  scenes: SceneId[];
};

export type MissionControlConfig = LaunchConfig & {
  environmentSelector: {
    width: number;
    rowHeight: number;
    labelSize: number;
    surface: string;
    border: string;
    highlight: string;
    transitionStartRatio: number;
    transitionFrames: number;
    labels: {hosted: string; ubuntu: string; macos: string; windows: string};
  };
  panels: {
    primaryWidth: number;
    displayTop: number;
    displayHeight: number;
    headerHeight: number;
    railWidth: number;
    bayHeight: number;
    bayGap: number;
    logoWidth: number;
  };
  labels: {
    edition: string;
    primary: string;
    index: string;
    separateExamples: string;
    selected: string;
    reference: string;
    openingNote: string;
    closingNote: string;
    sceneSources: Record<SceneId, string>;
    bays: [BayConfig, BayConfig, BayConfig];
  };
  status: {
    activeBorder: string;
    inactiveBorder: string;
    secondaryText: string;
    activeFill: string;
    outlineWidth: number;
    showSelectionLabel: boolean;
  };
  motion: {
    apertureFrames: number;
    baySettleFrames: number;
    bayStaggerFrames: number;
    bayTravel: number;
    selectionFrames: number;
    consolidationFrames: number;
    openingWidthRatio: number;
    iphoneSplitRatio: number;
  };
};

const base = structuredClone(defaultLaunchConfig);

export const config: MissionControlConfig = {
  ...base,
  environmentSelector: {
    width: 840, rowHeight: 94, labelSize: 42,
    surface: '#ffffff', border: 'rgba(25,25,25,0.08)', highlight: '#edeceb',
    transitionStartRatio: 0.22, transitionFrames: 22,
    labels: {hosted: 'Hosted', ubuntu: 'Ubuntu', macos: 'macOS', windows: 'Windows'},
  },
  brand: {
    ...base.brand,
    typography: {
      ...base.brand.typography,
      headingSize: 116,
      bodySize: 50,
      bodyLineHeight: 1.12,
    },
  },
  media: {
    ...base.media,
    logo: {...base.media.logo, asset: logos.white},
    environment: {
      ...base.media.environment,
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 580, y: 435, width: 1850, height: 980},
      },
    },
    agent: {
      ...base.media.agent,
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 340, y: 70, width: 1300, height: 690},
      },
    },
  },
  layout: {
    margin: 48, gutter: 24, padding: 14, captionHeight: 80,
    grid: {captionTop: 76, footerTop: 1035},
  },
  panels: {
    primaryWidth: 1508, displayTop: 172, displayHeight: 842,
    headerHeight: 44, railWidth: 292, bayHeight: 224, bayGap: 18,
    logoWidth: 136,
  },
  labels: {
    edition: 'MAC / LAUNCH',
    primary: 'MAIN DISPLAY',
    index: 'SOURCE INDEX',
    separateExamples: 'Separate session examples',
    selected: 'ON MAIN DISPLAY',
    reference: 'REFERENCE',
    openingNote: 'Hosted Mac environments',
    closingNote: 'Devin on Mac',
    sceneSources: {
      opening: 'FEATURE INTRODUCTION',
      environment: 'ENVIRONMENT SELECTION / ANIMATION',
      agent: 'AGENT SELECTION / RECORDING',
      iphone: 'IPHONE SIMULATOR / STILLS',
      webQa: 'WEB QA / RECORDING',
      ipad: 'IPAD SIMULATOR / STILL',
      closing: 'START A MAC SESSION',
    },
    bays: [
      {
        number: '01', title: 'Session setup',
        detail: 'Hosted Mac.\nYour choice of agent.',
        sourceNote: 'Selector + agent menu',
        scenes: ['environment', 'agent'],
      },
      {
        number: '02', title: 'Simulator',
        detail: 'iPhone and iPad.\nSeparate examples.',
        sourceNote: 'Original screenshots',
        scenes: ['iphone', 'ipad'],
      },
      {
        number: '03', title: 'Test review',
        detail: 'Recorded steps.\nVisible test results.',
        sourceNote: 'Web QA example',
        scenes: ['webQa'],
      },
    ],
  },
  status: {
    activeBorder: '#ffffff',
    inactiveBorder: 'rgba(255,255,255,0.22)',
    secondaryText: 'rgba(255,255,255,0.64)',
    activeFill: 'rgba(255,255,255,0.06)',
    outlineWidth: 2,
    showSelectionLabel: true,
  },
  motion: {
    apertureFrames: 24,
    baySettleFrames: 18,
    bayStaggerFrames: 5,
    bayTravel: 32,
    selectionFrames: 12,
    consolidationFrames: 24,
    openingWidthRatio: 0.76,
    iphoneSplitRatio: 0.5,
  },
};
