import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const numberControl = (path: string, label: string, description: string, min: number, max: number, step = 1): ConfigControl =>
  ({path, label, description, type: 'number', min, max, step});

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: key, description: 'Editable launch copy.', type: 'string',
    })),
    ...Object.keys(config.durations).map((key) => numberControl(
      `durations.${key}`, `${key} duration`, 'Seconds; video scenes must fit the actual source trim.', 0.1, 60, 0.1)),
    ...Object.keys(config.brand.colors).map((key): ConfigControl => ({
      path: `brand.colors.${key}`, label: key, description: 'Studio/typographic token; does not recolor UI.', type: 'color',
    })),
    ...Object.entries(config.brand.typography).map(([key, value]): ConfigControl => ({
      path: `brand.typography.${key}`, label: key, description: 'Shared brand typography token.',
      type: typeof value === 'number' ? 'number' : 'string',
    })),
    ...Object.keys(config.typography).map((key) => numberControl(
      `typography.${key}`, key, 'Direction-specific typography or text-column position in output pixels.', 1, 1920)),
    ...Object.keys(config.labels).map((key): ConfigControl => ({
      path: `labels.${key}`, label: key, description: 'Caption outside the source plane.', type: 'string',
    })),
    ...['margin', 'gutter', 'padding', 'captionHeight'].map((key) => numberControl(
      `layout.${key}`, key, 'Spacing in output pixels.', 0, 300)),
    ...Object.keys(config.layout.grid).map((key) => numberControl(
      `layout.grid.${key}`, key, 'Editorial baseline in output pixels.', 0, 1080)),
    ...['opening', 'closing', 'detailCrop', 'contextCrop'].flatMap((box) =>
      ['x', 'y', 'width', 'height'].map((key) => numberControl(
        `camera.${box}.${key}`, `${box} ${key}`,
        box.includes('Crop') ? 'Original source pixel coordinate; keep inside the selected asset.' : 'Output pixel coordinate.',
        0, 4000))),
    ...Object.keys(config.lighting).map((key) => numberControl(
      `lighting.${key}`, key, 'Lighting outside the source plane; strengths/opacity use 0–1.', 0,
      key.includes('Strength') || key.includes('Opacity') ? 1 : 100, 0.01)),
    ...Object.keys(config.motion).map((key) => numberControl(
      `motion.${key}`, key, 'Frame-driven camera control; fractional controls use 0–1.',
      0, key.includes('Fraction') || key === 'iphoneSplit' ? 1 : key === 'perspective' ? 6000 : 120, 0.01)),
    ...['logo', 'environment', 'agent', 'iphone.0', 'iphone.1', 'webQa', 'ipad'].flatMap((key): ConfigControl[] => [
      {path: `media.${key}.asset`, label: `${key} asset`, type: 'string', description: 'Filename from the shared asset manifest.'},
      {path: `media.${key}.framing.fit`, label: `${key} fit`, type: 'string', description: 'contain or cover. Preserve reports in full.'},
      numberControl(`media.${key}.framing.anchorX`, `${key} anchor X`, 'Horizontal 0–1 anchor.', 0, 1, 0.01),
      numberControl(`media.${key}.framing.anchorY`, `${key} anchor Y`, 'Vertical 0–1 anchor.', 0, 1, 0.01),
    ]),
    ...['agent', 'webQa'].map((key) => numberControl(
      `media.${key}.sourceStartSeconds`, `${key} source offset`, 'Seconds at 1× speed, independent of output placement.', 0, 59, 0.1)),
  ],
});
