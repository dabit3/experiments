import { Composition } from "remotion";
import { Main } from "./Main";
import { TOTAL_FRAMES } from "./scenes";
import { FPS, HEIGHT, WIDTH } from "./theme";

export const Root: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={TOTAL_FRAMES}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);
