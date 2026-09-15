import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const numeric = (
  path: string, label: string, description: string, min: number, max: number, step = 1,
): ConfigControl => ({path, label, description, type: 'number', min, max, step});

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    numeric('motion.approachFrames', 'Approach duration', 'Frames before a still display settles front-facing.', 0, 90),
    numeric('motion.arrivalScale', 'Arrival scale', 'Initial still display scale; recordings stay at 1.', 0.8, 1, 0.01),
    numeric('motion.lateralTravel', 'Lateral travel', 'Short horizontal travel in pixels around still exhibits.', 0, 80),
    numeric('motion.exitFrames', 'Departure duration', 'Frames of lateral departure at the end of the iPhone wall.', 0, 45),
    numeric('motion.wallTravel', 'Wall seam travel', 'Architectural seam translation during still arrivals.', 0, 100),
    numeric('motion.titleRevealFrames', 'Title settle', 'Intro mask and end-card opacity settle duration.', 0, 60),
    numeric('motion.iphoneSplit', 'iPhone still split', 'Fraction of the iPhone scene assigned to Afterhours Maze.', 0.3, 0.7, 0.01),
    ...(['opening', 'environment', 'agent', 'iphone', 'webQa', 'ipad', 'closing'] as const).map((scene) =>
      numeric(`durations.${scene}`, `${scene} duration`, 'Seconds; metadata follows all seven durations. Videos must fit their source.', 0.1, 60, 0.1)),
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: `${key} copy`, type: 'string', description: 'Editable caption or launch text.',
    })),
    ...Object.keys(config.gallery).map((key): ConfigControl => ({
      path: `gallery.${key}`, label: key,
      type: key === 'seamColor' ? 'color' : 'number',
      description: 'Gallery geometry, label type size, or quiet lighting. Values are canvas pixels or 0–1 opacity.',
    })),
    ...config.exhibition.exhibits.flatMap((_, index): ConfigControl[] => [
      ...(['number', 'title', 'medium'] as const).map((key): ConfigControl => ({
        path: `exhibition.exhibits.${index}.${key}`, label: `Exhibit ${index + 1} ${key}`,
        type: 'string', description: 'Reusable exhibition label; newline characters create deliberate line breaks.',
      })),
      ...(['cameraX', 'cameraY'] as const).map((key) =>
        numeric(`exhibition.exhibits.${index}.${key}`, `Exhibit ${index + 1} ${key}`, 'Front-facing display camera offset in pixels.', -80, 80)),
    ]),
    ...(['logo', 'environment', 'agent', 'iphone.0', 'iphone.1', 'webQa', 'ipad'] as const).flatMap((key): ConfigControl[] => [
      {path: `media.${key}.asset`, label: `${key} media`, type: 'string', description: 'An asset filename from the shared verified inventory.'},
      ...(['anchorX', 'anchorY'] as const).map((anchor) =>
        numeric(`media.${key}.framing.${anchor}`, `${key} ${anchor}`, 'Framing anchor from 0 to 1. Crop uses original source pixels.', 0, 1, 0.01)),
    ]),
    ...(['agent', 'webQa'] as const).map((key) =>
      numeric(`media.${key}.sourceStartSeconds`, `${key} source in`, 'Source offset in seconds, always at 1× speed.', 0, 50, 0.1)),
    ...(['canvas', 'ink', 'secondaryInk', 'white', 'mediaMat'] as const).map((key): ConfigControl => ({
      path: `brand.colors.${key}`, label: key, type: 'color', description: 'Presentation surface only; original UI pixels are unchanged.',
    })),
    ...Object.entries(config.brand.typography).map(([key, value]): ConfigControl => ({
      path: `brand.typography.${key}`, label: key, type: typeof value === 'number' ? 'number' : 'string',
      description: 'Shared typography token. Use supplied local fonts.',
    })),
    ...(['margin', 'gutter', 'padding', 'captionHeight'] as const).map((key) =>
      numeric(`layout.${key}`, key, 'Scene spacing in canvas pixels.', 0, 180)),
  ],
});
