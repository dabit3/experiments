import {defaultLaunchConfig, type Crop, type LaunchConfig} from '../../shared';

export type FocusKey = 'environment' | 'agent' | 'iphoneFirst' | 'iphoneSecond' | 'webQa' | 'ipad';
export type FocusRegion = {
  crop: Crop;
  annotation: string;
  sourceNote: string;
};

export type OpticalConfig = LaunchConfig & {
  focus: Record<FocusKey, FocusRegion>;
  labels: {
    direction: string;
    fullView: string;
    inspection: string;
    montage: string;
    openingNote: string;
    result: string;
  };
  motion: {
    contextHoldSeconds: number;
    revealFrames: number;
    returnSeconds: number;
    iphoneSplit: number;
    connectorOpacity: number;
    outlineWidth: number;
    maxSourceScale: number;
  };
};

export const config: OpticalConfig = {
  ...structuredClone(defaultLaunchConfig),
  layout: {
    margin: 60,
    gutter: 64,
    padding: 20,
    captionHeight: 150,
    grid: {
      mediaTop: 250,
      mediaHeight: 704,
      inspectionWidth: 500,
      inspectionHeight: 420,
      inspectionTop: 326,
      annotationTop: 812,
      captionSize: 58,
      annotationSize: 28,
      indexSize: 20,
      logoWidth: 160,
    },
  },
  labels: {
    direction: 'OPTICAL LABORATORY',
    fullView: 'CONTEXT / COMPLETE SOURCE',
    inspection: 'DETAIL / SAME SOURCE',
    montage: 'Separate session examples. Simulator views are captured stills.',
    openingNote: 'A closer look at Devin on Mac.',
    result: 'Terra Table · captured iPad Simulator result',
  },
  motion: {
    contextHoldSeconds: 0.85,
    revealFrames: 20,
    returnSeconds: 0.8,
    iphoneSplit: 0.5,
    connectorOpacity: 0.42,
    outlineWidth: 2,
    maxSourceScale: 1,
  },
  focus: {
    environment: {
      crop: {x: 640, y: 940, width: 600, height: 405},
      annotation: 'Hosted environment',
      sourceNote: 'macOS is selected in the source interface.',
    },
    agent: {
      crop: {x: 535, y: 105, width: 645, height: 585},
      annotation: 'Agent selection',
      sourceNote: 'Original recording · 1× playback',
    },
    iphoneFirst: {
      crop: {x: 730, y: 495, width: 490, height: 520},
      annotation: 'Afterhours Maze',
      sourceNote: 'Captured still. Report: 8 passed, 0 failed, 1 untested.',
    },
    iphoneSecond: {
      crop: {x: 720, y: 335, width: 520, height: 790},
      annotation: 'Large Dispatch',
      sourceNote: 'Captured still. Complete review remains alongside.',
    },
    webQa: {
      crop: {x: 1240, y: 95, width: 665, height: 385},
      annotation: 'Recorded test steps',
      sourceNote: 'Original recording · 1× playback',
    },
    ipad: {
      crop: {x: 670, y: 550, width: 840, height: 570},
      annotation: 'Terra Table',
      sourceNote: 'Captured iPad Simulator still. Complete report retained.',
    },
  },
};
