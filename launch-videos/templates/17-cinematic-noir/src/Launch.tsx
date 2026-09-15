import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { LaunchProps, Scene } from "./schema";
import { Stage } from "./components/Stage";
import { Statement } from "./scenes/Statement";
import { Title } from "./scenes/Title";
import { Product } from "./scenes/Product";
import { Outro } from "./scenes/Outro";

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, scene) => sum + scene.durationInFrames, 0);

const SceneView: React.FC<{ scene: Scene; props: LaunchProps }> = ({ scene, props }) => {
  const { brand, content, layout, lighting, media, mask } = props;
  switch (scene.type) {
    case "statement":
      return <Statement scene={scene} brand={brand} content={content} layout={layout} />;
    case "title":
      return <Title scene={scene} brand={brand} layout={layout} />;
    case "product": {
      const slot = media[scene.media];
      if (!slot) {
        throw new Error(`Scene "${scene.id}" references unknown media slot "${scene.media}"`);
      }
      return (
        <Product
          scene={scene}
          slot={slot}
          brand={brand}
          content={content}
          layout={layout}
          lighting={lighting}
          defaultMask={mask}
        />
      );
    }
    case "outro":
      return <Outro brand={brand} content={content} layout={layout} />;
    default:
      return null;
  }
};

export const Launch: React.FC<LaunchProps> = (props) => {
  let from = 0;
  return (
    <Stage brand={props.brand} lighting={props.lighting}>
      {props.scenes.map((scene) => {
        const start = from;
        from += scene.durationInFrames;
        return (
          <Sequence key={scene.id} from={start} durationInFrames={scene.durationInFrames} name={scene.id}>
            <AbsoluteFill>
              <SceneView scene={scene} props={props} />
            </AbsoluteFill>
          </Sequence>
        );
      })}
    </Stage>
  );
};
