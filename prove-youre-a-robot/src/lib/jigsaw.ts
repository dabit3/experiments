export type Tab = -1 | 1
export type Tabs = readonly [Tab, Tab, Tab, Tab]

/**
 * SVG path for a jigsaw piece whose body is an `s`×`s` square with its
 * top-left corner at the origin. Each edge (top, right, bottom, left) gets a
 * tab that bulges outward (1) or is notched inward (-1). Tabs extend about
 * 0.27·s beyond the square.
 */
export function jigsawPath(s: number, tabs: Tabs): string {
  const maps: ReadonlyArray<(u: number, v: number) => readonly [number, number]> = [
    (u, v) => [u, -v],
    (u, v) => [s + v, u],
    (u, v) => [s - u, s + v],
    (u, v) => [-v, s - u],
  ]
  const f = (n: number) => (Math.round(n * 100) / 100).toString()
  let d = 'M 0 0'
  tabs.forEach((t, i) => {
    const m = maps[i]
    const P = (u: number, v: number) => {
      const [x, y] = m(u * s, v * s)
      return `${f(x)} ${f(y)}`
    }
    d += ` L ${P(0.38, 0)}`
    d += ` C ${P(0.47, 0)} ${P(0.4, t * 0.1)} ${P(0.4, t * 0.16)}`
    d += ` C ${P(0.4, t * 0.3)} ${P(0.6, t * 0.3)} ${P(0.6, t * 0.16)}`
    d += ` C ${P(0.6, t * 0.1)} ${P(0.53, 0)} ${P(0.62, 0)}`
    d += ` L ${P(1, 0)}`
  })
  return `${d} Z`
}
