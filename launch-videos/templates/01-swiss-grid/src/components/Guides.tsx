import { AbsoluteFill } from "remotion";
import { HEIGHT } from "../defaults";
import { columnWidth, columnX } from "../layout";
import type { Brand, Grid } from "../schema";

/** Column hairlines. They sit behind everything and never move. */
export const Guides = ({ grid, brand }: { grid: Grid; brand: Brand }) => {
  if (!grid.showGuides) {
    return null;
  }
  const w = columnWidth(grid);
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {Array.from({ length: grid.columns }, (_, i) => {
        const x = columnX(grid, i + 1);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: grid.margin,
              width: w,
              height: HEIGHT - grid.margin * 2,
              borderLeft: `1px solid ${brand.line}`,
              borderRight: i === grid.columns - 1 ? `1px solid ${brand.line}` : undefined,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};
