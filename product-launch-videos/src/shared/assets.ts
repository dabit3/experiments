import {staticFile} from 'remotion';
import manifest from './asset-manifest.json';

export type AssetId = keyof typeof manifest;
type KeysOfKind<K extends string> = {
  [Key in AssetId]: (typeof manifest)[Key] extends {width: number}
    ? K extends 'video'
      ? (typeof manifest)[Key] extends {fps: number} ? Key : never
      : (typeof manifest)[Key] extends {fps: number} ? never : Key
    : never;
}[AssetId];
export type ImageAssetId = KeysOfKind<'image'>;
export type VideoAssetId = KeysOfKind<'video'>;
export type MediaAssetId = ImageAssetId | VideoAssetId;

export const assets = manifest;
export const assetPath = (id: AssetId): string => staticFile(`assets/${id}`);

export const logos = {
  black: 'BLACK_NO_BG_DEVIN_LOCKUP_HORIZONTAL_WHITE.png',
  white: 'DEVIN_LOCKUP_HORIZONTAL_WHITE_TRANSPARENT.png',
  avatarBlack: 'DEVIN_AVATAR_SQUARE_BLACK_NO_BG.png',
  avatarWhite: 'DEVIN_AVATAR_SQUARE_WHITE_NO_BG.png',
} as const satisfies Record<string, ImageAssetId>;

export const mediaNotes: Partial<Record<MediaAssetId, string>> = {
  'agent-selector-cloud.mp4': 'Agent mode/capability menu, not macOS selection.',
  'devin-testing-2.mp4': 'Web QA example. Separate web-app testing session, not iOS.',
  'devin-web-4.png': 'Hosted environment menu with macOS selected.',
  'devin-web-14.png': 'Afterhours Maze iPhone still. Preserve 8 passed, 0 failed, 1 untested.',
  'devin-web-18.png': 'Large Dispatch iPhone still and final-review report.',
  'devin-web-19.png': 'Terra Table iPad still and acceptance report.',
  'devin-web-9.png': 'Wisp context only: 12 passed, 3 failed, 2 untested.',
  'devin-web-10.png': 'Wisp report contains failures. Never hide the report counts.',
  'devin-web-11.png': 'Wisp report contains failures. Never hide the report counts.',
};
