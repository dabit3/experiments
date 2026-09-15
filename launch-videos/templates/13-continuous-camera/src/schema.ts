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
  blackRaised: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  /** Paths (relative to assets/) of licensed NB International Pro woff2 files. Omit to use Inter. */
  licensedFontFiles: z.object({ regular: z.string(), medium: z.string() }).optional(),
  logoLight: z.string(),
  logoDark: z.string(),
});

export const mediaSlotSchema = z.object({
  src: z.string(),
  kind: z.enum(["image", "video"]),
  startFrom: z.number().int().min(0).optional(),
  crop: z
    .object({
      x: z.number().min(0).max(1),
      y: z.number().min(0).max(1),
      w: z.number().min(0).max(1),
      h: z.number().min(0).max(1),
    })
    .optional(),
  playbackRate: z.number().positive().optional(),
  /** Pixel size of the source asset; used to derive the frame aspect (default 1920x1080). */
  sourceSize: z.object({ w: z.number().positive(), h: z.number().positive() }).optional(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z.string(),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

/**
 * A station is one stopping point on the canvas. The camera travels
 * `travelInFrames` to reach it, then holds for `holdFrames`.
 * Positions are canvas coordinates of the station's centre (px).
 */
export const stationSchema = z.object({
  id: z.string(),
  kind: z.enum(["opening", "media", "cta"]),
  x: z.number(),
  y: z.number(),
  travelInFrames: z.number().int().min(0),
  holdFrames: z.number().int().min(1),
  /** Camera zoom while holding at this station (1 = canvas px == screen px). */
  zoom: z.number().positive().optional(),
  /** Stage label shown on the route line under the station ("Build"). */
  stageLabel: z.string().optional(),
  /** Index into content.captions (media stations). */
  captionIndex: z.number().int().min(0).optional(),
  /** Use-case label shown above the caption (media stations). */
  useCaseLabel: z.string().optional(),
  /** Named slot(s) in `media`. A second slot cross-fades in halfway through the hold. */
  mediaSlot: z.string().optional(),
  mediaSlotB: z.string().optional(),
  /** Where the caption sits relative to the media. */
  textSide: z.enum(["left", "right"]).optional(),
  /** Width of the media frame on the canvas (px). Height follows the media aspect. */
  mediaWidth: z.number().positive().optional(),
  /** Show the speed badge on the media frame. */
  showSpeedBadge: z.boolean().optional(),
});

export const cameraSchema = z.object({
  /** Ease used for travel between stations. */
  easing: z.enum(["inOutCubic", "inOutSine"]),
  /** Draw the accent route line and station dots on the canvas. */
  showRoute: z.boolean(),
  /** Vertical offset of the route line from station centre (px). */
  routeOffsetY: z.number(),
  /** Dot grid spacing on the paper canvas (px). 0 disables the grid. */
  gridSpacing: z.number().min(0),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(stationSchema),
  camera: cameraSchema,
});

export type Brand = z.infer<typeof brandSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Content = z.infer<typeof contentSchema>;
export type Station = z.infer<typeof stationSchema>;
export type Camera = z.infer<typeof cameraSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
