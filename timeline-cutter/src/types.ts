export type Pattern = 'sunrise' | 'ocean' | 'grid' | 'bokeh' | 'bars' | 'noise'

export interface MediaItem {
  id: string
  name: string
  duration: number
  pattern: Pattern
  primary: string
  secondary: string
}

export interface VideoClip {
  id: string
  mediaId: string
  /** source in-point (seconds) */
  in: number
  /** source out-point (seconds, exclusive) */
  out: number
}

export interface TitleClip {
  id: string
  text: string
  start: number
  duration: number
}

export interface Project {
  video: VideoClip[]
  titles: TitleClip[]
}

export type Tool = 'select' | 'razor'

export type Selection =
  | { kind: 'video'; id: string }
  | { kind: 'title'; id: string }
  | null

export const FPS = 30
export const MIN_CLIP_DURATION = 0.25
