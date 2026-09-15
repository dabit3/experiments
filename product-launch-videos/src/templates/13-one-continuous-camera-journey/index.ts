import {defineTemplate, type ConfigControl} from '../../shared';
import {config, stopIds} from './config';
import manifest from './manifest.json';
import {Template} from './Template';

const controls: ConfigControl[] = [
  {path: 'motion.travelSeconds', label: 'Camera travel', type: 'number', min: 0.1, max: 1.2, step: 0.1,
    description: 'Seconds per move, automatically capped to retain still reading time.'},
  {path: 'motion.iphoneSplit', label: 'iPhone destination split', type: 'number', min: 0.25, max: 0.75, step: 0.05,
    description: 'Fraction of the iPhone scene at which the second still is reached.'},
  {path: 'motion.travelPullback', label: 'Travel pullback', type: 'number', min: 0, max: 0.1, step: 0.005,
    description: 'Small camera scale change during travel only; every hold is exactly front-facing at scale 1.'},
  {path: 'motion.railWeight', label: 'Canvas baseline weight', type: 'number', min: 0, max: 6, step: 1,
    description: 'Weight of the continuous editorial baseline.'},
  ...stopIds.flatMap((id): ConfigControl[] => [
    {path: `canvas.stops.${id}.x`, label: `${id} x`, type: 'number',
      description: 'Destination and camera x position; keep at least 1980 px between consecutive stops.'},
    {path: `canvas.stops.${id}.y`, label: `${id} y`, type: 'number',
      description: 'Destination and camera y position; small changes keep the path calm.'},
  ]),
  ...(['railY', 'titleSize', 'titleWidth', 'logoWidth', 'captionSize', 'labelSize', 'mediaTop', 'mediaBottom'] as const)
    .map((key): ConfigControl => ({
      path: `canvas.${key}`, label: key, type: 'number',
      description: 'Canvas layout in 1920 × 1080 composition pixels.',
    })),
  ...Object.keys(config.copy).map((key): ConfigControl => ({
    path: `copy.${key}`, label: key, type: 'string', description: 'Editable launch copy.',
  })),
  ...Object.keys(config.durations).map((key): ConfigControl => ({
    path: `durations.${key}`, label: `${key} seconds`, type: 'number', min: 0.1, step: 0.1,
    description: 'Scene seconds; composition length and camera holds derive from these values.',
  })),
  ...Object.keys(config.labels).map((key): ConfigControl => ({
    path: `labels.${key}`, label: `${key} label`, type: 'string', description: 'Stationary editorial context.',
  })),
];

export const template = defineTemplate({
  ...manifest, schemaVersion: 1, Component: Template, defaultConfig: config, controls,
});
