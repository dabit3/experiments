import {defineTemplate} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    {path: 'route.code', label: 'Route identifier', type: 'string', description: 'Editorial route badge.'},
    {path: 'route.legend', label: 'Route legend', type: 'string', description: 'Makes the separate-session montage explicit.'},
    {path: 'route.stillLabel', label: 'Still caption', type: 'string', description: 'Native source disclosure.'},
    {path: 'route.departureLabel', label: 'Departure caption', type: 'string', description: 'Opening route endpoint caption.'},
    {path: 'route.destinationLabel', label: 'Destination caption', type: 'string', description: 'Closing route endpoint caption.'},
    ...config.route.stations.flatMap((station, i) => [
      {path: `route.stations.${i}.name`, label: `${station.name} label`, type: 'string' as const, description: 'Short station label.'},
      {path: `route.stations.${i}.x`, label: `${station.name} horizontal position`, type: 'number' as const, description: 'Normalized route coordinate.', min: 0.04, max: 0.96, step: 0.01},
      {path: `route.stations.${i}.y`, label: `${station.name} vertical position`, type: 'number' as const, description: 'Normalized route coordinate; orthogonal connectors join stations.', min: 0.1, max: 0.8, step: 0.01},
    ]),
    {path: 'motion.arrivalFrames', label: 'Arrival reveal', type: 'number', description: 'Marker-origin rectangular expansion; video starts after its frozen-first-frame arrival.', min: 0, max: 30, step: 1},
    {path: 'motion.mapHoldFrames', label: 'Map pause', type: 'number', description: 'Brief map-only frames before an arrival.', min: 0, max: 15, step: 1},
    {path: 'motion.lineTraceFrames', label: 'Departure trace', type: 'number', description: 'Frames to trace the intro line toward the first action.', min: 1, max: 90, step: 1},
    {path: 'motion.lineWidth', label: 'Route weight', type: 'number', description: 'Line weight in output pixels.', min: 1, max: 12, step: 1},
    {path: 'motion.markerRadius', label: 'Station size', type: 'number', description: 'Full-map station radius in pixels.', min: 5, max: 20, step: 1},
    {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', description: 'Fraction of iPhone scene assigned to the first still.', min: 0.2, max: 0.8, step: 0.05},
  ],
});
