import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import manifest from './manifest.json';
import {Template} from './Template';

const control = (path: string, label: string, description: string, min: number, max: number, step = 1): ConfigControl =>
  ({path, label, type: 'number', description, min, max, step});

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    control('motion.revealFrames', 'Horizontal reveal', 'Frames for still-image reveals; recordings always begin with an unobstructed clean cut.', 0, 30),
    {path: 'motion.revealDirection', label: 'Reveal edge', type: 'string', description: 'left or right; uncover original pixels without moving internal UI.'},
    control('motion.coverRevealDelay', 'Cover reveal delay', 'Delay in frames before opening the cover photograph window.', 0, 15),
    control('motion.ruleFrames', 'Masthead rule reveal', 'Frames for the editorial rule to extend; text remains still.', 0, 30),
    control('motion.iphoneSplit', 'Aligned iPhone replacement', 'Fraction of the iPhone spread occupied by Afterhours Maze before the clean cut to Large Dispatch.', 0.2, 0.8, 0.05),
    control('editorial.coverTypeSize', 'Cover type', 'Maximum cover title size, scaled by the brand heading token; automatically reduced for longer copy.', 96, 220),
    control('editorial.captionTypeSize', 'Demonstration caption', 'Stable caption size above video and iPhone spreads.', 32, 64),
    control('editorial.marginTypeSize', 'Oversized margin words', 'Scale of the Mac and Layouts words outside the product image.', 90, 180),
    control('editorial.sideTypeSize', 'Side explanation', 'Type size in the environment and iPad explanation columns.', 32, 64),
    control('editorial.closingTypeSize', 'Closing statement', 'Type size for the pricing statement on the final spread.', 52, 96),
    control('editorial.logoWidth', 'Logo width', 'Proportional contained original logo; never stretched.', 120, 200),
    {path: 'editorial.environmentHighlight.enabled', label: 'Highlight macOS', type: 'boolean', description: 'Move the captured Ubuntu hover background to the checked macOS row in both environment crops.'},
    {path: 'editorial.edition', label: 'Edition label', type: 'string', description: 'Small editorial masthead label, separate from product content.'},
    {path: 'editorial.montageNote', label: 'Montage label', type: 'string', description: 'Explains that the examples come from separate sessions.'},
    {path: 'editorial.environmentWord', label: 'Environment margin word', type: 'string', description: 'Oversized word in the environment spread, outside UI.'},
    {path: 'editorial.layoutWord', label: 'Layouts margin word', type: 'string', description: 'Oversized word above the iPad spread.'},
    ...(['opening', 'environment', 'agent', 'iphone', 'webQa', 'ipad', 'closing'] as const).map((scene) =>
      control(`durations.${scene}`, `${scene} duration`, 'Seconds; metadata and scene positions derive from these values. Recording durations must fit the original source.', 1, scene === 'agent' ? 9 : 20, 0.5)),
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: key, type: 'string', description: 'Editable approved launch copy; preserve supported claims.',
    })),
    ...Object.keys(config.layout.grid).map((key) =>
      control(`layout.grid.${key}`, key, 'Editorial layout coordinate or dimension in the 1920 × 1080 design space.', 0, 1800)),
    control('layout.margin', 'Outer margin', 'Common outside margin in pixels.', 48, 100),
    control('layout.gutter', 'Column gutter', 'Space between explanation and product image.', 24, 80),
    control('layout.padding', 'Media mat padding', 'Inset around the cover and environment crop.', 0, 36),
    control('layout.captionHeight', 'Reserved caption strip', 'Height above full-width demonstrations; no captions cover product controls.', 90, 170),
    ...Object.keys(config.brand.colors).map((key): ConfigControl => ({
      path: `brand.colors.${key}`, label: key, type: 'color', description: 'Presentation color token; source UI colors stay unchanged.',
    })),
  ],
});
