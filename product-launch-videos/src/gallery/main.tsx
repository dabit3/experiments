import {useEffect, useRef, useState} from 'react';
import {createRoot} from 'react-dom/client';
import catalog from '../../.cache/gallery-catalog.json';
import './style.css';

const {templates} = catalog;
type Template = typeof templates[number];
const mediaPath = (template: Template, name: string) => `./renders/${template.slug}/${name}`;
const sourcePath = (template: Template) => `product-launch-videos/src/templates/${template.slug}/`;
const sourceUrl = (template: Template) => `https://github.com/dabit3/experiments/tree/${template.commit}/${sourcePath(template)}`;
const number = (template: Template) => String(template.number).padStart(2, '0');
const completed = templates.filter((template) => template.status === 'complete').length;

const DownloadLinks = ({template}: {template: Template}) => <div className="downloads">
  <a href={mediaPath(template, 'sample.mp4')} download={`${template.slug}.mp4`}>MP4 ↓</a>
  <a href={mediaPath(template, 'poster.png')} download={`${template.slug}-poster.png`}>Poster ↓</a>
  <a href={mediaPath(template, 'contact-sheet.png')} download={`${template.slug}-contact-sheet.png`}>Contact sheet ↓</a>
  <a href={mediaPath(template, 'default-props.json')} download={`${template.slug}-props.json`}>Editable props ↓</a>
</div>;

const Detail = ({template, index, onSelect, onClose}: {
  template: Template; index: number; onSelect: (index: number) => void; onClose: () => void;
}) => {
  const dialog = useRef<HTMLDialogElement>(null);
  const video = useRef<HTMLVideoElement>(null);
  const [mediaError, setMediaError] = useState(false);
  useEffect(() => {
    const current = dialog.current;
    current?.showModal();
    return () => current?.close();
  }, []);
  useEffect(() => {
    const current = video.current;
    return () => current?.pause();
  }, [template.slug]);
  const select = (next: number) => {
    setMediaError(false);
    onSelect(next);
  };
  return <dialog ref={dialog} onClose={onClose} aria-labelledby="detail-title">
    <div className="dialog-top">
      <p className="eyebrow">{number(template)} / {templates.length} — {template.status === 'complete' ? 'Verified render' : template.status}</p>
      <button className="button small" onClick={() => dialog.current?.close()} autoFocus>Close <span aria-hidden="true">×</span></button>
    </div>
    <div className="player">
      <video key={template.slug} ref={video} controls playsInline preload="metadata"
        poster={mediaPath(template, 'poster.png')} src={mediaPath(template, 'sample.mp4')}
        aria-label={`${template.name}: silent 40-second launch video with embedded captions`}
        onError={() => setMediaError(true)} />
      {mediaError && <p role="alert" className="media-error">This local MP4 is missing or cannot be played. Rehydrate the media using the manifest, or open the MP4 download in your video player.</p>}
    </div>
    <div className="detail-content">
      <div className="detail-heading">
        <div><h2 id="detail-title">{template.name}</h2><p>{template.description}</p></div>
        <div className="pager" aria-label="Browse directions">
          <button className="button" disabled={index === 0} onClick={() => select(index - 1)}>← Previous</button>
          <button className="button" disabled={index === templates.length - 1} onClick={() => select(index + 1)}>Next →</button>
        </div>
      </div>
      <DownloadLinks template={template} />
      <details>
        <summary>Source, controls & render instructions</summary>
        <p><a href={sourceUrl(template)} target="_blank" rel="noreferrer">Open template source ↗</a></p>
        <code className="path">{sourcePath(template)}</code>
        <p>Edit <code>config.ts</code> or download the complete props above. Run from <code>product-launch-videos/</code> after installing the original asset bundle:</p>
        <pre>{`npm ci\nnpm run assets:setup -- /path/to/shared-assets.zip\nnpm run render -- --template ${template.slug}\n# Render with your edited complete config:\nnpm run render -- --template ${template.slug} --props /path/to/props.json`}</pre>
        <p><code>{template.compositionId}</code> · 1920 × 1080 · 30 fps · 1,200 frames</p>
        <h3>Direction controls</h3>
        <ul className="controls">{template.controls.map((control) =>
          <li key={control.path}><code>{control.path}</code><span>{control.description}</span></li>)}</ul>
        <details><summary>Default configuration</summary><pre>{JSON.stringify(template.defaultConfig, null, 2)}</pre></details>
      </details>
      <details>
        <summary>Verification & provenance</summary>
        <p>{template.checks.source}</p><p>{template.checks.decode}</p>
        {template.checks.error && <p role="alert">{template.checks.error}</p>}
        <p>Producer report: {template.producerChecks}</p>
        <p>Producer branch: <code>{template.branch}</code><br />Commit: <code>{template.commit}</code></p>
        {template.limitations && <p>{template.limitations}</p>}
        <p>The native examples are stills from separate sessions. The recordings show agent selection and a labeled Web QA example, both at 1×. Small report text is best read full-screen. Revalidate copy, crop and duration edits before exporting.</p>
      </details>
      <details>
        <summary>Caption transcript & shared sample edit</summary>
        <ol className="transcript">
          <li><time>00–04</time> Devin now runs on Mac. Build, run, and test iOS apps in the cloud.</li>
          <li><time>04–09</time> Choose a hosted Mac environment.</li>
          <li><time>09–13</time> Choose your agent.</li>
          <li><time>13–22</time> See your app in the iPhone Simulator. Two separate native app stills.</li>
          <li><time>22–29</time> Review recorded test steps and results. Web QA example.</li>
          <li><time>29–35</time> Check iPhone and iPad layouts.</li>
          <li><time>35–40</time> Same pricing as Linux cloud sessions. Start a Mac session with Devin. https://app.devin.ai</li>
        </ol>
      </details>
    </div>
  </dialog>;
};

