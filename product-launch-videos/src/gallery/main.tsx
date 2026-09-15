import {Player} from '@remotion/player';
import {createRoot} from 'react-dom/client';
import type {GalleryDescriptor} from '../shared/contract';
import {template as smoke} from '../smoke';
import './style.css';

const modules = import.meta.glob<{template: GalleryDescriptor}>('../templates/*/index.ts', {eager: true});
const templates = Object.values(modules).map((module) => module.template)
  .sort((a, b) => a.slug.localeCompare(b.slug));
const previews = templates.length ? templates : [smoke];

const Gallery = () => <main>
  <header>
    <p>DEVIN ON MAC / TEMPLATE COMPARISON</p>
    <h1>Launch directions</h1>
    <p>{templates.length
      ? `${templates.length} independent templates. Each preview uses its editable default configuration.`
      : 'No producer templates collected yet. Foundation smoke preview only.'}</p>
  </header>
  <div className="gallery">
    {previews.map((template) => <article key={template.slug}>
      <Player
        component={template.Preview}
        durationInFrames={template.metadata.durationInFrames}
        compositionWidth={template.metadata.width}
        compositionHeight={template.metadata.height}
        fps={template.metadata.fps}
        controls
        clickToPlay
        style={{width: '100%', aspectRatio: '16 / 9'}}
      />
      <h2>{template.name}</h2>
      <p>{template.description}</p>
      <p>{template.metadata.durationInFrames / template.metadata.fps}s · 1920 × 1080 · 30 fps</p>
      <details>
        <summary>Configuration and motion controls</summary>
        <ul>{template.controls.map((control) =>
          <li key={control.path}><code>{control.path}</code>: {control.description}</li>,
        )}</ul>
        <pre>{JSON.stringify(template.defaultConfig, null, 2)}</pre>
      </details>
    </article>)}
  </div>
</main>;

createRoot(document.getElementById('root')!).render(<Gallery />);
