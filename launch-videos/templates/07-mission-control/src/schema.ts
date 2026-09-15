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
  blackRaised: zColor(),
  blackRaisedAlt: zColor(),
  white: zColor(),
  /** Panel hairline on the dark console. */
  consoleLine: zColor(),
  fontFamily: z.string(),
  monoFontFamily: z.string(),
  logoLight: z.string(),
  logoDark: z.string(),
});

export const stageSchema = z.object({
  id: z.string(),
  label: z.string(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  /** Word(s) of the headline to set in the accent color. Must appear verbatim in `headline`. */
  headlineAccent: z.string().optional(),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(stageSchema),
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
  src: z.string(),
  kind: z.enum(["image", "video"]),
  /** Video only: first frame of the source to show (in source frames, 30fps). */
  startFrom: z.number().int().min(0).optional(),
  crop: cropSchema.optional(),
  playbackRate: z.number().positive().optional(),
  /** Source width / height. Needed for exact crops; defaults to 16:9. */
  aspectRatio: z.number().positive().optional(),
});

export const bayRoleSchema = z.enum(["request", "work", "artifact"]);

export const baySchema = z.object({
  id: bayRoleSchema,
  /** Short role label, shown in the bay header in mono caps. */
  label: z.string(),
  /** Key of `media` shown in the bay when it is not on the primary display. */
  media: z.string(),
});

export const statusSchema = z.enum(["standby", "live", "held"]);

export const captionCueSchema = z.object({
  /** Frame offset within the scene at which this caption becomes current. */
  at: z.number().int().min(0),
  /** Index into `content.captions`. */
  caption: z.number().int().min(0),
});

export const sceneSchema = z.object({
  id: z.string(),
  durationInFrames: z.number().int().min(1),
  /**
   * What the primary display shows: "title" (headline), "hero" (closing lockup) or a key of `media`.
   */
  primary: z.string(),
  /** Which bay is the current point of attention (gets the `live` status). */
  activeBay: bayRoleSchema.optional(),
  /** Which stage is highlighted in the header strip. */
  stage: z.string().optional(),
  /** Use-case label shown above the caption. */
  useCase: z.number().int().min(0).optional(),
  captions: z.array(captionCueSchema).default([]),
  /** Show the speed badge on the primary display (only when the footage is sped up). */
  speedBadge: z.boolean().default(false),
});

export const layoutSchema = z.object({
  safeMargin: z.number().int().min(0),
  gutter: z.number().int().min(0),
  headerHeight: z.number().int().min(0),
  captionHeight: z.number().int().min(0),
  /** Primary display width as a fraction of the content width (>= 0.55 keeps 1920px recordings legible). */
  primaryFraction: z.number().min(0.55).max(0.85),
  /** Bays column position relative to the primary display. */
  baysSide: z.enum(["right", "left"]),
  panelRadius: z.number().int().min(0),
  /** Duration of primary-display crossfades and of the closing layout consolidation. */
  transitionFrames: z.number().int().min(1),
  consolidateFrames: z.number().int().min(1),
});

export const statusLabelsSchema = z.object({
  standby: z.string(),
  live: z.string(),
  held: z.string(),
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  bays: z.array(baySchema).min(1).max(4),
  statusLabels: statusLabelsSchema,
  layout: layoutSchema,
  scenes: z.array(sceneSchema).min(1),
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type Bay = z.infer<typeof baySchema>;
export type BayRole = z.infer<typeof bayRoleSchema>;
export type BayStatus = z.infer<typeof statusSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type Layout = z.infer<typeof layoutSchema>;
export type StatusLabels = z.infer<typeof statusLabelsSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
