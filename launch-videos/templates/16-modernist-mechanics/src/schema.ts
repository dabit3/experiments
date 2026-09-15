import {z} from 'zod';
import {zColor} from '@remotion/zod-types';

export const brandSchema = z.object({
  paper: zColor(),
  surface: zColor(),
  line: zColor(),
  ink: zColor(),
  inkMuted: zColor(),
  inkSubtle: zColor(),
  accent: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe('Lockup used on light backgrounds (public path)'),
  logoDark: z.string().describe('Lockup used on dark backgrounds (public path)'),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z
    .string()
    .describe('Substring of the headline set in the accent color (empty = none)'),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({label: z.string(), url: z.string()}),
  outroLine: z.string(),
  speedBadge: z.string(),
});

export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSlotSchema = z.object({
  name: z.string().describe('Slot name that scenes refer to'),
  src: z.string().describe('Path relative to launch-videos/assets'),
  kind: z.enum(['image', 'video']),
  width: z.number().describe('Intrinsic pixel width of the source'),
  height: z.number().describe('Intrinsic pixel height of the source'),
  startFrom: z.number().optional(),
  playbackRate: z.number().optional(),
  crop: cropSchema.optional(),
});

export const mediaSchema = z.array(mediaSlotSchema).min(1);

/** Where the product frame sits and what the caption plane does. */
export const compositionSchema = z.enum([
  'media-right', // caption plane left, product frame right (asymmetric)
  'media-left', // product frame left, caption plane right
  'media-wide', // frame spans the safe width, caption below-left
  'tiles', // two framed crops side by side, caption plane left
]);

export const openSceneSchema = z.object({
  id: z.string(),
  type: z.literal('open'),
  durationInFrames: z.number().int().positive(),
});

export const demoSceneSchema = z.object({
  id: z.string(),
  type: z.literal('demo'),
  durationInFrames: z.number().int().positive(),
  composition: compositionSchema,
  media: z.array(z.string()).min(1).describe('Media slot names (1, or 2 for tiles)'),
  caption: z.number().int().min(0).describe('Index into content.captions'),
  stage: z.number().int().min(0).describe('Index into content.stages'),
  label: z.string().optional().describe('Short literal label above the caption'),
  showSpeedBadge: z.boolean().optional(),
  selector: z
    .object({
      options: z.array(z.string()).min(2),
      from: z.number().int().min(0).describe('Index selected when the plane settles'),
      to: z.number().int().min(0).describe('Index the indicator moves to'),
      switchAt: z.number().int().min(0).describe('Frames after settle before the move'),
    })
    .optional()
    .describe('Brand-styled selector in the caption plane (not a UI redraw)'),
  split: z
    .number()
    .min(0.4)
    .max(0.85)
    .optional()
    .describe('Fraction of the safe width given to the product frame'),
});

export const resultSceneSchema = z.object({
  id: z.string(),
  type: z.literal('result'),
  durationInFrames: z.number().int().positive(),
  media: z.string(),
  caption: z.number().int().min(0),
  stage: z.number().int().min(0),
  label: z.string().optional(),
});

export const outroSceneSchema = z.object({
  id: z.string(),
  type: z.literal('outro'),
  durationInFrames: z.number().int().positive(),
  media: z.string().describe('The result stays on screen while the structure resolves'),
});

export const sceneSchema = z.discriminatedUnion('type', [
  openSceneSchema,
  demoSceneSchema,
  resultSceneSchema,
  outroSceneSchema,
]);

/** Roles of the shape vocabulary. Each role is a flat plane with one job. */
export const shapesSchema = z.object({
  frame: z.object({
    fill: zColor().describe('Plane color of the product frame before it opens'),
    border: zColor(),
    borderWidth: z.number(),
  }),
  rule: z.object({
    color: zColor(),
    progressColor: zColor(),
    thickness: z.number(),
    y: z.number().describe('Baseline of the progression line (px from top)'),
  }),
  tiles: z.object({
    size: z.number(),
    fill: zColor(),
    activeFill: zColor(),
  }),
  plane: z.object({
    fill: zColor().describe('Caption plane color'),
    text: zColor(),
    textMuted: zColor(),
    padding: z.number(),
    captionSize: z.number().describe('Caption font size in px'),
  }),
});

export const motionSchema = z.object({
  transitionFrames: z.number().int().min(2).describe('Length of a scene-to-scene move'),
  entranceFrames: z.number().int().min(2),
  slideDistance: z.number().describe('px a shape travels when it enters'),
  stagger: z.number().int().min(0).describe('Frames between staggered entrances'),
});

export const layoutSchema = z.object({
  margin: z.number(),
  gutter: z.number(),
  radius: z.number(),
  defaultSplit: z.number().min(0.4).max(0.85),
  maxPlaneWidth: z.number().describe('Caption plane never grows wider than this (px)'),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: mediaSchema,
  scenes: z.array(sceneSchema).min(1),
  shapes: shapesSchema,
  motion: motionSchema,
  layout: layoutSchema,
});

export type LaunchProps = z.infer<typeof launchPropsSchema>;
export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type DemoScene = z.infer<typeof demoSceneSchema>;
export type ResultScene = z.infer<typeof resultSceneSchema>;
export type OutroScene = z.infer<typeof outroSceneSchema>;
export type Shapes = z.infer<typeof shapesSchema>;
export type Motion = z.infer<typeof motionSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type Composition = z.infer<typeof compositionSchema>;
