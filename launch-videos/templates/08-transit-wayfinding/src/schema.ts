import { z } from "zod";
import { zColor } from "@remotion/zod-types";

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
  logoLight: z.string().describe("Lockup used on light backgrounds (staticFile path)"),
  logoDark: z.string().describe("Lockup used on dark backgrounds (staticFile path)"),
  licensedFontFiles: z
    .object({ regular: z.string(), medium: z.string() })
    .optional()
    .describe("Optional NB International Pro woff2 files under assets/ (e.g. fonts/NBInternationalPro-Regular.woff2)"),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path relative to launch-videos/assets, e.g. recordings/x.mp4"),
  kind: z.enum(["image", "video"]),
  startFrom: z.number().int().min(0).optional().describe("Video start offset in source frames"),
  playbackRate: z.number().positive().optional(),
  crop: z
    .object({ x: z.number().min(0).max(1), y: z.number().min(0).max(1), w: z.number().min(0).max(1), h: z.number().min(0).max(1) })
    .optional()
    .describe("Fractional crop of the source (0-1)"),
  sourceWidth: z.number().positive(),
  sourceHeight: z.number().positive(),
});

export const branchSchema = z.object({
  label: z.string(),
  chosen: z.boolean(),
});

export const stationSchema = z.object({
  id: z.string(),
  name: z.string().describe("Station name (stage label)"),
  branches: z.array(branchSchema).optional().describe("Supported choices shown as a small junction above the marker"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccentWord: z.string().optional().describe("Single word of the headline set in the accent color"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

const sceneBase = { id: z.string(), durationInFrames: z.number().int().positive() };

export const sceneSchema = z.discriminatedUnion("type", [
  z.object({ ...sceneBase, type: z.literal("open") }),
  z.object({
    ...sceneBase,
    type: z.literal("station"),
    station: z.string().describe("Station id"),
    media: z.string().describe("Media slot name"),
    captions: z
      .array(z.object({ text: z.string(), atFrame: z.number().int().min(0) }))
      .describe("Captions shown under the recording; each holds until the next one"),
    speedBadge: z.boolean().optional(),
  }),
  z.object({ ...sceneBase, type: z.literal("link"), from: z.string(), to: z.string() }),
  z.object({ ...sceneBase, type: z.literal("outro") }),
]);

export const routeSchema = z.object({
  originLabel: z.string().describe("Terminus label at the start of the line (defaults to the feature name)"),
  stations: z.array(stationSchema).min(2),
  y: z.number().describe("Vertical position of the route line on the map (px)"),
  lineWidth: z.number(),
  markerRadius: z.number(),
});

export const timingSchema = z.object({
  arrive: z.number().int().describe("Frames spent finishing the line into the marker"),
  expand: z.number().int().describe("Frames for the recording to expand from the marker"),
  collapse: z.number().int().describe("Frames for the recording to return to the marker"),
  captionWipe: z.number().int(),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  route: routeSchema,
  timing: timingSchema,
  scenes: z.array(sceneSchema).min(1),
});

export type Brand = z.infer<typeof brandSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Station = z.infer<typeof stationSchema>;
export type Content = z.infer<typeof contentSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type StationScene = Extract<Scene, { type: "station" }>;
export type LinkScene = Extract<Scene, { type: "link" }>;
export type Route = z.infer<typeof routeSchema>;
export type Timing = z.infer<typeof timingSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
