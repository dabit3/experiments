import {defineTemplate, type ConfigControl} from '../../shared';
import {config, type FocusKey} from './config';
import manifest from './manifest.json';
import {Template} from './Template';

const focusKeys: FocusKey[] = ['environment', 'agent', 'iphoneFirst', 'iphoneSecond', 'webQa', 'ipad'];
const focusControls: ConfigControl[] = focusKeys.flatMap((key) => [
  ...(['x', 'y', 'width', 'height'] as const).map((axis) => ({
    path: `focus.${key}.crop.${axis}`, label: `${key} focus ${axis}`,
    type: 'number' as const, min: 0, step: 1,
    description: 'Original source pixels. Must stay inside the full-context crop.',
  })),
  {path: `focus.${key}.annotation`, label: `${key} annotation`, type: 'string',
    description: 'Dedicated margin annotation, outside the product pixels.'},
  {path: `focus.${key}.sourceNote`, label: `${key} source note`, type: 'string',
    description: 'Source provenance and any report qualification.'},
]);

export const template = defineTemplate({
  ...manifest, schemaVersion: 1,
  Component: Template, defaultConfig: config,
  controls: [
    ...focusControls,
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: `${key} copy`, type: 'string', description: 'Editable launch copy.',
    })),
    ...Object.keys(config.durations).map((key): ConfigControl => ({
      path: `durations.${key}`, label: `${key} seconds`, type: 'number', min: 0.1, step: 0.1,
      description: 'Changes actual composition duration; videos must fit within their source.',
    })),
    ...Object.keys(config.layout.grid).map((key): ConfigControl => ({
      path: `layout.grid.${key}`, label: key, type: 'number', min: 1, step: 1,
      description: 'Output-pixel layout or typography control.',
    })),
    ...Object.keys(config.motion).map((key): ConfigControl => ({
      path: `motion.${key}`, label: key, type: 'number', min: 0, step: 0.05,
      description: key === 'maxSourceScale'
        ? 'Maximum output pixels per source pixel, always capped at 1.'
        : 'Deterministic inspection timing, source split, or line styling.',
    })),
    ...Object.keys(config.labels).map((key): ConfigControl => ({
      path: `labels.${key}`, label: key, type: 'string',
      description: 'Editorial label outside the original interface.',
    })),
  ],
});
