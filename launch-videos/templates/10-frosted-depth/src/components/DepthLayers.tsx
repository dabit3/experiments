import React from "react";
import { Glass } from "./Glass";

/**
 * The two rear depth levels: large, dim panes that sit behind the front layer and give the
 * backdrop-filter something to frost. They persist across scenes so the space feels continuous.
 */
export const DepthLayers: React.FC<{ sceneFrom: number; opacity?: number }> = ({ sceneFrom, opacity = 1 }) => (
  <>
    {/* Level 0 — far back */}
    <Glass x={-260} y={120} width={900} height={640} depth={0.15} sceneFrom={sceneFrom} opacity={0.55 * opacity} />
    <Glass x={1380} y={-180} width={760} height={560} depth={0.2} sceneFrom={sceneFrom} opacity={0.5 * opacity} />
    {/* Level 1 — mid */}
    <Glass x={1180} y={700} width={720} height={520} depth={0.5} sceneFrom={sceneFrom} opacity={0.7 * opacity} />
    <Glass x={140} y={820} width={520} height={380} depth={0.45} sceneFrom={sceneFrom} opacity={0.6 * opacity} />
  </>
);
