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
  brandFontFiles: z
    .object({ regular: z.string(), medium: z.string() })
    .nullable()
    .describe(
      "Optional licensed woff2 files under assets/ (e.g. fonts/NBInternationalPro-Regular.woff2). null = fall back to Inter",
    ),
  logoLight: z.string().describe("Lockup used on light backgrounds"),
  logoDark: z.string().describe("Lockup used on dark backgrounds"),
});

export const gridSchema = z.object({
  margin: z.number().describe("Outer safe margin in px"),
  columns: z.number().int().min(2).max(24),
  gutter: z.number(),
  railHeight: z.number().describe("Height of the top and bottom rails"),
  showGuides: z.boolean().describe("Draw the column hairlines"),
});

export const spanSchema = z.object({
  start: z.number().int().min(1).describe("1-based column"),
  span: z.number().int().min(1),
});

export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path relative to launch-videos/assets"),
  kind: z.enum(["image", "video"]),
  sourceWidth: z.number().describe("Intrinsic width of the file"),
  sourceHeight: z.number().describe("Intrinsic height of the file"),
  startFrom: z.number().int().min(0).optional().describe("Video trim, in frames"),
  crop: cropSchema.optional().describe("Fraction of the source to show"),
  playbackRate: z.number().min(0.25).max(8).optional(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z.string().describe("Substring of the headline set in the accent color"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().min(1),
};

export const statementSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("statement"),
  headlineCols: spanSchema,
  subheadCols: spanSchema,
});

export const featureSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("feature"),
  media: z.string().describe("Key of the media slot"),
  caption: z.number().int().min(0).describe("Index into content.captions"),
  useCase: z.number().int().min(0).optional().describe("Index into content.useCases"),
  stage: z.number().int().min(0).optional().describe("Index into content.stages"),
  mediaCols: spanSchema,
  textCols: spanSchema,
  enter: z.enum(["expand", "slide"]),
  mediaAlign: z.enum(["top", "center"]),
});

export const ctaSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("cta"),
  textCols: spanSchema,
});

export const sceneSchema = z.discriminatedUnion("kind", [
  statementSceneSchema,
  featureSceneSchema,
  ctaSceneSchema,
]);

export const launchPropsSchema = z.object({
  brand: brandSchema,
  grid: gridSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema).min(1),
  posterFrame: z.number().int().min(0),
});

export type Brand = z.infer<typeof brandSchema>;
export type Grid = z.infer<typeof gridSchema>;
export type Span = z.infer<typeof spanSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Content = z.infer<typeof contentSchema>;
export type StatementScene = z.infer<typeof statementSceneSchema>;
export type FeatureScene = z.infer<typeof featureSceneSchema>;
export type CtaScene = z.infer<typeof ctaSceneSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
