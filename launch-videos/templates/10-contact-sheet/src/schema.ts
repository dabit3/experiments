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
  logoLight: z.string().describe("Path under assets/ for the lockup used on light backgrounds"),
  logoDark: z.string().describe("Path under assets/ for the lockup used on dark backgrounds"),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path under launch-videos/assets, e.g. recordings/devin-working-4.mp4"),
  kind: z.enum(["image", "video"]),
  startFrom: z.number().int().min(0).optional().describe("Video only: first source frame to play"),
  thumbFrame: z
    .number()
    .int()
    .min(0)
    .optional()
    .describe("Video only: source frame used for the contact-sheet thumbnail (defaults to startFrom)"),
  playbackRate: z.number().positive().optional(),
  crop: z
    .object({ x: z.number().min(0).max(1), y: z.number().min(0).max(1), w: z.number().min(0).max(1), h: z.number().min(0).max(1) })
    .optional()
    .describe("Fraction of the source to show (0-1). Omit for the full frame."),
  fit: z.enum(["cover", "contain"]).optional().describe("How the (cropped) source fills a 16:9 frame. Default cover."),
  sourceWidth: z.number().positive().optional().describe("Intrinsic width of the source (default 1920). Needed for correct crop/fit math."),
  sourceHeight: z.number().positive().optional().describe("Intrinsic height of the source (default 1080)."),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccentWord: z.string().optional().describe("A single word of the headline set in the accent color"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

export const sheetSceneSchema = z.object({
  id: z.string(),
  kind: z.literal("sheet"),
  durationInFrames: z.number().int().min(1),
  selectAtFrame: z
    .number()
    .int()
    .min(0)
    .describe("Local frame at which the first index frame is marked as selected"),
});

export const clipSceneSchema = z.object({
  id: z.string(),
  kind: z.literal("clip"),
  durationInFrames: z.number().int().min(1),
  frameIndex: z.number().int().min(0).describe("0-based position of this clip on the contact sheet"),
  media: z.string().describe("Key of the media slot to enlarge"),
  caption: z.string().describe("Editorial caption shown under the footage, outside it"),
  label: z.string().describe("Short use-case label printed under the index frame"),
  expandFrames: z.number().int().min(1).describe("Frames for the cell to grow into the stage"),
  freezeHoldFrames: z.number().int().min(0).describe("Frames to hold the frozen end state before returning to the index"),
  freezeAtFrame: z
    .number()
    .int()
    .min(0)
    .optional()
    .describe("Video only: local clip frame at which to freeze. Defaults to the end of the play window."),
  indexFrames: z
    .number()
    .int()
    .min(1)
    .describe("Frames spent returning to and holding on the index before the next frame is selected"),
});

export const outroSceneSchema = z.object({
  id: z.string(),
  kind: z.literal("outro"),
  durationInFrames: z.number().int().min(1),
  frameIndex: z.number().int().min(0).describe("Index frame shown as the final hero"),
  media: z.string(),
  expandFrames: z.number().int().min(1),
});

export const sceneSchema = z.discriminatedUnion("kind", [sheetSceneSchema, clipSceneSchema, outroSceneSchema]);

export const sheetLayoutSchema = z.object({
  columns: z.number().int().min(1),
  cellWidth: z.number().int().min(80),
  gap: z.number().int().min(0),
  top: z.number().int().min(0).describe("Y position of the row of frames"),
  metadata: z.string().describe("Restrained one-line metadata under the sheet"),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(mediaSlotSchema),
  sheet: sheetLayoutSchema,
  scenes: z.array(sceneSchema),
});

export type Brand = z.infer<typeof brandSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Content = z.infer<typeof contentSchema>;
export type SheetScene = z.infer<typeof sheetSceneSchema>;
export type ClipScene = z.infer<typeof clipSceneSchema>;
export type OutroScene = z.infer<typeof outroSceneSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type SheetLayout = z.infer<typeof sheetLayoutSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
