import { useCurrentFrame } from "remotion";
import { MaskReveal } from "../components/MaskReveal";
import { MediaPanel, fitPanel } from "../components/MediaPanel";
import {
  ENTER,
  EXIT,
  columnX,
  contentHeight,
  contentTop,
  easeInOut,
  exitProgress,
  progress,
  spanWidth,
} from "../layout";
import type { Brand, Content, FeatureScene, Grid, MediaSlot } from "../schema";

type Props = {
  scene: FeatureScene;
  slot: MediaSlot;
  brand: Brand;
  grid: Grid;
  content: Content;
};

const pad = (n: number) => String(n).padStart(2, "0");

/**
 * One demonstration beat: a large, flat product panel on the grid beside a
 * narrow column of explanatory text. Panels enter by expanding along the top
 * alignment line or by sliding in along it; they leave by collapsing back to
 * the grid line they started from.
 */
export const Feature = ({ scene, slot, brand, grid, content }: Props) => {
  const frame = useCurrentFrame();
  const top = contentTop(grid);
  const maxH = contentHeight(grid);

  const mediaX = columnX(grid, scene.mediaCols.start);
  const mediaMaxW = spanWidth(grid, scene.mediaCols);
  const panel = fitPanel(slot, mediaMaxW, maxH);
  const mediaY = scene.mediaAlign === "center" ? top + (maxH - panel.height) / 2 : top;

  const enter = progress(frame, 0, ENTER, easeInOut);
  const exit = exitProgress(frame, scene.durationInFrames);
  const reveal = scene.enter === "expand" ? enter * (1 - exit) : 1 - exit;
  const slide = scene.enter === "slide" ? -(mediaX + panel.width + grid.gutter) * (1 - enter) : 0;

  const textX = columnX(grid, scene.textCols.start);
  const textW = spanWidth(grid, scene.textCols);
  const exitAt = scene.durationInFrames - EXIT;

  const caption = content.captions[scene.caption] ?? "";
  const useCase = scene.useCase === undefined ? undefined : content.useCases[scene.useCase];
  const showSpeed = slot.playbackRate !== undefined && slot.playbackRate !== 1;

  return (
    <>
      <div
        style={{
          position: "absolute",
          left: mediaX,
          top: mediaY,
          transform: `translateX(${slide}px)`,
        }}
      >
        <MediaPanel
          slot={slot}
          brand={brand}
          width={panel.width}
          height={panel.height}
          reveal={reveal}
        />
      </div>

      <div
        style={{
          position: "absolute",
          left: textX,
          top,
          width: textW,
          fontFamily: brand.fontFamily,
          color: brand.ink,
        }}
      >
        <MaskReveal from={6} exitAt={exitAt}>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 14,
              lineHeight: "20px",
              letterSpacing: "0.04em",
              textTransform: "uppercase",
              color: brand.inkMuted,
              display: "flex",
              justifyContent: "space-between",
            }}
          >
            <span>{useCase ?? content.featureName}</span>
            <span>{pad(scene.caption + 1)}</span>
          </div>
        </MaskReveal>
        <div
          style={{
            height: 1,
            background: brand.ink,
            marginTop: 12,
            width: `${progress(frame, 6, ENTER, easeInOut) * (1 - exit) * 100}%`,
          }}
        />
        <MaskReveal from={10} length={18} exitAt={exitAt + 2} style={{ marginTop: 24 }}>
          <p
            style={{
              margin: 0,
              fontSize: 32,
              lineHeight: 1.25,
              letterSpacing: "-0.02em",
              fontWeight: 400,
            }}
          >
            {caption}
          </p>
        </MaskReveal>
        {showSpeed ? (
          <MaskReveal from={14} exitAt={exitAt + 2} style={{ marginTop: 24 }}>
            <span
              style={{
                display: "inline-block",
                fontFamily: brand.monoFontFamily,
                fontSize: 14,
                lineHeight: "24px",
                padding: "0 8px",
                borderRadius: 8,
                border: `1px solid ${brand.line}`,
                color: brand.inkMuted,
              }}
            >
              {content.speedBadge}
            </span>
          </MaskReveal>
        ) : null}
      </div>
    </>
  );
};
