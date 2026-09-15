import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const motionControls: ConfigControl[] = [
  {path: 'motion.dividerFrames', label: 'Divider travel', type: 'number', description: 'Frames for a synchronized change of panel ratio.', min: 0, max: 60, step: 1},
  {path: 'motion.activeAt', label: 'Active side cue', type: 'number', description: 'Fraction of each still hold when the result gains space.', min: 0, max: 1, step: 0.01},
  {path: 'motion.balancedAt', label: 'Comparison cue', type: 'number', description: 'Fraction when the divider returns to the comparison ratio.', min: 0, max: 1, step: 0.01},
  {path: 'motion.unifyAt', label: 'Complete source cue', type: 'number', description: 'Fraction when both crops resolve into the uncut source screenshot.', min: 0, max: 1, step: 0.01},
  {path: 'motion.iphoneSwitchAt', label: 'iPhone example cut', type: 'number', description: 'Fraction of the iPhone scene devoted to the first source.', min: 0.1, max: 0.9, step: 0.01},
  {path: 'motion.openingSplit', label: 'Title divider position', type: 'number', description: 'Title and CTA divider as a fraction of canvas width.', min: 0.4, max: 0.65, step: 0.01},
  {path: 'motion.videoRailRatio', label: 'Recording label rail', type: 'number', description: 'Proportion reserved for stable action/result labels beside the complete recording.', min: 0.1, max: 0.25, step: 0.01},
  {path: 'motion.closingCtaAt', label: 'Closing CTA cue', type: 'number', description: 'Fraction of closing held on the full-frame result before the CTA.', min: 0, max: 0.8, step: 0.01},
  {path: 'motion.shutterFrames', label: 'Rail reveal', type: 'number', description: 'Frames for the editorial rail rule; never masks source video.', min: 0, max: 60, step: 1},
  {path: 'motion.dividerWidth', label: 'Divider weight', type: 'number', description: 'Divider width in output pixels.', min: 1, max: 8, step: 1},
];

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...motionControls,
    ...['environment', 'iphone.0', 'iphone.1', 'ipad'].flatMap((key): ConfigControl[] => [
      {path: `pairings.${key}.balancedRatio`, label: `${key}: comparison ratio`, type: 'number', description: 'Left panel fraction during the balanced comparison hold.', min: 0.2, max: 0.7, step: 0.01},
      {path: `pairings.${key}.activeRatio`, label: `${key}: active ratio`, type: 'number', description: 'Left panel fraction while the right-hand result is active.', min: 0.2, max: 0.7, step: 0.01},
      {path: `pairings.${key}.leftLabel`, label: `${key}: left label`, type: 'string', description: 'Literal description outside source controls.'},
      {path: `pairings.${key}.rightLabel`, label: `${key}: right label`, type: 'string', description: 'Literal description outside source controls.'},
    ]),
    {path: 'copy.opening', label: 'Opening copy', type: 'string', description: 'Launch opening; all captions and CTA are editable in copy.'},
    {path: 'copy.cta', label: 'Closing CTA', type: 'string', description: 'Final invitation.'},
    {path: 'brand.colors.canvas', label: 'Canvas', type: 'color', description: 'Presentation canvas only; source pixels remain unchanged.'},
    {path: 'layout.margin', label: 'Scene margin', type: 'number', description: 'Outer product-stage margin in output pixels.', min: 24, max: 100, step: 1},
  ],
});
