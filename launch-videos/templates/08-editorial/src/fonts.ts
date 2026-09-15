import {loadFont as loadFraunces} from '@remotion/google-fonts/Fraunces';
import {loadFont as loadInter} from '@remotion/google-fonts/Inter';
import {loadFont as loadGeistMono} from '@remotion/google-fonts/GeistMono';

// Loaded once at module level; each call registers a delayRender handle so
// the renderer waits until the faces are available before painting frames.
const fraunces = loadFraunces('normal', {weights: ['400', '500'], subsets: ['latin']});
loadFraunces('italic', {weights: ['400'], subsets: ['latin']});
const inter = loadInter('normal', {weights: ['400', '500'], subsets: ['latin']});
const geistMono = loadGeistMono('normal', {weights: ['400', '500'], subsets: ['latin']});

export const serif = `${fraunces.fontFamily}, Georgia, 'Times New Roman', serif`;
export const sans = `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`;
export const mono = `${geistMono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`;
