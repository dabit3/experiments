import {defaultLaunchConfig, type Crop, type LaunchConfig} from '../../shared';

export type Pairing = {
  leftLabel: string;
  rightLabel: string;
  note: string;
  leftCrop: Crop;
  rightCrop: Crop | null;
  balancedRatio: number;
  activeRatio: number;
};

export type DiptychConfig = LaunchConfig & {
  labels: {
    edition: string;
    montage: string;
    source: string;
    playback: string;
    next: string;
    agentAction: string;
    agentObservation: string;
    agentPair: string;
    qaAction: string;
    qaObservation: string;
    qaPair: string;
    qaNote: string;
    iphoneNote: string;
  };
  pairings: {
    environment: Pairing;
    iphone: [Pairing, Pairing];
    ipad: Pairing;
  };
  motion: {
    dividerFrames: number;
    activeAt: number;
    balancedAt: number;
    unifyAt: number;
    iphoneSwitchAt: number;
    openingSplit: number;
    videoRailRatio: number;
    closingCtaAt: number;
    shutterFrames: number;
    dividerWidth: number;
  };
};

export const config: DiptychConfig = {
  ...structuredClone(defaultLaunchConfig),
  layout: {margin: 56, gutter: 24, padding: 12, captionHeight: 112, grid: {panelLabelHeight: 48, footerHeight: 48}},
  labels: {
    edition: '14 / ACTION & OBSERVATION',
    montage: 'Examples from separate sessions',
    source: 'Two views · one source',
    playback: 'Original recording · 1×',
    next: 'Devin on Mac',
    agentAction: 'Agent menu',
    agentObservation: 'Visible options',
    agentPair: 'Composer + menu · same source',
    qaAction: 'Test step',
    qaObservation: 'Recorded result',
    qaPair: 'Recording + report · same source',
    qaNote: 'Web QA example · separate session',
    iphoneNote: 'iPhone examples · separate sessions · stills',
  },
  pairings: {
    environment: {
      leftLabel: 'Hosted environment',
      rightLabel: 'macOS selected',
      note: 'Selection detail + complete source screenshot',
      leftCrop: {x: 620, y: 920, width: 650, height: 445},
      rightCrop: null,
      balancedRatio: 0.36,
      activeRatio: 0.27,
    },
    iphone: [
      {
        leftLabel: 'Test step + observed result',
        rightLabel: 'iPhone Simulator · still',
        note: 'Afterhours Maze · same screenshot',
        leftCrop: {x: 1948, y: 138, width: 1038, height: 940},
        rightCrop: {x: 0, y: 0, width: 1948, height: 1626},
        balancedRatio: 0.45,
        activeRatio: 0.36,
      },
      {
        leftLabel: 'Test step + observed result',
        rightLabel: 'iPhone Simulator · still',
        note: 'Large Dispatch · separate session',
        leftCrop: {x: 1940, y: 138, width: 1038, height: 780},
        rightCrop: {x: 0, y: 0, width: 1940, height: 1626},
        balancedRatio: 0.45,
        activeRatio: 0.36,
      },
    ],
    ipad: {
      leftLabel: 'Test step + observed result',
      rightLabel: 'iPad Simulator · still',
      note: 'Terra Table · same screenshot',
      leftCrop: {x: 1948, y: 138, width: 1034, height: 900},
      rightCrop: {x: 0, y: 0, width: 1948, height: 1626},
      balancedRatio: 0.45,
      activeRatio: 0.36,
    },
  },
  motion: {
    dividerFrames: 16,
    activeAt: 0.12,
    balancedAt: 0.60,
    unifyAt: 0.76,
    iphoneSwitchAt: 0.5,
    openingSplit: 0.57,
    videoRailRatio: 0.16,
    closingCtaAt: 0.28,
    shutterFrames: 12,
    dividerWidth: 2,
  },
};
