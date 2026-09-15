import type {ImageAssetId, VideoAssetId} from './assets';
import {logos} from './assets';
import {contain, type Framing} from './geometry';
import {brand, type BrandTokens} from './tokens';
import {sampleCopy, sampleDurations, type LaunchCopy, type SceneDurations} from './timeline';

export type ImageSelection = {asset: ImageAssetId; framing: Framing};
export type VideoSelection = {asset: VideoAssetId; framing: Framing; sourceStartSeconds: number};
export type LaunchConfig = {
  copy: LaunchCopy;
  durations: SceneDurations;
  brand: BrandTokens;
  media: {
    logo: ImageSelection;
    environment: ImageSelection;
    agent: VideoSelection;
    iphone: [ImageSelection, ImageSelection];
    webQa: VideoSelection;
    ipad: ImageSelection;
  };
  layout: {
    margin: number;
    gutter: number;
    padding: number;
    captionHeight: number;
    grid: Record<string, number>;
  };
  motion: Record<string, number | boolean | string>;
};

export const defaultLaunchConfig: LaunchConfig = {
  copy: sampleCopy,
  durations: sampleDurations,
  brand,
  media: {
    logo: {asset: logos.black, framing: contain},
    environment: {asset: 'devin-web-4.png', framing: contain},
    agent: {asset: 'agent-selector-cloud.mp4', framing: contain, sourceStartSeconds: 0},
    iphone: [
      {asset: 'devin-web-14.png', framing: contain},
      {asset: 'devin-web-18.png', framing: contain},
    ],
    webQa: {asset: 'devin-testing-2.mp4', framing: contain, sourceStartSeconds: 0},
    ipad: {asset: 'devin-web-19.png', framing: contain},
  },
  layout: {margin: 60, gutter: 60, padding: 34, captionHeight: 140, grid: {}},
  motion: {},
};
