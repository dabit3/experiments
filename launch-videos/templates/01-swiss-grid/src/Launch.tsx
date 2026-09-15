import type { ReactNode } from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { Guides } from "./components/Guides";
import { Rails } from "./components/Rails";
import { brandFontFace } from "./fonts";
import { Cta } from "./scenes/Cta";
import { Feature } from "./scenes/Feature";
import { Statement } from "./scenes/Statement";
import type { LaunchProps, Scene } from "./schema";

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const Launch = ({ brand, grid, content, media, scenes }: LaunchProps) => {
  let offset = 0;
  return (
    <AbsoluteFill style={{ background: brand.paper, fontFamily: brand.fontFamily }}>
      <style>{brandFontFace(brand)}</style>
      <Guides grid={grid} brand={brand} />
      {scenes.map((scene, index) => {
        const from = offset;
        offset += scene.durationInFrames;
        const common = { brand, grid, content };
        let body: ReactNode;
        let stage: number | undefined;
        if (scene.kind === "statement") {
          body = <Statement scene={scene} {...common} />;
        } else if (scene.kind === "feature") {
          const slot = media[scene.media];
          if (!slot) {
            throw new Error(`Scene "${scene.id}" references unknown media slot "${scene.media}"`);
          }
          stage = scene.stage;
          body = <Feature scene={scene} slot={slot} {...common} />;
        } else {
          body = (
            <Cta
              scene={scene}
              {...common}
              sceneIndex={index}
              sceneCount={scenes.length}
            />
          );
        }
        return (
          <Sequence
            key={scene.id}
            name={scene.id}
            from={from}
            durationInFrames={scene.durationInFrames}
          >
            {scene.kind === "cta" ? null : (
              <Rails
                {...common}
                sceneIndex={index}
                sceneCount={scenes.length}
                stage={stage}
              />
            )}
            {body}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
