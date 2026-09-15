import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type Exhibit = {
  number: string;
  title: string;
  medium: string;
  cameraX: number;
  cameraY: number;
};

export type GalleryConfig = LaunchConfig & {
  exhibition: {
    title: string;
    note: string;
    exhibits: [Exhibit, Exhibit, Exhibit];
    iphoneLabels: [string, string];
    ipadLabel: string;
    environmentLabel: string;
    agentLabel: string;
    webQaLabel: string;
  };
  gallery: {
    displayX: number;
    displayY: number;
    displayWidth: number;
    displayHeight: number;
    railWidth: number;
    labelSize: number;
    indexSize: number;
    captionSize: number;
    floorY: number;
    seamColor: string;
    shadowOpacity: number;
    lightOpacity: number;
  };
  motion: {
    approachFrames: number;
    arrivalScale: number;
    lateralTravel: number;
    exitFrames: number;
    wallTravel: number;
    titleRevealFrames: number;
    iphoneSplit: number;
  };
};

const base = structuredClone(defaultLaunchConfig);

export const config: GalleryConfig = {
  ...base,
  media: {
    ...base.media,
    environment: {
      ...base.media.environment,
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 560, y: 410, width: 1920, height: 1080},
      },
    },
  },
  layout: {...base.layout, margin: 56, gutter: 26, padding: 8, captionHeight: 108},
  exhibition: {
    title: 'A collection of possibilities',
    note: 'Selected examples from separate sessions',
    exhibits: [
      {number: '01', title: 'Hosted\nMac', medium: 'Environment\n& agent', cameraX: 0, cameraY: 0},
      {number: '02', title: 'iPhone\nSimulator', medium: 'Native app\nstills', cameraX: 0, cameraY: 0},
      {number: '03', title: 'Test\n& review', medium: 'Web recording\n& iPad still', cameraX: 0, cameraY: 0},
    ],
    iphoneLabels: ['Afterhours Maze · still', 'Large Dispatch · still'],
    ipadLabel: 'Terra Table · still',
    environmentLabel: 'Hosted environment · still',
    agentLabel: 'Agent selection · recording',
    webQaLabel: 'Recorded web test review',
  },
  gallery: {
    displayX: 210,
    displayY: 126,
    displayWidth: 1644,
    displayHeight: 894,
    railWidth: 134,
    labelSize: 26,
    indexSize: 64,
    captionSize: 43,
    floorY: 1040,
    seamColor: 'rgba(25,25,25,0.10)',
    shadowOpacity: 0.09,
    lightOpacity: 0.68,
  },
  motion: {
    approachFrames: 32,
    arrivalScale: 0.96,
    lateralTravel: 34,
    exitFrames: 12,
    wallTravel: 56,
    titleRevealFrames: 22,
    iphoneSplit: 0.5,
  },
};
