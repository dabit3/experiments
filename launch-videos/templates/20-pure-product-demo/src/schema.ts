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
  black: zColor(),
  white: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string().describe("Lockup used on light backgrounds (path under assets/)"),
  logoDark: z.string().describe("Lockup used on dark backgrounds (path under assets/)"),
  fontFaces: z
    .array(
      z.object({
        family: z.string(),
        src: z.string().describe("Path under assets/, e.g. fonts/NBInternationalPro-Regular.woff2"),
        weight: z.number(),
      }),
    )
    .describe("Optional @font-face declarations for licensed fonts dropped into assets/fonts"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z
    .string()
    .describe("Substring of the headline set in the accent color; empty for none"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
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
  src: z.string().describe("Path under assets/, passed to staticFile()"),
  kind: z.enum(["image", "video"]),
  width: z.number().describe("Source pixel width (used to keep the crop pixel-accurate)"),
  height: z.number().describe("Source pixel height"),
  startFrom: z.number().optional().describe("Video only: first source frame (at 30fps)"),
  playbackRate: z.number().optional().describe("Video only: 1 = real time"),
  crop: cropSchema.optional().describe("Fractions of the source; omitted = full frame"),
});

export const zoomSchema = z.object({
  from: z.number(),
  to: z.number(),
  originX: z.number().min(0).max(1),
  originY: z.number().min(0).max(1),
});

export const shotSchema = z.object({
  media: z.string().describe("Key of media[]"),
  at: z.number().describe("Frame within the scene at which this shot cuts in"),
  zoom: zoomSchema.optional(),
});

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().positive(),
};

export const statementSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("statement"),
});

export const demoSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("demo"),
  shots: z.array(shotSchema).min(1),
  caption: z.number().int().nullable().describe("Index into content.captions"),
  stage: z.number().int().nullable().describe("Index into content.stages"),
  captionSide: z.enum(["bottom", "right"]),
  speedLabel: z.string().nullable().describe("Shown as a badge when footage is sped up"),
});

export const outroSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("outro"),
});

export const sceneSchema = z.discriminatedUnion("kind", [
  statementSceneSchema,
  demoSceneSchema,
  outroSceneSchema,
]);

export const layoutSchema = z.object({
  marginX: z.number(),
  marginTop: z.number(),
  marginBottom: z.number(),
  captionBand: z.number().describe("Height reserved for captions below the stage"),
  captionColumn: z.number().describe("Width reserved for captions beside the stage"),
  gap: z.number(),
  frameRadius: z.number(),
  captionSize: z.number(),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema).min(1),
  layout: layoutSchema,
  posterFrame: z.number().int().nonnegative(),
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type Zoom = z.infer<typeof zoomSchema>;
export type Shot = z.infer<typeof shotSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type DemoScene = z.infer<typeof demoSceneSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
