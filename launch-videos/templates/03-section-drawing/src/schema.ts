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
  /** Opacity of the drafting grid while a diagram is on screen (0 hides it). */
  gridOpacity: z.number().min(0).max(1),
  /** Spacing of the drafting grid in px. */
  gridSize: z.number().min(16),
});

export const stageSchema = z.object({
  id: z.string(),
  label: z.string(),
  /** Media slot shown as this stage's plane in the overview diagram. */
  media: z.string(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  /** Word(s) in the headline that are set in the accent color. */
  headlineAccent: z.string(),
  subhead: z.string(),
  /** Heading above the stage diagram in the overview scene. */
  overviewTitle: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(stageSchema),
  /** Diagram connections between stages: [fromIndex, toIndex]. Defaults to a chain. */
  connections: z.array(z.tuple([z.number(), z.number()])),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  /** Word(s) in the outro line set in the accent color. */
  outroAccent: z.string(),
  speedBadge: z.string(),
  /** Title-block metadata drawn in the corner of the sheet. */
  sheet: z.object({ number: z.string(), title: z.string(), scale: z.string() }),
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
  /** Source pixel size, used to keep the plane's aspect ratio exact. */
  width: z.number(),
  height: z.number(),
  startFrom: z.number().optional(),
  crop: cropSchema.optional(),
  playbackRate: z.number().optional(),
  /** Set when the footage is sped up; the speed badge is then shown. */
  speedBadge: z.boolean().optional(),
});

/** A caption anchored to a point on a media plane by a short leader line. */
export const annotationSchema = z.object({
  /** Media slot the anchor refers to. */
  media: z.string(),
  /** Anchor point in fractions of the full source image/video (before crop). */
  anchor: z.object({ x: z.number().min(0).max(1), y: z.number().min(0).max(1) }),
  /** Index into content.captions. */
  caption: z.number(),
  /** Which side of the plane the caption column sits on. */
  side: z.enum(["left", "right"]),
  /** Vertical position of the caption box as a fraction of the plane height. */
  y: z.number().min(0).max(1),
  /** Frame (scene-local) at which the leader begins to draw. */
  startFrame: z.number(),
});

export const sceneSchema = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("title"),
    id: z.string(),
    durationInFrames: z.number().min(1),
  }),
  z.object({
    kind: z.literal("overview"),
    id: z.string(),
    durationInFrames: z.number().min(1),
    /** Frame at which the planes separate to explain the flow. */
    separateAt: z.number(),
  }),
  z.object({
    kind: z.literal("stage"),
    id: z.string(),
    durationInFrames: z.number().min(1),
    /** Index into content.stages. */
    stage: z.number(),
    /** One plane (`wide`) or two side-by-side planes (`split`). */
    layout: z.enum(["wide", "split"]),
    /** Media slots to show, in order. `wide` uses the first; `split` uses two. */
    media: z.array(z.string()).min(1),
    /** `wide` only: frame at which the second media slot is revealed over the first (aligned wipe). */
    swapAt: z.number().optional(),
    /** `forward`: the plane lifts out of the overview. `slide`: sections slide along the baseline. */
    enter: z.enum(["forward", "slide"]),
    annotations: z.array(annotationSchema),
  }),
  z.object({
    kind: z.literal("close"),
    id: z.string(),
    durationInFrames: z.number().min(1),
    /** Media slot the stages resolve into. */
    result: z.string(),
  }),
]);

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema),
  /** Motion timing knobs (frames at 30fps). */
  timing: z.object({
    enter: z.number(),
    move: z.number(),
    leader: z.number(),
  }),
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type Annotation = z.infer<typeof annotationSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type StageScene = Extract<Scene, { kind: "stage" }>;
export type OverviewScene = Extract<Scene, { kind: "overview" }>;
export type CloseScene = Extract<Scene, { kind: "close" }>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
