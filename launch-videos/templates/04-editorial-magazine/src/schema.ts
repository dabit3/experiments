import { zColor } from "@remotion/zod-types";
import { z } from "zod";

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
  logoLight: z.string().describe("Lockup used on light backgrounds (staticFile path)"),
  logoDark: z.string().describe("Lockup used on dark backgrounds (staticFile path)"),
  customFontFaces: z
    .array(
      z.object({
        family: z.string(),
        src: z.string().describe("staticFile path, e.g. fonts/NBInternationalPro-Regular.woff2"),
        weight: z.number(),
      }),
    )
    .describe("Optional @font-face declarations, e.g. the licensed NB International Pro files"),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  accentWord: z
    .string()
    .describe("Substring of the headline set in the accent color (first match)"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
  issueLabel: z.string().describe("Small running head, e.g. 'Launch notes · 04'"),
});

export const cropSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
});

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path under launch-videos/assets, e.g. screenshots/devin-web-1.png"),
  kind: z.enum(["image", "video"]),
  aspect: z
    .number()
    .describe("Intrinsic width / height of the source. Used to place the crop window.")
    .default(16 / 9),
  startFrom: z.number().int().min(0).optional(),
  playbackRate: z.number().positive().optional(),
  crop: cropSchema.optional(),
});

export const layoutSchema = z.enum(["cover", "full", "spread", "dense", "closing"]);
export const revealSchema = z.enum(["cut", "wipe"]);

export const sceneSchema = z.object({
  id: z.string(),
  durationInFrames: z.number().int().min(1),
  layout: layoutSchema,
  reveal: revealSchema.default("cut"),
  media: z
    .array(z.string())
    .describe("Keys into `media`. cover/full/spread use [0]; dense uses [0] and [1]; closing uses [0] as the outcome"),
  captionIndex: z
    .number()
    .int()
    .min(0)
    .optional()
    .describe("Index into content.captions shown as the scene's explanation"),
  kicker: z.string().optional().describe("Small mono label above the caption"),
  marginWord: z
    .string()
    .optional()
    .describe("Oversized word placed in the empty margin, never over the media"),
  mediaSide: z.enum(["left", "right"]).default("right"),
  bleed: z.boolean().default(false).describe("Let the media run off the frame edge"),
  dark: z.boolean().default(false).describe("Set the page on brand.black instead of paper"),
  mediaWidth: z
    .number()
    .min(0.3)
    .max(1)
    .optional()
    .describe("Fraction of frame width the media block takes (spread/full)"),
});

export const typeScaleSchema = z.object({
  display: z.number(),
  heading: z.number(),
  body: z.number(),
  small: z.number(),
  eyebrow: z.number(),
  marginWord: z.number(),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema),
  layoutTokens: z.object({
    margin: z.number().describe("Outer safe margin in px"),
    gutter: z.number(),
    radius: z.number(),
    revealFrames: z.number().int().describe("Length of the horizontal reveal"),
    textEnterFrames: z.number().int(),
    showFolio: z.boolean().describe("Page numbers + running head"),
  }),
  type: typeScaleSchema,
});

export type LaunchProps = z.infer<typeof launchPropsSchema>;
export type Brand = LaunchProps["brand"];
export type Content = LaunchProps["content"];
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type LayoutTokens = LaunchProps["layoutTokens"];
export type TypeScale = LaunchProps["type"];
