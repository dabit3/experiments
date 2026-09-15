import { MaskReveal } from "../components/MaskReveal";
import { columnX, contentTop, spanWidth, EXIT } from "../layout";
import type { Brand, Content, Grid, StatementScene } from "../schema";

type Props = { scene: StatementScene; brand: Brand; grid: Grid; content: Content };

export const AccentHeadline = ({
  text,
  accent,
  color,
}: {
  text: string;
  accent: string;
  color: string;
}) => {
  const i = accent ? text.indexOf(accent) : -1;
  if (i < 0) {
    return <>{text}</>;
  }
  return (
    <>
      {text.slice(0, i)}
      <span style={{ color }}>{accent}</span>
      {text.slice(i + accent.length)}
    </>
  );
};

/** Opening feature statement: eyebrow, display headline, subhead in a narrow column. */
export const Statement = ({ scene, brand, grid, content }: Props) => {
  const exitAt = scene.durationInFrames - EXIT;
  const top = contentTop(grid);
  const headX = columnX(grid, scene.headlineCols.start);
  const headW = spanWidth(grid, scene.headlineCols);
  const subX = columnX(grid, scene.subheadCols.start);
  const subW = spanWidth(grid, scene.subheadCols);

  return (
    <>
      <div
        style={{
          position: "absolute",
          left: headX,
          top,
          width: headW,
          color: brand.ink,
          fontFamily: brand.fontFamily,
        }}
      >
        <MaskReveal from={0} exitAt={exitAt}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              fontFamily: brand.monoFontFamily,
              fontSize: 14,
              lineHeight: "20px",
              letterSpacing: "0.04em",
              textTransform: "uppercase",
              color: brand.inkMuted,
              height: 20,
            }}
          >
            <span style={{ width: 8, height: 8, background: brand.accent, display: "block" }} />
            {content.eyebrow}
          </div>
        </MaskReveal>
        <MaskReveal from={6} length={18} exitAt={exitAt + 2} style={{ marginTop: 40 }}>
          <h1
            style={{
              margin: 0,
              fontSize: 128,
              lineHeight: 1.02,
              letterSpacing: "-0.04em",
              fontWeight: 500,
            }}
          >
            <AccentHeadline
              text={content.headline}
              accent={content.headlineAccent}
              color={brand.accent}
            />
          </h1>
        </MaskReveal>
        <MaskReveal
          from={18}
          length={18}
          exitAt={exitAt + 4}
          style={{ marginTop: 56, marginLeft: subX - headX, width: subW }}
        >
          <p
            style={{
              margin: 0,
              fontSize: 30,
              lineHeight: 1.3,
              letterSpacing: "-0.015em",
              fontWeight: 400,
            }}
          >
            {content.subhead}
          </p>
        </MaskReveal>
      </div>
    </>
  );
};
