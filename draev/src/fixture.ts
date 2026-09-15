import type { Drawing, Entity, Layer } from './model'

export const LAYERS: Layer[] = [
  { id: 'walls', name: 'A-WALL', color: '#d6dedf', visible: true, locked: false, weight: 1.55 },
  { id: 'glazing', name: 'A-GLAZ', color: '#78b9c7', visible: true, locked: false, weight: 0.85 },
  { id: 'doors', name: 'A-DOOR', color: '#c8b88a', visible: true, locked: false, weight: 0.75 },
  { id: 'furniture', name: 'A-FURN', color: '#a4b0b9', visible: true, locked: false, weight: 0.65 },
  { id: 'landscape', name: 'L-PLANT', color: '#859b72', visible: true, locked: false, weight: 0.7 },
  { id: 'water', name: 'L-WATER', color: '#579ab3', visible: true, locked: false, weight: 0.65 },
  { id: 'hatch', name: 'A-HATCH', color: '#667278', visible: true, locked: false, weight: 0.45 },
  { id: 'dimensions', name: 'A-DIMS', color: '#9da986', visible: true, locked: false, weight: 0.55 },
  { id: 'text', name: 'A-ANNO', color: '#c3cace', visible: true, locked: false, weight: 0.65 },
  { id: 'site', name: 'C-SITE', color: '#827b68', visible: true, locked: false, weight: 0.55 },
  { id: 'draft', name: 'A-SKETCH', color: '#66c8f0', visible: true, locked: false, weight: 1.5 },
]

