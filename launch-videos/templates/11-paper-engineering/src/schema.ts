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
  logoLight: z.string(),
  logoDark: z.string(),
  /**
   * Optional licensed NB International Pro files, relative to the assets dir
   * (e.g. "fonts/NBInternationalPro-Regular.woff2"). When set, an @font-face is
   * injected so `fontFamily` resolves to the real brand face instead of Inter.
   */
  customFontFiles: z
    .object({ regular: z.string(), medium: z.string() })
    .optional(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  /** A word or phrase inside `headline` that is set in the accent color. */
  accentWord: z.string().optional(),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

export const mediaSlotSchema = z.object({
  src: z.string(),
  kind: z.enum(["image", "video"]),
  /** First frame of the source to show (video only). */
  startFrom: z.number().int().min(0).optional(),
  /** Crop as fractions of the source (0-1). Crop/scale only; never skew. */
  crop: z
    .object({
      x: z.number().min(0).max(1),
      y: z.number().min(0).max(1),
      w: z.number().min(0).max(1),
      h: z.number().min(0).max(1),
    })
    .optional(),
  playbackRate: z.number().positive().optional(),
  /** Width / height of the *uncropped* source. Defaults to 16/9. */
  aspect: z.number().positive().optional(),
});

export const revealKindSchema = z.enum(["lift", "sleeve", "fold", "cut"]);

const sceneBase = {
  id: z.string(),
  durationInFrames: z.number().int().positive(),
};

export const titleSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("title"),
  /** Media slot shown flat beneath the title sheet, revealed when it slides away. */
  media: z.string(),
  /** Direction the title sheet slides away in. */
  exit: z.enum(["left", "right", "up"]),
});

export const demoSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("demo"),
  media: z.string(),
  /** 1-based index into content.captions. Omit to keep the previous caption. */
  caption: z.number().int().positive().optional(),
  /** 1-based index into content.stages shown at the right of the caption strip. */
  stage: z.number().int().positive().optional(),
  /** How the divider uncovers this demonstration. */
  reveal: revealKindSchema,
});

export const outroSceneSchema = z.object({
  ...sceneBase,
  kind: z.literal("outro"),
  /** Media slot for the result that stays on screen next to the CTA. */
  media: z.string(),
});

export const sceneSchema = z.discriminatedUnion("kind", [
  titleSceneSchema,
  demoSceneSchema,
  outroSceneSchema,
]);

export const layoutSchema = z.object({
  /** Outer safe margin (px at 1920x1080). */
  margin: z.number(),
  /** Vertical space reserved for the logo row above the stage. */
  headerHeight: z.number(),
  /** Height of the separate caption strip below the stage. */
  captionStripHeight: z.number(),
  /** Gap between stage and caption strip. */
  gap: z.number(),
  /** Matte border around a screenshot / recording on its plate. */
  platePadding: z.number(),
  plateRadius: z.number(),
  mediaRadius: z.number(),
  /** Width of the result plate in the final composition (px). */
  outroPlateWidth: z.number(),
});

export const motionSchema = z.object({
  /** Frames the title sheet takes to slide away. */
  titleExit: z.number().int().positive(),
  /** Total frames a divider takes to cover and uncover (half in, half out). */
  reveal: z.number().int().positive(),
  /** Frames a new caption takes to slide into the strip. */
  caption: z.number().int().positive(),
  /** Frames for the final layout move into the CTA composition. */
  layoutMove: z.number().int().positive(),
});

export const surfaceSchema = z.object({
  /** 0 = flat, 1 = brand shadow, 2 = strong. */
  shadowStrength: z.number().min(0).max(2),
  /** 0 = none, 1 = the most texture allowed (still very subtle). */
  texture: z.number().min(0).max(1),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema),
  layout: layoutSchema,
  motion: motionSchema,
  surface: surfaceSchema,
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type RevealKind = z.infer<typeof revealKindSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type TitleScene = z.infer<typeof titleSceneSchema>;
export type DemoScene = z.infer<typeof demoSceneSchema>;
export type OutroScene = z.infer<typeof outroSceneSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type Motion = z.infer<typeof motionSchema>;
export type Surface = z.infer<typeof surfaceSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
