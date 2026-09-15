import {defineTemplate, type ConfigControl} from '../../shared';
import manifest from './manifest.json';
import {config} from './config';
import {Template} from './Template';

const numericControls = [
  ['motion.panelRevealFrames', 'Panel expansion', 'Frames for a still-media region to expand; recordings stay fully visible.', 0, 60, 1],
  ['motion.panelTravel', 'Aligned panel travel', 'Horizontal still-panel travel along the media grid; recordings remain stationary.', 0, 120, 1],
  ['motion.typeRevealFrames', 'Type mask duration', 'Frames for complete caption/title rectangular reveals.', 0, 60, 1],
  ['motion.typeTravel', 'Type travel', 'Vertical travel inside a fixed type mask, in pixels.', 0, 100, 1],
  ['motion.regionStartWidth', 'Initial region width', 'Fraction of a media/CTA bay visible before it expands.', 0, 1, 0.01],
  ['motion.iphoneSplit', 'iPhone still split', 'Fraction of the iPhone scene allocated to the first screenshot.', 0.1, 0.9, 0.05],
  ['layout.margin', 'Canvas margin', 'Outer composition margin, in pixels.', 30, 90, 1],
  ['layout.gutter', 'Grid gutter', 'Gap between the caption rail and media region.', 20, 70, 1],
  ['layout.padding', 'Media padding', 'Mat padding around unchanged source pixels.', 0, 34, 1],
  ['layout.captionHeight', 'Caption allocation', 'Height budget used to size the explanatory caption.', 280, 480, 1],
  ['layout.grid.railWidth', 'Caption rail width', 'Width of the narrow explanatory grid region.', 210, 340, 1],
  ['layout.grid.headerHeight', 'Header allocation', 'Media start measured from the top margin.', 80, 150, 1],
  ['layout.grid.footerHeight', 'Footer allocation', 'Reserved space beneath product media.', 24, 60, 1],
  ['layout.grid.titleWidth', 'Title mask width', 'Maximum width of the opening title mask.', 1000, 1500, 1],
  ['layout.grid.titleTop', 'Title grid position', 'Vertical title origin.', 220, 320, 1],
  ['layout.grid.captionTop', 'Caption grid position', 'Vertical product caption origin.', 300, 380, 1],
  ['layout.grid.ruleWidth', 'Grid rule weight', 'Width of the flat alignment rules.', 0, 3, 0.5],
  ['brand.typography.headingSize', 'Display type size', 'Base display type size, in pixels.', 100, 180, 1],
  ['brand.typography.bodySize', 'Caption type size', 'Base caption type size, in pixels.', 36, 52, 1],
] as const;

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...numericControls.map(([path, label, description, min, max, step]): ConfigControl =>
      ({path, label, description, type: 'number', min, max, step})),
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: key, type: 'string', description: 'Editable launch copy.',
    })),
    ...Object.keys(config.durations).map((key): ConfigControl => ({
      path: `durations.${key}`, label: `${key} duration`, type: 'number',
      description: 'Seconds. Video scene durations must fit the source at 1×.', min: 0.1, step: 0.1,
    })),
    ...Object.keys(config.brand.colors).map((key): ConfigControl => ({
      path: `brand.colors.${key}`, label: key, type: 'color', description: 'Composition color; source UI is unchanged.',
    })),
  ],
});
