import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { MaskReveal } from "../components/MaskReveal";
import { Rails } from "../components/Rails";
import { WIDTH } from "../defaults";
import { columnX, contentTop, easeInOut, progress, spanWidth } from "../layout";
import type { Brand, Content, CtaScene, Grid } from "../schema";

type Props = {
  scene: CtaScene;
  brand: Brand;
  grid: Grid;
  content: Content;
  sceneIndex: number;
  sceneCount: number;
};

const COVER = 18;

/**
 * Closing composition. A dark region expands from the left grid line across
 * the whole frame, then the product name, outro line and CTA are revealed.
 */
export const Cta = ({ scene, brand, grid, content, sceneIndex, sceneCount }: Props) => {
  const frame = useCurrentFrame();
  const cover = progress(frame, 0, COVER, easeInOut);
  const x = columnX(grid, scene.textCols.start);
  const w = spanWidth(grid, scene.textCols);
  const top = contentTop(grid);

  return (
    <>
      <Rails
        brand={brand}
        grid={grid}
        content={content}
        sceneIndex={sceneIndex}
        sceneCount={sceneCount}
      />
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: Math.round(WIDTH * cover),
          height: "100%",
          overflow: "hidden",
        }}
      >
        <AbsoluteFill style={{ width: WIDTH, background: brand.black }}>
          <Rails
            brand={brand}
            grid={grid}
            content={content}
            sceneIndex={sceneIndex}
            sceneCount={sceneCount}
            dark
          />
          <div
            style={{
              position: "absolute",
              left: x,
              top: top + 96,
              width: w,
              color: brand.white,
              fontFamily: brand.fontFamily,
            }}
          >
            <MaskReveal from={COVER} length={18}>
              <Img
                src={staticFile(brand.logoDark)}
                style={{ height: 56, display: "block" }}
              />
            </MaskReveal>
            <MaskReveal from={COVER + 6} length={18} style={{ marginTop: 56 }}>
              <h1
                style={{
                  margin: 0,
                  fontSize: 112,
                  lineHeight: 1.02,
                  letterSpacing: "-0.04em",
                  fontWeight: 500,
                }}
              >
                {content.featureName}
              </h1>
            </MaskReveal>
            <MaskReveal from={COVER + 14} length={18} style={{ marginTop: 40 }}>
              <p
                style={{
                  margin: 0,
                  fontSize: 30,
                  lineHeight: 1.3,
                  letterSpacing: "-0.015em",
                  color: brand.inkSubtle,
                }}
              >
                {content.outroLine}
              </p>
            </MaskReveal>
            <MaskReveal from={COVER + 22} length={18} style={{ marginTop: 56 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 32 }}>
                <span
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    height: 56,
                    padding: "0 24px",
                    background: brand.white,
                    color: brand.black,
                    borderRadius: 2,
                    fontSize: 22,
                    fontWeight: 500,
                    letterSpacing: "-0.01em",
                  }}
                >
                  {content.cta.label}
                </span>
                <span
                  style={{
                    fontFamily: brand.monoFontFamily,
                    fontSize: 18,
                    color: brand.inkSubtle,
                  }}
                >
                  {content.cta.url}
                </span>
              </div>
            </MaskReveal>
          </div>
        </AbsoluteFill>
      </div>
    </>
  );
};
