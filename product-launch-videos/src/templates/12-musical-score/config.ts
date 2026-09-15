import {defaultLaunchConfig, type LaunchConfig, type SceneId} from '../../shared';

export type ProductScene = Exclude<SceneId, 'opening' | 'closing'>;
export type ScoreCue = {
  scene: ProductScene;
  atSeconds: number;
  label: string;
};

export type MusicalScoreConfig = LaunchConfig & {
  score: {
    label: string;
    context: string;
    tracks: [string, string, string];
    chapters: Record<ProductScene, {label: string; track: number}>;
    cues: ScoreCue[];
    fontSize: number;
    rowHeight: number;
    labelWidth: number;
    barInset: number;
    ruleOpacity: number;
    introIndex: string;
    closingIndex: string;
  };
  motion: {
    entranceFrames: number;
    playheadTravelFrames: number;
    cueAccentFrames: number;
    cueAccentSize: number;
    resolveFrames: number;
    iphoneSplit: number;
  };
  sound: {enabled: boolean; asset: string; volume: number; durationSeconds: number};
};

export const config: MusicalScoreConfig = {
  ...structuredClone(defaultLaunchConfig),
  brand: {
    ...structuredClone(defaultLaunchConfig.brand),
    typography: {
      ...defaultLaunchConfig.brand.typography,
      headingSize: 128,
      bodySize: 38,
    },
  },
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 540, y: 435, width: 1900, height: 1010},
      },
    },
    agent: {
      asset: 'agent-selector-cloud.mp4', sourceStartSeconds: 0,
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 380, y: 70, width: 1320, height: 742},
      },
    },
  },
  layout: {
    margin: 60,
    gutter: 28,
    padding: 18,
    captionHeight: 100,
    grid: {scoreTop: 922, mediaTop: 118, mediaHeight: 776},
  },
  score: {
    label: 'EDITORIAL SCORE',
    context: 'Separate examples · Narrative order',
    tracks: ['Environment', 'Simulator', 'Review'],
    chapters: {
      environment: {label: 'Mac', track: 0},
      agent: {label: 'Agent', track: 0},
      iphone: {label: 'iPhone', track: 1},
      webQa: {label: 'Web QA', track: 2},
      ipad: {label: 'iPad', track: 1},
    },
    cues: [
      {scene: 'environment', atSeconds: 0, label: 'macOS selected'},
      {scene: 'agent', atSeconds: 1, label: 'Agent menu open'},
      {scene: 'iphone', atSeconds: 0, label: 'Simulator stills'},
      {scene: 'webQa', atSeconds: 3.5, label: 'New ticket form'},
      {scene: 'ipad', atSeconds: 0, label: 'iPad example'},
    ],
    fontSize: 21,
    rowHeight: 27,
    labelWidth: 250,
    barInset: 17,
    ruleOpacity: 0.18,
    introIndex: 'PRELUDE',
    closingIndex: 'RESOLUTION',
  },
  motion: {
    entranceFrames: 24,
    playheadTravelFrames: 14,
    cueAccentFrames: 18,
    cueAccentSize: 12,
    resolveFrames: 24,
    iphoneSplit: 0.5,
  },
  sound: {enabled: false, asset: '', volume: 0.18, durationSeconds: 0.18},
};
