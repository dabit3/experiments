import assert from 'node:assert/strict'
import { test } from 'node:test'
import { hexToHsv, hsvToHex } from './color.ts'
import { constrainPoint } from './shapes.ts'
import { floodFill } from './floodFill.ts'

test('color editing preserves arbitrary RGB values, neutrals and hue wraparound', () => {
  for (let r = 0; r <= 255; r += 17) {
    for (let g = 0; g <= 255; g += 17) {
      for (let b = 0; b <= 255; b += 17) {
        const hex = `#${[r, g, b].map((c) => c.toString(16).padStart(2, '0')).join('')}`
        const { h, s, v } = hexToHsv(hex)
        assert.equal(hsvToHex(h, s, v), hex)
      }
    }
  }
  assert.equal(hsvToHex(360, 1, 1), '#ff0000')
})

test('Shift constrains reverse-drag rectangles without flipping their direction', () => {
  const from = { x: 250, y: 250 }
  for (const tool of ['rect', 'circle']) {
    assert.deepEqual(constrainPoint(from, { x: 210, y: 150 }, tool), {
      x: 150,
      y: 150,
    })
    assert.deepEqual(constrainPoint(from, { x: 280, y: 150 }, tool), {
      x: 350,
      y: 150,
    })
  }
  const snapped = constrainPoint(from, { x: 350, y: 253 }, 'line')
  assert.equal(snapped.y, from.y)
  assert.ok(
    Math.abs(
      Math.hypot(snapped.x - 250, snapped.y - 250) - Math.hypot(100, 3),
    ) < 0.001,
  )
})

function canvasForRows(rows) {
  const width = rows[0].length
  const height = rows.length
  const image = {
    data: new Uint8ClampedArray(width * height * 4),
    width,
    height,
  }
  rows.forEach((row, y) =>
    Array.from(row).forEach((cell, x) => {
      const value = cell === '#' ? 0 : 255
      image.data.set([value, value, value, 255], (y * width + x) * 4)
    }),
  )
  return {
    canvas: { width, height },
    getImageData: () => image,
    putImageData: (result) => {
      image.data.set(result.data)
    },
    pixel: (x, y) =>
      Array.from(
        image.data.slice((y * width + x) * 4, (y * width + x) * 4 + 4),
      ),
  }
}

test('scanline fill reaches connected branches while preserving outlines and disconnected regions', () => {
  const rows = [
    '#########',
    '#...#...#',
    '#.#.#.#.#',
    '#.#...#.#',
    '#.#####.#',
    '#.......#',
    '#########',
  ]
  const ctx = canvasForRows(rows)
  floodFill(ctx, { x: 1, y: 1 }, '#ffa940')
  rows.forEach((row, y) =>
    Array.from(row).forEach((cell, x) => {
      assert.deepEqual(
        ctx.pixel(x, y),
        cell === '#' ? [0, 0, 0, 255] : [255, 169, 64, 255],
      )
    }),
  )
  const isolated = canvasForRows(['#######', '#..#..#', '#######'])
  floodFill(isolated, { x: 1, y: 1 }, '#ffa940')
  assert.deepEqual(isolated.pixel(4, 1), [255, 255, 255, 255])
  assert.deepEqual(isolated.pixel(1, 1), [255, 169, 64, 255])
})

test('fill terminates for a close replacement color and ignores out-of-canvas points', () => {
  const ctx = canvasForRows(['...', '...', '...'])
  floodFill(ctx, { x: -1, y: 0 }, '#000000')
  assert.deepEqual(ctx.pixel(0, 0), [255, 255, 255, 255])
  floodFill(ctx, { x: 1, y: 1 }, '#eeeeee')
  for (let y = 0; y < 3; y++)
    for (let x = 0; x < 3; x++)
      assert.deepEqual(ctx.pixel(x, y), [238, 238, 238, 255])
})
