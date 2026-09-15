import type { Point } from '../types'

const TOLERANCE = 48

function hexToRgba(hex: string): [number, number, number, number] {
  const n = parseInt(hex.slice(1), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255, 255]
}

function matches(
  data: Uint8ClampedArray,
  i: number,
  target: Uint8ClampedArray,
): boolean {
  return (
    Math.abs(data[i] - target[0]) <= TOLERANCE &&
    Math.abs(data[i + 1] - target[1]) <= TOLERANCE &&
    Math.abs(data[i + 2] - target[2]) <= TOLERANCE &&
    Math.abs(data[i + 3] - target[3]) <= TOLERANCE
  )
}

/**
 * Scanline flood fill starting at `start`, replacing every connected pixel that is
 * within TOLERANCE of the start pixel's color. Operates directly on the context.
 */
export function floodFill(
  ctx: CanvasRenderingContext2D,
  start: Point,
  fillHex: string,
): void {
  const { width, height } = ctx.canvas
  const sx = Math.floor(start.x)
  const sy = Math.floor(start.y)
  if (sx < 0 || sy < 0 || sx >= width || sy >= height) return

  const image = ctx.getImageData(0, 0, width, height)
  const data = image.data
  const startIdx = (sy * width + sx) * 4
  const target = data.slice(startIdx, startIdx + 4)
  const fill = hexToRgba(fillHex)

  if (
    target[0] === fill[0] &&
    target[1] === fill[1] &&
    target[2] === fill[2] &&
    target[3] === fill[3]
  ) {
    return
  }

  const visited = new Uint8Array(width * height)
  const stack: number[] = [sx, sy]

  while (stack.length > 0) {
    const y = stack.pop() as number
    let x = stack.pop() as number

    const rowStart = y * width
    while (
      x >= 0 &&
      !visited[rowStart + x] &&
      matches(data, (rowStart + x) * 4, target)
    )
      x--
    x++

    let spanAbove = false
    let spanBelow = false
    while (
      x < width &&
      !visited[rowStart + x] &&
      matches(data, (rowStart + x) * 4, target)
    ) {
      const p = rowStart + x
      visited[p] = 1
      data[p * 4] = fill[0]
      data[p * 4 + 1] = fill[1]
      data[p * 4 + 2] = fill[2]
      data[p * 4 + 3] = fill[3]

      if (y > 0) {
        const up = p - width
        const canUp = !visited[up] && matches(data, up * 4, target)
        if (canUp && !spanAbove) {
          stack.push(x, y - 1)
          spanAbove = true
        } else if (!canUp) {
          spanAbove = false
        }
      }
      if (y < height - 1) {
        const down = p + width
        const canDown = !visited[down] && matches(data, down * 4, target)
        if (canDown && !spanBelow) {
          stack.push(x, y + 1)
          spanBelow = true
        } else if (!canDown) {
          spanBelow = false
        }
      }
      x++
    }
  }

  ctx.putImageData(image, 0, 0)
}
