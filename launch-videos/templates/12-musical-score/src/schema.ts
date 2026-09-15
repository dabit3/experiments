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
  logoLight: z.string().describe("Lockup shown on light backgrounds (path under assets/)"),
  logoDark: z.string().describe("Lockup shown on dark backgrounds (path under assets/)"),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path under launch-videos/assets, e.g. recordings/androidios.mp4"),
  kind: z.enum(["image", "video"]),
  width: z.number().optional().describe("Source pixel width (defaults to 1920)"),
  height: z.number().optional().describe("Source pixel height (defaults to 1080)"),
  startFrom: z.number().optional().describe("Video only: first source frame to show"),
  playbackRate: z.number().optional(),
  crop: z
    .object({ x: z.number(), y: z.number(), w: z.number(), h: z.number() })
    .optional()
    .describe("Fractions 0-1 of the source; the crop is scaled, never skewed"),
});

export const cueSchema = z.object({
  at: z.number().describe("Frame offset inside the scene when this footage event lands"),
  label: z.string().describe("Short event name shown on the track and in the cue log"),
  mediaSlot: z.string().optional().describe("Switch the large view to this media slot"),
  captionIndex: z.number().optional().describe("Switch to content.captions[index]"),
  accent: z.boolean().optional().describe("Pulse the accent ring on the playhead (default true)"),
});

export const sceneSchema = z.object({
  id: z.string(),
  kind: z.enum(["intro", "stage", "outro"]),
  durationInFrames: z.number().min(1),
  track: z.number().optional().describe("Stage only: index into content.stages (the track row)"),
  mediaSlot: z.string().optional().describe("Stage only: media slot shown when the stage arrives"),
  captionIndex: z.number().optional().describe("Stage only: content.captions[index] shown on arrival"),
  span: z
    .object({ start: z.number(), end: z.number() })
    .optional()
    .describe(
      "Stage only: horizontal extent on the score as fractions 0-1. Defaults to equal sequential bars; overlapping spans place parallel work side by side",
    ),
  cues: z.array(cueSchema).optional(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z.string().describe("Substring of the headline set in the accent color"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()).describe("Track labels, one per workflow stage"),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string().describe("Shown next to footage only when playbackRate > 1"),
});

export const layoutSchema = z.object({
  margin: z.number(),
  mediaWidth: z.number(),
  mediaHeight: z.number(),
  mediaTop: z.number(),
  captionGap: z.number(),
  stripTop: z.number(),
  stripHeight: z.number(),
  labelColumnWidth: z.number(),
  playheadEaseFrames: z.number(),
});

export const soundSchema = z.object({
  enabled: z.boolean().describe("Off by default: v1 renders silent and the captions carry the story"),
  cueAccentSrc: z.string().optional().describe("Path under assets/ to a short accent played on each cue"),
  volume: z.number().min(0).max(1),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema),
  layout: layoutSchema,
  sound: soundSchema,
});

export type LaunchProps = z.infer<typeof launchPropsSchema>;
export type Brand = z.infer<typeof brandSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Cue = z.infer<typeof cueSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type Content = z.infer<typeof contentSchema>;
