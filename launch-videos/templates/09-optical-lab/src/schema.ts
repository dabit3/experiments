import { z } from "zod";
import { zColor } from "@remotion/zod-types";

export const brandSchema = z.object({
  paper: zColor(),
  surface: zColor(),
  surfaceAlt: zColor(),
  line: zColor(),
  ink: zColor(),
  inkMuted: zColor(),
  inkSubtle: zColor(),
  accent: zColor(),
  black: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe("Logo used on light backgrounds (public path)"),
  logoDark: z.string().describe("Logo used on dark backgrounds (public path)"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  accentWord: z
    .string()
    .describe("Word in the headline set in the accent color (exact match)"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

/** A fraction rectangle (0-1 of the media's width / height). */
export const fractionRectSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path under launch-videos/assets, e.g. recordings/androidios.mp4"),
  kind: z.enum(["image", "video"]),
  width: z.number().int().positive().describe("Source pixel width (used for aspect + magnification cap)"),
  height: z.number().int().positive().describe("Source pixel height"),
  startFrom: z.number().int().min(0).optional().describe("Video start offset in frames"),
  crop: fractionRectSchema.optional(),
  playbackRate: z.number().positive().optional(),
  highlight: z
    .object({
      rect: fractionRectSchema,
      color: zColor().optional(),
      radius: z.number().min(0).optional(),
    })
    .optional()
    .describe(
      "Editorial hover/selection tint multiplied over a region of the media (fractions of the full frame). Text and icons underneath stay untouched.",
    ),
});

export const mediaSchema = z.record(mediaSlotSchema);

/**
 * One inspection: a focus region on the media and where the enlarged view sits.
 * The inspection window keeps the focus region's aspect ratio (no distortion) and
 * its width is capped so that one source pixel is never stretched above one output
 * pixel.
 */
export const inspectionSchema = z.object({
  focus: fractionRectSchema.describe("Region of the media to enlarge (fractions of the media)"),
  window: z
    .object({
      x: z.number().min(0).max(1).describe("Left edge of the window as a fraction of the stage width"),
      y: z.number().min(0).max(1).describe("Top edge of the window as a fraction of the stage height"),
      w: z.number().min(0).max(1).describe("Window width as a fraction of the stage width"),
    })
    .describe("Where the inspection window is placed on the stage"),
  label: z.string().describe("Short annotation under the caption naming what is inspected"),
  openAt: z.number().int().min(0).describe("Frame (within the scene) at which the window opens"),
  closeAt: z
    .number()
    .int()
    .min(0)
    .optional()
    .describe("Frame (within the scene) at which the window closes; defaults to the scene end"),
});

export const sceneSchema = z.object({
  id: z.string(),
  durationInFrames: z.number().int().positive(),
  kind: z.enum(["title", "inspect", "outro"]),
  media: z.string().optional().describe("Key of the media slot shown on the stage"),
  captionIndex: z.number().int().min(0).optional().describe("Index into content.captions"),
  inspection: inspectionSchema.optional(),
});

export const layoutSchema = z.object({
  safeMargin: z.number(),
  marginWidth: z.number().describe("Width of the text margin column in px"),
  gap: z.number().describe("Gap between margin column and stage in px"),
  stageRadius: z.number(),
  windowRadius: z.number(),
  windowBorder: z.number().describe("Outline thickness of the inspection window in px"),
  logoHeight: z.number().describe("Height of the margin lockup in px"),
  outroLogoHeight: z.number().describe("Height of the outro lockup in px"),
  showSceneCounter: z.boolean().describe("Show a 01 / 06 counter above each caption"),
  showMagnification: z
    .boolean()
    .describe("Show the real magnification factor (e.g. 2.1x) next to the inspection label"),
  crossfadeFrames: z.number().int().min(0),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: mediaSchema,
  scenes: z.array(sceneSchema),
  layout: layoutSchema,
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type FractionRect = z.infer<typeof fractionRectSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Inspection = z.infer<typeof inspectionSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
