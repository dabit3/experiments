import {
  contain, defaultLaunchConfig, logos,
  type ImageSelection, type LaunchConfig, type SceneId,
} from '../../shared';

export type BroadcastConfig = LaunchConfig & {
  broadcast: {
    chapters: Record<SceneId, {number: string; label: string}>;
    montageLabel: string;
    stillLabel: string;
    titleMediaLabel: string;
    closingLogo: ImageSelection;
    titlePanelFraction: number;
    markerSize: number;
    captionSize: number;
    logoWidth: number;
  };
  motion: {
    wipeFrames: number;
    stingFrames: number;
    panelTravel: number;
    titleRevealFrames: number;
    iphoneSplit: number;
  };
};

export const config: BroadcastConfig = {
  ...structuredClone(defaultLaunchConfig),
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        ...contain,
        crop: {x: 580, y: 460, width: 1840, height: 910},
      },
    },
  },
  layout: {
    margin: 48,
    gutter: 28,
    padding: 16,
    captionHeight: 128,
    grid: {headerHeight: 44, mediaTop: 84},
  },
  broadcast: {
    chapters: {
      opening: {number: '18', label: 'Devin on Mac'},
      environment: {number: '01', label: 'Environment'},
      agent: {number: '01', label: 'Agent'},
      iphone: {number: '02', label: 'Simulator'},
      webQa: {number: '03', label: 'Test review'},
      ipad: {number: '04', label: 'Layouts'},
      closing: {number: '05', label: 'Start building'},
    },
    montageLabel: 'Separate session examples',
    stillLabel: 'Simulator still',
    titleMediaLabel: 'Hosted Mac environment',
    closingLogo: {asset: logos.white, framing: contain},
    titlePanelFraction: 0.57,
    markerSize: 23,
    captionSize: 44,
    logoWidth: 248,
  },
  motion: {
    wipeFrames: 12,
    stingFrames: 12,
    panelTravel: 56,
    titleRevealFrames: 20,
    iphoneSplit: 0.5,
  },
};
