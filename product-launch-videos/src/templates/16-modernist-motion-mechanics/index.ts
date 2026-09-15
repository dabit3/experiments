import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import manifest from './manifest.json';
import {Template} from './Template';

const numberControl = (
  path: string, label: string, description: string, min: number, max: number, step = 1,
): ConfigControl => ({path, label, description, type: 'number', min, max, step});

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    numberControl('motion.revealFrames', 'Aperture travel', 'Frame-driven opposing matte reveal; videos remain unobscured from frame zero.', 0, 60),
    numberControl('motion.transitionDistance', 'Mechanical travel', 'Pixel travel of opening planes and closing tiles.', 0, 360),
    numberControl('motion.openingAssembleFrames', 'Opening assembly', 'Frames for the two rectangles to reach exact alignment.', 0, 60),
    numberControl('motion.tileTravel', 'Tile travel', 'Distance of editorial index tile entry.', 0, 120),
    numberControl('motion.closingResolveFrames', 'Result resolve', 'Frames to move the intact result into the closing composition.', 0, 90),
    numberControl('motion.iphoneSplit', 'iPhone still split', 'Fraction of the iPhone segment assigned to the first genuine still.', 0.1, 0.9, 0.05),
    {path: 'motion.revealAxis', label: 'Division axis', type: 'string', description: 'x or y; opposing matte planes uncover stills without dividing source pixels.'},
    {path: 'geometry.rectangleRole', label: 'Rectangle role', type: 'string', description: 'frame gives a thin outline; plane gives a flat surrounding mat.'},
    {path: 'geometry.lineRole', label: 'Line role', type: 'string', description: 'progression indexes editorial examples, rule keeps a full-length static line. Neither is execution telemetry.'},
    {path: 'geometry.showTiles', label: 'Stage tiles', type: 'boolean', description: 'Show the five editorial example tiles in opening, footer and closing.'},
    numberControl('geometry.frameThickness', 'Frame weight', 'Outline thickness in pixels.', 0, 12),
    numberControl('geometry.lineThickness', 'Line weight', 'Editorial rule thickness in pixels.', 1, 12),
    numberControl('geometry.tileSize', 'Tile size', 'Opening/rail tile size in pixels.', 24, 80),
    ...Object.keys(config.composition).map((key) =>
      numberControl(`composition.${key}`, key, 'Composition geometry or typography in 1920 × 1080 pixels.', 1, 1920)),
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: key, type: 'string', description: 'Editable launch copy; captions stay outside the product viewport.',
    })),
    ...Object.keys(config.durations).map((key) =>
      numberControl(`durations.${key}`, `${key} seconds`, 'Scene duration; composition length derives from all seven scenes. Videos must fit their source trim.', 0.5, 30, 0.5)),
    ...config.labels.stages.map((_, index): ConfigControl => ({
      path: `labels.stages.${index}`, label: `Stage ${index + 1}`, type: 'string', description: 'Editorial example label.',
    })),
    ...['montage', 'still', 'result'].map((key): ConfigControl => ({
      path: `labels.${key}`, label: key, type: 'string', description: 'Supporting source-context label.',
    })),
    ...Object.keys(config.brand.colors).map((key): ConfigControl => ({
      path: `brand.colors.${key}`, label: key, type: 'color', description: 'Presentation color; original interface pixels are not recolored.',
    })),
    ...Object.entries(config.brand.typography).map(([key, value]): ConfigControl => ({
      path: `brand.typography.${key}`, label: key, type: typeof value === 'number' ? 'number' : 'string',
      description: 'Brand typography; use the bundled fonts loaded by the shared font gate.',
    })),
    ...['margin', 'gutter', 'padding', 'captionHeight', 'grid.railWidth', 'grid.footerHeight'].map((key) =>
      numberControl(`layout.${key}`, key, 'Scene spacing in pixels.', 0, 200)),
    ...['logo', 'environment', 'agent', 'iphone.0', 'iphone.1', 'webQa', 'ipad'].flatMap((key): ConfigControl[] => [
      {path: `media.${key}.asset`, label: `${key} asset`, type: 'string', description: 'Exact filename from the verified shared asset manifest.'},
      {path: `media.${key}.framing.fit`, label: `${key} fit`, type: 'string', description: 'contain or cover; use contain for result reports.'},
      numberControl(`media.${key}.framing.anchorX`, `${key} horizontal anchor`, 'Normalized source crop anchor.', 0, 1, 0.05),
      numberControl(`media.${key}.framing.anchorY`, `${key} vertical anchor`, 'Normalized source crop anchor.', 0, 1, 0.05),
      ...['x', 'y', 'width', 'height'].map((axis) =>
        numberControl(`media.${key}.framing.crop.${axis}`, `${key} crop ${axis}`, 'Optional crop rectangle in original source pixels; supply all four fields together or omit crop.', 0, 5000)),
    ]),
    ...['agent', 'webQa'].map((key) =>
      numberControl(`media.${key}.sourceStartSeconds`, `${key} source offset`, 'Source trim in seconds at 1×; scene plus offset must fit source duration.', 0, 50, 0.1)),
  ],
});
