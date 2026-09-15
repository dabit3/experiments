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
  useLicensedFont: z
    .boolean()
    .describe("Register @font-face for NBInternationalPro-*.woff2 from assets/fonts/"),
  logoLight: z.string(),
  logoDark: z.string(),
});

export const contentSchema = z.object({
  featureName: z.string(),
  eyebrow: z.string(),
  headline: z.string(),
  headlineAccent: z.string().describe("Substring of headline set in the accent color"),
  subhead: z.string(),
  captions: z.array(z.string()),
  useCases: z.array(z.string()),
  stages: z.array(z.string()),
  cta: z.object({ label: z.string(), url: z.string() }),
  outroLine: z.string(),
  speedBadge: z.string(),
});

export const cropSchema = z
  .object({
    x: z.number(),
    y: z.number(),
    w: z.number(),
    h: z.number(),
  })
  .describe("Window into the source media, as fractions 0-1 of its width/height");

export const mediaSlotSchema = z.object({
  src: z.string().describe("Path relative to launch-videos/assets, e.g. screenshots/devin-web-1.png"),
  kind: z.enum(["image", "video"]),
  width: z.number().describe("Natural pixel width of the source"),
  height: z.number().describe("Natural pixel height of the source"),
  startFrom: z.number().optional().describe("Video only: first source frame to show"),
  playbackRate: z.number().optional(),
});

export const cameraViewSchema = z.object({
  crop: cropSchema,
  planeWidth: z
    .number()
    .describe("Width of the display plane as a fraction of the frame width (>1 for close-ups)"),
  x: z.number().describe("Plane centre, fraction of frame width"),
  y: z.number().describe("Plane centre, fraction of frame height"),
});

export const cameraSchema = z.object({
  from: cameraViewSchema,
  to: cameraViewSchema,
  easing: z.enum(["linear", "out", "inOut"]),
  settleFrames: z
    .number()
    .int()
    .min(0)
    .describe("Frames before the scene ends at which the camera reaches `to` and holds"),
});

export const lightingSchema = z.object({
  keyX: z.number().describe("Key light position, fraction of frame width"),
  keyY: z.number().describe("Key light position, fraction of frame height"),
  keyRadius: z.number().describe("Key light falloff radius, fraction of frame width"),
  keyIntensity: z.number().min(0).max(1),
  vignette: z.number().min(0).max(1),
  shadowStrength: z.number().min(0).max(2),
  planeBorder: z.boolean(),
});

export const transitionSchema = z.enum(["tilt", "fade", "none"]);

export const captionPlacementSchema = z.enum(["left", "right", "below", "above"]);

export const sceneSchema = z.object({
  id: z.string(),
  kind: z.enum(["film", "cta"]),
  durationInFrames: z.number().int().min(1),
  media: z.string().nullable().describe("Key into media slots, or null for no plane"),
  camera: cameraSchema.nullable(),
  caption: z.number().int().nullable().describe("Index into content.captions"),
  stage: z.number().int().nullable().describe("Index into content.stages, shown as a mono eyebrow"),
  captionPlacement: captionPlacementSchema,
  captionWidth: z.number().describe("Caption column width, fraction of frame width"),
  showTitle: z.boolean().describe("Show eyebrow + headline + subhead block in the caption column"),
  titleDelay: z.number().int().describe("Frames into the scene before the title/caption enters"),
  showLogo: z.boolean(),
  transitionIn: transitionSchema,
  transitionOut: transitionSchema,
});

export const launchPropsSchema = z.object({
  brand: brandSchema,
  content: contentSchema,
  media: z.record(z.string(), mediaSlotSchema),
  scenes: z.array(sceneSchema),
  lighting: lightingSchema,
  transitionFrames: z.number().int().min(1),
  tiltDegrees: z.number().describe("Perspective tilt of the plane while a tilt transition runs"),
});

export type Brand = z.infer<typeof brandSchema>;
export type Content = z.infer<typeof contentSchema>;
export type Crop = z.infer<typeof cropSchema>;
export type MediaSlot = z.infer<typeof mediaSlotSchema>;
export type CameraView = z.infer<typeof cameraViewSchema>;
export type Camera = z.infer<typeof cameraSchema>;
export type Lighting = z.infer<typeof lightingSchema>;
export type Scene = z.infer<typeof sceneSchema>;
export type LaunchProps = z.infer<typeof launchPropsSchema>;
