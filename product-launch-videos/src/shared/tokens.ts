export type BrandTokens = {
  colors: {
    canvas: string;
    ink: string;
    secondaryInk: string;
    white: string;
    mediaMat: string;
  };
  typography: {
    fontFamily: string;
    monoFamily: string;
    headingSize: number;
    headingLineHeight: number;
    headingTracking: string;
    bodySize: number;
    bodyLineHeight: number;
    bodyTracking: string;
  };
  spacing: {margin: number; gutter: number; padding: number; titleGap: number};
};

export const brand: BrandTokens = {
  colors: {
    canvas: '#f7f6f5',
    ink: '#191919',
    secondaryInk: 'rgba(25,25,25,0.56)',
    white: '#ffffff',
    mediaMat: '#edeceb',
  },
  typography: {
    fontFamily: 'nbInternationalPro',
    monoFamily: 'Geist Mono',
    headingSize: 96,
    headingLineHeight: 1,
    headingTracking: '-0.0266em',
    bodySize: 36,
    bodyLineHeight: 1.4,
    bodyTracking: '-0.0195em',
  },
  spacing: {margin: 60, gutter: 60, padding: 34, titleGap: 32},
};

export const VIDEO = {width: 1920, height: 1080, fps: 30} as const;
