import {loadFont as loadInter} from '@remotion/google-fonts/Inter';
import {loadFont as loadGeistMono} from '@remotion/google-fonts/GeistMono';

// Inter is the deterministic fallback for NB International Pro; Geist Mono for mono.
export const loadFonts = () => {
  loadInter('normal', {weights: ['400', '500'], subsets: ['latin']});
  loadGeistMono('normal', {weights: ['400', '500'], subsets: ['latin']});
};