const Gallery = () => {
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState<number | null>(null);
  const opener = useRef<HTMLButtonElement | null>(null);
  const [failedPosters, setFailedPosters] = useState<string[]>([]);
  const filtered = templates.filter((template) =>
    `${number(template)} ${template.name} ${template.description}`.toLowerCase().includes(query.toLowerCase().trim()));
  return <>
    <a className="skip-link" href="#directions">Skip to directions</a>
    <main>
      <header>
        <div className="masthead"><span>Devin</span><span>ON MAC / DESIGN COLLECTION</span><a href="#usage">How to use ↗</a></div>
        <div className="hero">
          <p className="eyebrow">One launch. Twenty points of view.</p>
          <h1>The same product.<br />A different perspective.</h1>
          <p className="intro">Twenty independent, editable launch films for Devin on Mac. Compare the motion, framing and pacing using the same source material.</p>
        </div>
        <div className="facts"><span>{String(completed).padStart(2, '0')} / {templates.length} complete</span><span>40 seconds each</span><span>1920 × 1080 · 30 fps</span><span>Silent, captioned</span></div>
      </header>
      <section id="directions" aria-labelledby="collection-title">
        <div className="collection-heading"><h2 id="collection-title">Explore the directions</h2>
          <label className="search"><span>Find a direction</span><input type="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Number, name or motion…" /></label>
        </div>
        <p className="result-count" aria-live="polite">{filtered.length} of {templates.length} directions</p>
        <div className="gallery">
          {filtered.map((template) => <article key={template.slug}>
            <button className="poster" aria-label={`Watch ${number(template)}: ${template.name}`}
              onClick={(event) => {opener.current = event.currentTarget; setSelected(templates.indexOf(template));}}>
              {failedPosters.includes(template.slug) ? <span className="poster-missing">Poster unavailable — rehydrate local media</span>
                : <img src={mediaPath(template, 'poster.png')} alt={`${template.name} — frame from the final film`} loading="lazy" width="1920" height="1080"
                  onError={() => setFailedPosters((current) => [...current, template.slug])} />}
              <span className="watch">Watch direction <span aria-hidden="true">↗</span></span>
            </button>
            <div className="card-title"><span className="index">{number(template)}</span><h3>{template.name}</h3></div>
            <p className="description">{template.description}</p>
            <div className="card-meta"><span>{failedPosters.includes(template.slug) ? 'Local poster unavailable' : template.status === 'complete' ? 'Complete · verified 1080p30' : template.status}</span><a href={sourceUrl(template)} target="_blank" rel="noreferrer">Source ↗</a></div>
            <DownloadLinks template={template} />
          </article>)}
        </div>
        {filtered.length === 0 && <p className="empty">No matching direction. <button onClick={() => setQuery('')}>Clear search</button></p>}
      </section>
      <section className="usage" id="usage" aria-labelledby="usage-title">
        <div><p className="eyebrow">A reusable collection</p><h2 id="usage-title">Choose a direction.<br />Make it yours.</h2></div>
        <div><p>Open any poster for a full-size player, motion controls, editable props and render instructions. Tab through controls; Enter opens a direction; Escape closes the detail view. Downloads and media stay local to this gallery.</p>
          <p>Each template owns its composition and motion system. Copy, media, brand tokens, scene durations and crop positions are editable. Source recordings and fonts are supplied separately for rendering.</p>
          <p>These are examples from separate sessions. The native app scenes use authentic iPhone and iPad stills; the Web QA recording is labeled throughout.</p>
          <p><a href="./gallery-manifest.json" download>Rehydration & verification manifest ↓</a><br /><a href="./comparison.png" download>All 20 directions — comparison sheet ↓</a></p>
        </div>
      </section>
      <footer><span>Devin on Mac</span><span>Independent directions / shared material</span><a href="https://app.devin.ai" target="_blank" rel="noreferrer">Start a Mac session ↗</a></footer>
    </main>
    {selected !== null && <Detail template={templates[selected]} index={selected} onSelect={setSelected}
      onClose={() => {setSelected(null); opener.current?.focus();}} />}
  </>;
};

const FontReadyGallery = () => {
  const [font, setFont] = useState<'loading' | 'ready' | 'error'>('loading');
  useEffect(() => {
    document.fonts.load('16px nbInternationalPro')
      .then((faces) => setFont(faces.length ? 'ready' : 'error'))
      .catch(() => setFont('error'));
  }, []);
  if (font === 'loading') return <main><p role="status">Loading the original brand font…</p></main>;
  if (font === 'error') return <main><h1>Brand font unavailable.</h1><p role="alert">Install the supplied asset bundle and restart the gallery. If viewing the portable ZIP, use the local HTTP server command in its README, then reload.</p></main>;
  return <Gallery />;
};

createRoot(document.getElementById('root')!).render(<FontReadyGallery />);
