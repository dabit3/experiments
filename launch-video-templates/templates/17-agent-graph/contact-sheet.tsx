import React from 'react';
import {AbsoluteFill, Composition, Img, registerRoot, staticFile} from 'remotion';
import {samples} from './qa-config';

const ContactSheet: React.FC = () => (
  <AbsoluteFill style={{background: '#080f16', color: '#f5faf8', fontFamily: '"Helvetica Neue", Arial, sans-serif'}}>
    <div style={{height: 94, padding: '25px 24px', boxSizing: 'border-box', fontSize: 30}}>
      17 / AGENT GRAPH
      <span style={{fontSize: 20, float: 'right', color: '#9faeb6', paddingTop: 8}}>42s · 1920×1080 · 30fps · Scene and transition QA</span>
    </div>
    <div style={{display: 'grid', gridTemplateColumns: 'repeat(4, 480px)'}}>
      {samples.map(([frame, label], index) => (
        <div key={frame} style={{height: 306}}>
          <Img src={staticFile(`17-agent-graph-qa/frame-${String(index + 1).padStart(3, '0')}.png`)} style={{display: 'block', width: 480, height: 270}} />
          <div style={{fontSize: 16, padding: '8px 12px', color: '#bdcec9'}}>{(frame / 30).toFixed(2)}s · {label}</div>
        </div>
      ))}
    </div>
  </AbsoluteFill>
);

registerRoot(() => <Composition id="ContactSheet" component={ContactSheet} width={1920} height={2236} fps={30} durationInFrames={1} />);