export function createResidence(): Drawing {
  const entities: Entity[] = []
  let index = 0
  const base = (layer: string) => ({ id: `res-${++index}`, layer })
  const line = (x1: number, y1: number, x2: number, y2: number, layer = 'walls') => entities.push({ ...base(layer), type: 'line', x1, y1: 22000 - y1, x2, y2: 22000 - y2 })
  const rect = (x: number, y: number, width: number, height: number, layer = 'walls', hatch = false) => entities.push({ ...base(layer), type: 'rect', x, y: 22000 - y - height, width, height, ...(hatch ? { hatch } : {}) })
  const circle = (cx: number, cy: number, radius: number, layer = 'furniture') => entities.push({ ...base(layer), type: 'circle', cx, cy: 22000 - cy, radius })
  const arc = (cx: number, cy: number, radius: number, start: number, end: number, layer = 'doors') => entities.push({ ...base(layer), type: 'arc', cx, cy: 22000 - cy, radius, start, end })
  const text = (x: number, y: number, value: string, size = 190, layer = 'text', angle = 0) => entities.push({ ...base(layer), type: 'text', x, y: 22000 - y, text: value, size, angle })
  const poly = (points: [number, number][], layer = 'furniture', closed = true) => entities.push({ ...base(layer), type: 'polyline', points: points.map(([x, y]) => ({ x, y: 22000 - y })), closed })
  const wall = (x: number, y: number, w: number, h: number) => rect(x, y, w, h, 'walls', true)
  const windowH = (x: number, y: number, length: number) => {
    rect(x, y, length, 200, 'glazing')
    line(x, y + 70, x + length, y + 70, 'glazing'); line(x, y + 130, x + length, y + 130, 'glazing')
    for (let i = 0; i <= length; i += 1000) line(x + i, y, x + i, y + 200, 'glazing')
  }
  const windowV = (x: number, y: number, length: number) => {
    rect(x, y, 200, length, 'glazing')
    line(x + 70, y, x + 70, y + length, 'glazing'); line(x + 130, y, x + 130, y + length, 'glazing')
    for (let i = 0; i <= length; i += 1000) line(x, y + i, x + 200, y + i, 'glazing')
  }
  const door = (x: number, y: number, radius = 900, flip = false) => {
    line(x, y, x, y + radius, 'doors')
    arc(x, y, radius, flip ? 180 : 270, flip ? 270 : 360)
    if (flip) line(x - radius, y, x, y, 'doors')
    else line(x, y, x + radius, y, 'doors')
  }
  const label = (x: number, y: number, name: string, area: string) => { text(x, y, name, 195); text(x, y + 300, area, 130, 'dimensions') }
  const tree = (x: number, y: number, r: number) => {
    const points: [number, number][] = []
    for (let i = 0; i < 64; i++) {
      const a = i / 64 * Math.PI * 2, radius = r * (0.88 + 0.09 * Math.sin(i * 2.8) + 0.03 * Math.cos(i * 1.1))
      points.push([x + Math.cos(a) * radius, y + Math.sin(a) * radius])
    }
    poly(points, 'landscape')
    circle(x, y, r * .67, 'landscape'); circle(x, y, 75, 'landscape')
    for (let i = 0; i < 7; i++) {
      const a = i / 7 * Math.PI * 2
      line(x + Math.cos(a) * 90, y + Math.sin(a) * 90, x + Math.cos(a + .24) * r * .68, y + Math.sin(a + .24) * r * .68, 'landscape')
    }
  }
  const shrub = (x: number, y: number) => {
    circle(x, y, 165, 'landscape')
    line(x - 100, y, x + 100, y, 'landscape'); line(x, y - 100, x, y + 100, 'landscape')
  }
  const bed = (x: number, y: number, width = 1900) => {
    rect(x - 70, y - 90, width + 140, 2200, 'furniture')
    rect(x, y, width, 2050, 'furniture')
    rect(x + 100, y + 100, width / 2 - 150, 400, 'furniture'); rect(x + width / 2 + 50, y + 100, width / 2 - 150, 400, 'furniture')
    line(x, y + 650, x + width, y + 650, 'furniture'); line(x, y + 760, x + width, y + 760, 'furniture')
    rect(x - 630, y, 450, 450, 'furniture'); circle(x - 405, y + 225, 90)
    rect(x + width + 180, y, 450, 450, 'furniture'); circle(x + width + 405, y + 225, 90)
  }
  const chair = (x: number, y: number, w = 500, h = 500) => { rect(x, y, w, h, 'furniture'); line(x, y + 95, x + w, y + 95, 'furniture') }
  const sofa = (x: number, y: number, w: number, h: number) => {
    rect(x, y, w, h, 'furniture'); rect(x + 100, y + 100, w - 200, h - 200, 'furniture')
    if (w > h) { for (let i = 1; i < 3; i++) line(x + w * i / 3, y + 150, x + w * i / 3, y + h - 100, 'furniture'); line(x + 120, y + 230, x + w - 120, y + 230, 'furniture') }
    else { for (let i = 1; i < 3; i++) line(x + 150, y + h * i / 3, x + w - 100, y + h * i / 3, 'furniture'); line(x + 230, y + 120, x + 230, y + h - 120, 'furniture') }
  }
  const sink = (x: number, y: number) => { rect(x, y, 650, 460, 'furniture'); rect(x + 65, y + 60, 520, 340, 'furniture'); circle(x + 325, y + 200, 30) }
  const bath = (x: number, y: number) => { rect(x, y, 1550, 750, 'furniture'); rect(x + 100, y + 80, 1350, 590, 'furniture'); circle(x + 1270, y + 370, 40) }
  const toilet = (x: number, y: number) => { rect(x, y, 440, 150, 'furniture'); circle(x + 220, y + 390, 230); circle(x + 220, y + 390, 150) }
  const dimH = (xs: number[], y: number, fromY: number) => {
    line(xs[0], y, xs.at(-1)!, y, 'dimensions')
    for (const x of xs) { line(x, fromY, x, y - 140, 'dimensions'); line(x - 80, y + 80, x + 80, y - 80, 'dimensions') }
    for (let i = 0; i < xs.length - 1; i++) text((xs[i] + xs[i + 1]) / 2, y - 130, (xs[i + 1] - xs[i]).toLocaleString('en-US'), 160, 'dimensions')
  }
  const dimV = (ys: number[], x: number, fromX: number) => {
    line(x, ys[0], x, ys.at(-1)!, 'dimensions')
    for (const y of ys) { line(fromX, y, x + 140, y, 'dimensions'); line(x - 80, y + 80, x + 80, y - 80, 'dimensions') }
    for (let i = 0; i < ys.length - 1; i++) text(x - 130, (ys[i] + ys[i + 1]) / 2, (ys[i + 1] - ys[i]).toLocaleString('en-US'), 160, 'dimensions', 90)
  }

  // Site and paving are drawn before the architecture.
  rect(1500, 2300, 26900, 16200, 'site')
  rect(1100, 1900, 27700, 17000, 'site')
  for (let y = 18000; y < 20400; y += 400) line(4500, y, 24700, y, 'hatch')
  for (let x = 4500; x < 24800; x += 1200) line(x, 18000, x, 20000, 'hatch')
  rect(11200, 7000, 7700, 7300, 'site')
  for (let y = 7000; y <= 14100; y += 300) line(11200, y, 18900, y, 'hatch')
  rect(12600, 8500, 4800, 3900, 'water')
  rect(12750, 8650, 4500, 3600, 'water')
  for (let y = 8830; y < 12200; y += 310) line(12750, y, 17250, y, 'water')
  for (let i = 0; i < 4; i++) line(12750 + i * 230, 8650, 12750 + i * 230, 9800, 'water')
  text(15000, 10500, 'REFLECTING POOL', 170, 'water'); text(15000, 10800, '4.80 × 3.90', 140, 'water')
  rect(17100, 12600, 1550, 1450, 'landscape')
  tree(17880, 13300, 610)
  for (const [x, y] of [[2300, 1400], [4800, 1300], [8100, 1200], [21900, 1250], [26500, 1300], [650, 5200], [650, 13000], [29400, 5400], [29400, 10500], [29300, 16100], [2900, 19800], [26700, 19800]]) tree(x, y, 760)
  for (let x = 5700; x < 24600; x += 580) shrub(x, 20750)
  for (let y = 3700; y < 17400; y += 600) { shrub(1650, y); shrub(28100, y) }

  // Exterior wall segments leave genuine openings for glazing.
  wall(2500, 3000, 1100, 250); windowH(3600, 3025, 3600); wall(7200, 3000, 1700, 250); windowH(8900, 3025, 2000)
  wall(10900, 3000, 1600, 250); windowH(12500, 3025, 4000); wall(16500, 3000, 3600, 250); windowH(20100, 3025, 4200); wall(24300, 3000, 3200, 250)
  wall(2500, 3000, 250, 1800); windowV(2525, 4800, 3900); wall(2500, 8700, 250, 5700); windowV(2525, 14400, 2300); wall(2500, 16700, 250, 1300)
  wall(27250, 3000, 250, 1700); windowV(27275, 4700, 2900); wall(27250, 7600, 250, 1900); windowV(27275, 9500, 2200); wall(27250, 11700, 250, 2300); windowV(27275, 14000, 2200); wall(27250, 16200, 250, 1800)
  wall(2500, 17750, 1100, 250); windowH(3600, 17775, 3300); wall(6900, 17750, 2000, 250); windowH(8900, 17775, 6000); wall(14900, 17750, 500, 250)
  windowH(15400, 17775, 3800); wall(19200, 17750, 1200, 250); windowH(20400, 17775, 3700); wall(24100, 17750, 3400, 250)

  // Courtyard enclosure and room partitions.
  wall(11000, 3250, 200, 800); wall(11000, 5150, 200, 1850); door(11000, 4050, 1100, true)
  wall(11200, 6800, 800, 200); windowH(12000, 6800, 5700); wall(17700, 6800, 1200, 200)
  wall(11000, 7000, 200, 800); windowV(11000, 7800, 4300); wall(11000, 12100, 200, 1900)
  wall(11000, 14000, 900, 200); windowH(11900, 14000, 6100); wall(18000, 14000, 1100, 200)
  wall(18900, 3250, 200, 2400); wall(18900, 6500, 200, 1300); door(18900, 5650, 850, true)
  windowV(18900, 7800, 4700); wall(18900, 12500, 200, 5250)
  wall(2750, 10900, 3000, 180); wall(6650, 10900, 4350, 180); door(5750, 10900)
  wall(7700, 11080, 180, 2900); wall(7700, 14900, 180, 2850); door(7700, 14000)
  wall(19100, 8300, 1200, 180); wall(21200, 8300, 6050, 180); door(20300, 8300)
  wall(19100, 12900, 1200, 180); wall(21200, 12900, 6050, 180); door(20300, 12900)
  wall(24200, 3250, 180, 5000); wall(24380, 5400, 2870, 160)
  wall(23900, 8500, 160, 2400); wall(24060, 10900, 3190, 160)
  wall(24000, 13100, 160, 2800); wall(24160, 15900, 3090, 160)
  door(25100, 5400, 750); door(23900, 10900, 750, true); door(24000, 15900, 750, true)
  // Living room and dining.
  rect(3500, 4300, 6200, 4700, 'hatch')
  sofa(4100, 4500, 3300, 900); sofa(3900, 5900, 900, 2800)
  rect(5400, 6100, 2100, 1400, 'furniture'); rect(5500, 6200, 1900, 1200, 'furniture')
  circle(6650, 6800, 250); rect(5730, 6420, 450, 300, 'furniture')
  chair(8400, 6000, 850, 850); chair(8400, 7250, 850, 850)
  rect(9900, 5300, 500, 3500, 'furniture'); rect(10050, 6200, 110, 1700, 'furniture')
  circle(3550, 9700, 330); tree(3550, 9700, 270)
  label(6800, 9600, 'LIVING ROOM', '42.80 m² · FFL ±0.000')
  rect(8400, 11800, 1750, 3300, 'furniture')
  for (let y = 12050; y < 15000; y += 900) { chair(7930, y, 460, 550); chair(10150, y, 460, 550) }
  chair(9020, 11330, 550, 460); chair(9020, 15100, 550, 460)
  circle(9250, 12700, 160); circle(9250, 14000, 160)
  label(9340, 16400, 'DINING', '18.60 m²')
  // Kitchen, counters and appliances.
  rect(11600, 3450, 6700, 600, 'furniture')
  for (let x = 11600; x <= 18200; x += 600) line(x, 3450, x, 4050, 'furniture')
  rect(17700, 4050, 600, 2300, 'furniture')
  rect(18000, 4280, 240, 1200, 'furniture')
  sink(13400, 3540); sink(14150, 3540)
  rect(12800, 5100, 3600, 1000, 'furniture')
  rect(14900, 5270, 800, 550, 'furniture')
  for (const [x, y] of [[15100, 5420], [15500, 5420], [15100, 5650], [15500, 5650]]) circle(x, y, 95)
  for (let x = 13000; x < 14900; x += 700) circle(x, 6420, 220)
  rect(11600, 4150, 800, 1000, 'furniture'); line(11600, 4650, 12400, 4650, 'furniture')
  text(14500, 4550, 'KITCHEN / BREAKFAST', 190)
  // Principal suite, bathroom and wardrobes.
  bed(21300, 3900, 1950)
  label(21700, 7200, 'PRIMARY SUITE', '27.40 m²')
  rect(19600, 3350, 550, 3200, 'furniture')
  for (let y = 3450; y < 6550; y += 520) { line(19600, y, 20150, y, 'furniture'); line(19650, y + 40, 20100, y + 420, 'hatch') }
  bath(24900, 3500); sink(24700, 4750); toilet(26500, 4670)
  text(25800, 6050, 'DRESSING', 155)
  for (let x = 24700; x < 27000; x += 550) rect(x, 6450, 500, 1200, 'furniture')
  // Guest bedrooms.
  bed(21200, 9050, 1600); label(21900, 12000, 'BEDROOM 02', '19.20 m²')
  sink(24600, 8670); toilet(26300, 8950); rect(24400, 9730, 1500, 900, 'furniture')
  line(24400, 9730, 25900, 10630, 'furniture'); line(25900, 9730, 24400, 10630, 'furniture')
  rect(24500, 11400, 2400, 550, 'furniture')
  for (let x = 24500; x < 26900; x += 600) line(x, 11400, x, 11950, 'furniture')
  bed(21200, 13500, 1600); label(21800, 16600, 'BEDROOM 03', '18.90 m²')
  bath(24600, 13400); sink(24400, 14500); toilet(26300, 15000)
  rect(24600, 16600, 2300, 550, 'furniture'); line(25750, 16600, 25750, 17150, 'furniture')
  // Study / library, entry, outdoor seating.
  rect(3050, 11450, 3700, 400, 'furniture')
  for (let x = 3200; x < 6650; x += 180) line(x, 11450, x, 11850, 'furniture')
  rect(3650, 13400, 2200, 850, 'furniture'); rect(4150, 13600, 800, 440, 'furniture')
  chair(4400, 14400, 650, 650); chair(4600, 12700, 550, 550)
  sofa(3300, 16100, 2800, 800); label(5250, 15500, 'STUDY / LIBRARY', '25.20 m²')
  text(15000, 15300, 'GALLERY / ENTRY', 195); text(15000, 15600, 'INDOOR – OUTDOOR LIVING', 120, 'dimensions')
  rect(11900, 16750, 2200, 450, 'furniture'); circle(12200, 16970, 160)
  rect(15900, 16500, 2350, 550, 'furniture')
  for (let x = 13000; x < 16100; x += 1000) { rect(x, 12850, 750, 1100, 'furniture'); line(x, 13100, x + 750, 13100, 'furniture') }
  text(15000, 7700, 'OPEN COURTYARD', 190)
  text(15000, 8010, '42.00 m² · OPEN TO SKY', 125, 'dimensions')
  rect(14000, 18000, 2600, 350, 'site'); rect(13800, 18350, 3000, 350, 'site'); rect(13600, 18700, 3400, 350, 'site')
  for (let i = 0; i < 4; i++) rect(14500, 19200 + i * 420, 1600, 300, 'site')
  // Set-out axes, dimensions and drawing metadata.
  dimH([2500, 11000, 19000, 24200, 27500], 2400, 3000)
  dimH([2500, 27500], 1700, 2300)
  dimH([2500, 7700, 11000, 19000, 24000, 27500], 19100, 18000)
  dimV([3000, 8300, 12900, 18000], 28900, 27500)
  dimV([3000, 10900, 18000], 1000, 2500)
  for (const [i, x] of [2500, 11000, 19000, 27500].entries()) {
    circle(x, 450, 235, 'dimensions'); text(x, 510, String.fromCharCode(65 + i), 180, 'dimensions')
    line(x, 700, x, 1100, 'dimensions')
  }
  text(3600, 21600, '01', 350); line(4100, 21180, 12300, 21180, 'text')
  text(8100, 21600, 'GROUND FLOOR PLAN', 300)
  text(16700, 21550, 'COURTYARD RESIDENCE  /  284 m²', 180, 'dimensions')
  line(24200, 21200, 26600, 21200, 'text')
  for (let i = 0; i < 5; i++) { line(24200 + i * 600, 21100, 24200 + i * 600, 21300, 'text'); text(24200 + i * 600, 21600, String(i), 130) }
  text(27200, 21600, 'm', 130)
  // North arrow.
  poly([[30400, 1850], [30150, 2850], [30400, 2630], [30650, 2850]], 'text')
  line(30400, 1850, 30400, 3400, 'text'); text(30400, 1510, 'N', 220)
  return { version: 1, title: 'Courtyard Residence', currentLayer: 'draft', entities, layers: structuredClone(LAYERS) }
}
