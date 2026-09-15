import {defaultLaunchConfig, type Crop, type Framing, type ImageAssetId, type LaunchConfig} from '../../shared';

export type EditorialConfig = LaunchConfig & {
  editorial: {
    edition: string;
    montageNote: string;
    environmentWord: string;
    layoutWord: string;
    coverKicker: string;
    environmentKicker: string;
    environmentNote: string;
    ipadKicker: string;
    iphoneNotes: [string, string];
    ipadNote: string;
    coverFraming: Framing;
    environmentHighlight?: {
      enabled: boolean;
      asset: ImageAssetId;
      previousRow: Crop;
      selectedRow: Crop;
      radius: number;
      shade: number;
    };
    coverTypeSize: number;
    captionTypeSize: number;
    marginTypeSize: number;
    sideTypeSize: number;
    closingTypeSize: number;
    logoWidth: number;
  };
  motion: {
    revealFrames: number;
    revealDirection: 'left' | 'right';
    coverRevealDelay: number;
    iphoneSplit: number;
    ruleFrames: number;
  };
};

export const config: EditorialConfig = {
  ...structuredClone(defaultLaunchConfig),
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain',
        anchorX: 0.5,
        anchorY: 0.5,
        crop: {x: 610, y: 480, width: 1800, height: 900},
      },
    },
  },
  layout: {
    margin: 72,
    gutter: 40,
    padding: 18,
    captionHeight: 110,
    grid: {
      coverTextWidth: 810,
      coverMediaX: 930,
      coverMediaY: 248,
      coverMediaHeight: 526,
      environmentRail: 360,
      environmentMediaY: 224,
      environmentMediaHeight: 700,
      ipadRail: 320,
      ipadMediaY: 220,
      ipadMediaHeight: 746,
      closingMediaWidth: 946,
      closingMediaY: 366,
      closingTextY: 226,
    },
  },
  editorial: {
    edition: 'LAUNCH EDITION',
    montageNote: 'Examples from separate sessions',
    environmentWord: 'Mac',
    layoutWord: 'Layouts',
    coverKicker: 'MAC ENVIRONMENT',
    environmentKicker: 'ENVIRONMENT',
    environmentNote: 'Hosted environment / macOS selected',
    ipadKicker: 'SIMULATOR',
    iphoneNotes: [
      'Afterhours Maze / iPhone Simulator still',
      'Large Dispatch / iPhone Simulator still',
    ],
    ipadNote: 'Terra Table / iPad Simulator still',
    coverFraming: {
      fit: 'contain',
      anchorX: 0.5,
      anchorY: 0.5,
      crop: {x: 600, y: 895, width: 880, height: 495},
    },
    environmentHighlight: {
      enabled: true,
      asset: 'devin-web-4.png',
      previousRow: {x: 668, y: 1077, width: 532, height: 77},
      selectedRow: {x: 669, y: 1154, width: 530, height: 75},
      radius: 14,
      shade: 240,
    },
    coverTypeSize: 176,
    captionTypeSize: 48,
    marginTypeSize: 140,
    sideTypeSize: 52,
    closingTypeSize: 78,
    logoWidth: 156,
  },
  motion: {
    revealFrames: 14,
    revealDirection: 'left',
    coverRevealDelay: 3,
    iphoneSplit: 0.5,
    ruleFrames: 12,
  },
};
