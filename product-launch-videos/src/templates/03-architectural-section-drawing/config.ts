import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type StageId = 'environment' | 'agent' | 'iphone' | 'webQa' | 'ipad';
export type Annotation = {
  label: string;
  x: number;
  y: number;
  edge: 'top' | 'bottom';
  enabled: boolean;
};
export type SectionConfig = LaunchConfig & {
  stages: {id: StageId; label: string}[];
  connections: {from: StageId; to: StageId}[];
  annotations: Record<StageId | 'iphoneSecond', Annotation>;
  drawing: {
    title: string;
    montageLabel: string;
    stillLabel: string;
    recordLabel: string;
    closingLabel: string;
    lineWidth: number;
    gridSpacing: number;
    gridOpacity: number;
    indexSize: number;
  };
  motion: {
    sectionRevealFrames: number;
    planeSeparation: number;
    planeTravel: number;
    introResolveFraction: number;
    annotationHoldFrames: number;
    annotationFadeFrames: number;
    iphoneSplit: number;
  };
};

export const config: SectionConfig = {
  ...structuredClone(defaultLaunchConfig),
  brand: {
    ...structuredClone(defaultLaunchConfig.brand),
    typography: {
      ...defaultLaunchConfig.brand.typography,
      headingSize: 100,
      bodySize: 36,
    },
  },
  layout: {
    margin: 60,
    gutter: 32,
    padding: 12,
    captionHeight: 82,
    grid: {headerY: 36, mediaTop: 174, mediaBottom: 998, stageTop: 1024},
  },
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 550, y: 450, width: 1900, height: 950},
      },
    },
  },
  stages: [
    {id: 'environment', label: 'Environment'},
    {id: 'agent', label: 'Agent'},
    {id: 'iphone', label: 'iPhone Simulator'},
    {id: 'webQa', label: 'Web QA'},
    {id: 'ipad', label: 'iPad Simulator'},
  ],
  connections: [
    {from: 'environment', to: 'agent'},
    {from: 'agent', to: 'iphone'},
    {from: 'iphone', to: 'webQa'},
    {from: 'webQa', to: 'ipad'},
  ],
  annotations: {
    environment: {label: 'Hosted menu', x: 945, y: 1313, edge: 'bottom', enabled: true},
    agent: {label: 'Agent selector', x: 620, y: 674, edge: 'bottom', enabled: false},
    iphone: {label: 'iPhone Simulator', x: 970, y: 145, edge: 'top', enabled: true},
    iphoneSecond: {label: 'iPhone Simulator', x: 970, y: 145, edge: 'top', enabled: true},
    webQa: {label: 'Test report', x: 1370, y: 122, edge: 'top', enabled: false},
    ipad: {label: 'iPad Simulator', x: 970, y: 144, edge: 'top', enabled: true},
  },
  drawing: {
    title: 'SECTION STUDY / 03',
    montageLabel: 'Launch montage · separate examples',
    stillLabel: 'COMPOSED STILL',
    recordLabel: 'RECORDING / 1×',
    closingLabel: 'DRAWING COMPLETE',
    lineWidth: 1.25,
    gridSpacing: 80,
    gridOpacity: 0.065,
    indexSize: 20,
  },
  motion: {
    sectionRevealFrames: 24,
    planeSeparation: 62,
    planeTravel: 90,
    introResolveFraction: 0.65,
    annotationHoldFrames: 40,
    annotationFadeFrames: 14,
    iphoneSplit: 0.5,
  },
};
