import React, {type CSSProperties, type ReactNode} from 'react';
import {
  AbsoluteFill,
  Composition,
  Easing,
  Img,
  OffthreadVideo,
  Sequence,
  interpolate,
  registerRoot,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {design, interactionStages, media, scenes, type Scene} from './config';
import manifest from './template.json';

const FPS = manifest.fps;
const mono: CSSProperties = {
  fontFamily: design.mono,
  fontSize: 22,
  lineHeight: 1.3,
  letterSpacing: -0.5,
};

const Label: React.FC<{children: ReactNode; style?: CSSProperties}> = ({children, style}) => (
  <div style={{...mono, ...style}}>{children}</div>
);

const Reveal: React.FC<{children: ReactNode}> = ({children}) => {
  const frame = useCurrentFrame();
  const y = interpolate(frame, [0, design.entranceFrames], [28, 0], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return <AbsoluteFill style={{transform: `translateY(${y}px)`}}>{children}</AbsoluteFill>;
};

const Headline: React.FC<{
  scene: Scene;
  top?: number;
  width?: number;
  activeLine?: number;
}> = ({scene, top = 217, width = 1150, activeLine = scene.underline}) => (
  <div
    style={{
      position: 'absolute',
      left: design.inset,
      top,
      width,
      fontWeight: 900,
      fontSize: scene.size,
      lineHeight: 0.93,
      letterSpacing: -scene.size * 0.056,
    }}
  >
    {scene.title.map((line, index) => (
      <div
        key={line}
        style={{whiteSpace: 'nowrap', marginBottom: index === activeLine ? 34 : 8}}
      >
        <span
          style={{
            borderBottom: index === activeLine ? `15px solid ${design.accent}` : undefined,
            paddingBottom: index === activeLine ? 1 : 0,
          }}
        >
          {line}
        </span>
      </div>
    ))}
  </div>
);

const Crop: React.FC<{
  asset: string;
  sourceWidth: number;
  crop: {x: number; y: number; width: number; height: number};
  width: number;
}> = ({asset, sourceWidth, crop, width}) => {
  const scale = width / crop.width;
  return (
    <div style={{width, height: crop.height * scale, position: 'relative', overflow: 'hidden'}}>
      <Img
        src={staticFile(`assets/${asset}`)}
        style={{
          position: 'absolute',
          width: sourceWidth * scale,
          maxWidth: 'none',
          height: 'auto',
          left: -crop.x * scale,
          top: -crop.y * scale,
        }}
      />
    </div>
  );
};

const PhonePanel: React.FC<{
  asset?: string;
  sourceWidth?: number;
  action?: string;
}> = ({asset = 'devin-web-18.png', sourceWidth = 2978, action}) => (
  <div style={{position: 'absolute', left: 1308, top: 160, width: 480}}>
    <div style={{border: `10px solid ${design.ink}`, background: design.ink}}>
      <Crop asset={asset} sourceWidth={sourceWidth} crop={media.phoneCrop} width={460} />
      <Label
        style={{
          background: design.ink,
          color: design.paper,
          paddingTop: 18,
          paddingBottom: 10,
          fontSize: 20,
          display: 'flex',
          justifyContent: 'space-between',
        }}
      >
        <span>{media.phoneLabel}</span>
        <span>{action ?? '→'}</span>
      </Label>
    </div>
    <Label style={{fontSize: 18, marginTop: 12}}>{media.stagedLabel}</Label>
  </div>
);

const Support: React.FC<{text: string; top?: number; width?: number}> = ({
  text,
  top = 850,
  width = 1130,
}) => (
  <div
    style={{
      position: 'absolute',
      left: design.inset,
      top,
      width,
      fontSize: 38,
      fontWeight: 500,
      letterSpacing: -1.2,
      lineHeight: 1.15,
    }}
  >
    {text}
  </div>
);

const Context: React.FC<{scene: Scene}> = ({scene}) => (
  <>
    <Headline scene={scene} top={199} width={1750} />
    <div
      style={{
        position: 'absolute',
        top: 600,
        left: design.inset,
        right: design.inset,
        height: 260,
        display: 'flex',
        alignItems: 'center',
        borderTop: `7px solid ${design.ink}`,
        borderBottom: `7px solid ${design.ink}`,
      }}
    >
      <div style={{fontSize: 214, fontWeight: 900, letterSpacing: -16, lineHeight: 1}}>20+</div>
      <div style={{fontSize: 66, fontWeight: 800, letterSpacing: -2, marginLeft: 48}}>MIN</div>
      <div style={{fontSize: 44, lineHeight: 1.12, letterSpacing: -1, marginLeft: 'auto', width: 620}}>
        {scene.supporting}
      </div>
    </div>
  </>
);

const Build: React.FC<{scene: Scene}> = ({scene}) => (
  <>
    <Headline scene={scene} top={224} />
    <div
      style={{
        position: 'absolute',
        left: design.inset,
        top: 650,
        width: 1044,
        borderTop: `6px solid ${design.ink}`,
        paddingTop: 26,
        display: 'flex',
        justifyContent: 'space-between',
      }}
    >
      {['SOURCE', 'XCODE', 'SIMULATOR'].map((step, index) => (
        <Label key={step} style={{fontSize: 25}}>
          {step}{index < 2 ? '  →' : ''}
        </Label>
      ))}
    </div>
    <Support text={scene.supporting} top={813} />
    <PhonePanel asset="devin-web-14.png" sourceWidth={2986} />
  </>
);

const Interact: React.FC<{scene: Scene}> = ({scene}) => {
  const frame = useCurrentFrame();
  const stageIndex = interactionStages.reduce(
    (active, stage, index) => frame >= stage.second * FPS ? index : active,
    0,
  );
  const stage = interactionStages[stageIndex];
  return (
    <>
      <Headline scene={scene} top={203} activeLine={stageIndex} />
      <Support text={scene.supporting} top={852} />
      <PhonePanel asset={stage.asset} sourceWidth={stage.sourceWidth} action={stage.action} />
    </>
  );
};

const Fix: React.FC<{scene: Scene}> = ({scene}) => (
  <>
    <Headline scene={scene} top={240} width={1010} />
    <Support text={scene.supporting} top={760} width={920} />
    <div
      style={{
        position: 'absolute',
        left: 1160,
        top: 204,
        width: 670,
        border: `10px solid ${design.ink}`,
        background: brand.white,
      }}
    >
      <Label
        style={{
          padding: '22px 26px',
          background: design.ink,
          color: design.paper,
          fontSize: 21,
        }}
      >
        SOURCE CHECKS / WISP SIMULATOR
      </Label>
      <Crop
        asset="devin-web-10.png"
        sourceWidth={2990}
        crop={{x: 1949, y: 149, width: 1011, height: 850}}
        width={650}
      />
    </div>
    <Label style={{position: 'absolute', left: 1160, top: 868, fontSize: 18}}>
      Original mixed results retained.
    </Label>
  </>
);

const Review: React.FC<{scene: Scene}> = ({scene}) => (
  <>
    <Headline scene={scene} top={262} width={730} />
    <Support text={scene.supporting} top={779} width={670} />
    <div style={{position: 'absolute', left: 819, top: 235, width: 990}}>
      <Label
        style={{
          padding: '21px 20px',
          color: design.paper,
          background: design.ink,
          fontSize: 21,
        }}
      >
        {media.videoLabel}
      </Label>
      <div style={{border: `10px solid ${design.ink}`, borderTop: 0, background: brand.white}}>
        <OffthreadVideo
          src={staticFile(media.video)}
          trimBefore={media.videoInSeconds * FPS}
          muted
          style={{display: 'block', width: 970, height: (970 * 1080) / 1918, objectFit: 'contain'}}
        />
      </div>
      <Label style={{marginTop: 20, fontSize: 20}}>
        Recorded actions. Visible review.
      </Label>
    </div>
  </>
);

const End: React.FC<{scene: Scene}> = ({scene}) => (
  <>
    <Img
      src={staticFile(sources.logoBlack)}
      style={{
        position: 'absolute',
        left: 395,
        top: 171,
        width: 1130,
        height: 'auto',
        mixBlendMode: 'multiply',
      }}
    />
    <div style={{position: 'absolute', top: 614, width: '100%', textAlign: 'center'}}>
      <div style={{fontSize: 42, fontWeight: 600, letterSpacing: -1}}>{scene.supporting}</div>
      <div style={{fontSize: scene.size, fontWeight: 900, letterSpacing: -5, marginTop: 34}}>
        <span style={{borderBottom: `15px solid ${design.accent}`, paddingBottom: 6}}>
          {scene.title[0]}
        </span>
      </div>
    </div>
  </>
);

const SceneBody: React.FC<{scene: Scene}> = ({scene}) => {
  switch (scene.id) {
    case 'context':
      return <Context scene={scene} />;
    case 'build':
      return <Build scene={scene} />;
    case 'interact':
      return <Interact scene={scene} />;
    case 'fix':
      return <Fix scene={scene} />;
    case 'review':
      return <Review scene={scene} />;
    case 'end':
      return <End scene={scene} />;
    default:
      return (
        <>
          <Headline scene={scene} top={scene.id === 'outcome' ? 238 : 198} />
          <Support text={scene.supporting} top={scene.id === 'outcome' ? 803 : 835} />
          <PhonePanel />
        </>
      );
  }
};

const Ticker: React.FC = () => {
  const frame = useCurrentFrame();
  const groupWidth = 2600;
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 0,
        height: design.tickerHeight,
        width: '100%',
        overflow: 'hidden',
        background: design.ink,
        color: design.paper,
      }}
    >
      <div
        style={{
          display: 'flex',
          width: groupWidth * 3,
          height: '100%',
          transform: `translateX(-${(frame * design.tickerPixelsPerFrame) % groupWidth}px)`,
        }}
      >
        {[0, 1, 2].map((repeat) => (
          <div
            key={repeat}
            style={{
              width: groupWidth,
              flexShrink: 0,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-around',
              fontSize: 31,
              fontWeight: 800,
              letterSpacing: -0.5,
              whiteSpace: 'nowrap',
            }}
          >
            {media.ticker.map((text) => (
              <React.Fragment key={text}>
                <span>{text}</span>
                <span>●</span>
              </React.Fragment>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
};

const Launch: React.FC = () => {
  let from = 0;
  return (
    <AbsoluteFill style={{background: design.paper, color: design.ink, fontFamily: design.font}}>
      {scenes.map((scene, index) => {
        const start = from;
        const duration = scene.seconds * FPS;
        from += duration;
        return (
          <Sequence key={scene.id} from={start} durationInFrames={duration}>
            <AbsoluteFill style={{overflow: 'hidden', height: manifest.height - design.tickerHeight}}>
              <div
                style={{
                  position: 'absolute',
                  left: design.inset,
                  right: design.inset,
                  top: 63,
                  paddingBottom: 27,
                  borderBottom: `4px solid ${design.ink}`,
                  display: 'flex',
                  justifyContent: 'space-between',
                }}
              >
                <Label style={{fontWeight: 700}}>{scene.eyebrow}</Label>
                <Label>{String(index + 1).padStart(2, '0')} / 08</Label>
              </div>
              {scene.id === 'review' ? <SceneBody scene={scene} /> : (
                <Reveal><SceneBody scene={scene} /></Reveal>
              )}
              <Label
                style={{position: 'absolute', left: design.inset, bottom: 41, fontSize: 18}}
              >
                {scene.footer}
              </Label>
            </AbsoluteFill>
          </Sequence>
        );
      })}
      <Ticker />
    </AbsoluteFill>
  );
};

const Root: React.FC = () => (
  <Composition
    id={manifest.compositionId}
    component={Launch}
    durationInFrames={scenes.reduce((sum, scene) => sum + scene.seconds * FPS, 0)}
    fps={FPS}
    width={manifest.width}
    height={manifest.height}
  />
);

registerRoot(Root);
