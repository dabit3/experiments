import { useState } from 'react'
import type { MouseEvent } from 'react'
import { MATERIALS, PAVILIONS, TREES, snap, visibleElements } from './model'
import type { Combination, Element, Point, Project } from './model'

export type Tool = 'Arrow' | 'Wall' | 'Slab' | 'Door' | 'Measure'
type Props = {
  project: Project; story: number; combination: Combination; selected: string | null
  tool: Tool; anchor: Point | null; onPoint: (point: Point, id?: string) => void
  zoom: number; grid: boolean
}
function PlanElement({ e, selected }: { e: Element; selected: boolean }) {
  const fill = e.kind === 'door' ? 'white' : e.material === 'glass' ? '#e1eff0' : e.kind === 'slab' ? '#f8f6f0' : MATERIALS[e.material].color
  return <g data-element-id={e.id} transform={`translate(${e.x} ${e.z}) rotate(${e.rotation})`} className={`plan-element ${selected ? 'selected-element' : ''}`}>
    <title>{e.name}</title>
    <rect x={-e.width / 2} y={-e.depth / 2} width={e.width} height={e.depth} fill={fill} stroke={selected ? '#167ad7' : '#414b49'} strokeWidth={selected ? .18 : e.kind === 'slab' ? .045 : .09} />
    {e.kind === 'wall' && <rect x={-e.width / 2} y={-.35} width={e.width} height={.7} fill="transparent" stroke="none" />}
    {e.kind === 'door' && <><path d={`M${-e.width / 2} 0v${-e.width}a${e.width} ${e.width} 0 0 1 ${e.width} ${e.width}`} fill="none" stroke={selected ? '#167ad7' : '#626e6d'} strokeWidth=".08" /><line x1={-e.width / 2} y1={0} x2={-e.width / 2} y2={-e.width} stroke="#555f5d" strokeWidth=".1" /></>}
    {selected && [-1, 1].flatMap(x => [-1, 1].map(z => <rect key={`${x}-${z}`} x={x * e.width / 2 - .12} y={z * e.depth / 2 - .12} width=".24" height=".24" fill="#198cff" stroke="white" strokeWidth=".04" />))}
  </g>
}
export default function Plan(props: Props) {
  const [cursor, setCursor] = useState<Point | null>(null)
  const extent = 88 / props.zoom
  const point = (event: MouseEvent<SVGSVGElement>): Point => {
    const svg = event.currentTarget
    const p = svg.createSVGPoint()
    p.x = event.clientX; p.y = event.clientY
    const transformed = p.matrixTransform(svg.getScreenCTM()!.inverse())
    return { x: snap(transformed.x), z: snap(transformed.y) }
  }
  const elements = visibleElements(props.project, props.combination, props.story)
  const ordered = [...elements].sort((a, b) => (a.kind === 'slab' ? -1 : a.kind === 'door' ? 1 : 0) - (b.kind === 'slab' ? -1 : b.kind === 'door' ? 1 : 0))
  return <svg aria-label="Editable floor plan" className={`plan ${props.tool !== 'Arrow' ? 'drawing' : ''}`} viewBox={`${-extent / 2} ${-extent * .4} ${extent} ${extent * .8}`}
    onMouseMove={event => setCursor(point(event))}
    onClick={event => {
      const target = event.target as SVGElement
      props.onPoint(point(event), target.closest('[data-element-id]')?.getAttribute('data-element-id') ?? undefined)
    }}>
    <defs>
      <pattern id="grid" width="1" height="1" patternUnits="userSpaceOnUse"><circle cx="0" cy="0" r=".028" fill="#c7cdcb" /></pattern>
      <pattern id="grass" width=".55" height=".55" patternUnits="userSpaceOnUse"><path d="M.1 .3l.15-.15" stroke="#c4ccba" strokeWidth=".035" /></pattern>
    </defs>
    {props.grid && <rect x="-200" y="-200" width="400" height="400" fill="url(#grid)" />}
    {props.combination === 'All elements' && <g pointerEvents="none">
      <rect x="-39.5" y="-32.5" width="79" height="65" fill="#f3f5ee" stroke="#bdc4b5" strokeWidth=".08" />
      <rect x="-39.5" y="-32.5" width="79" height="65" fill="url(#grass)" />
      <rect x="-29.5" y="-11" width="59" height="35" fill="#f5f4ef" stroke="#cecec4" strokeWidth=".08" />
      <rect x="-10" y="-.5" width="16" height="15" fill="#e9eedf" stroke="#c1cbb7" strokeWidth=".1" />
      <rect x="5.1" y="7" width="5.8" height="12" fill="#dbeaec" stroke="#b3c8c6" strokeWidth=".12" />
      <rect x="-7" y="24" width="14" height="7.5" fill="#f5f4ef" stroke="#cecec4" strokeWidth=".07" />
      {[24, 24.5, 25, 25.5].map(z => <path key={z} d={`M-7 ${z}h14`} stroke="#aaa" strokeWidth=".055" />)}
      {TREES.map(([x, z, s], i) => <g key={i} transform={`translate(${x} ${z})`}><circle r={2.5 * s} fill="#e3e9da" stroke="#a7b598" strokeWidth=".08" /><path d={`M${-2 * s} 0h${4 * s}M0 ${-2 * s}v${4 * s}`} stroke="#a4b596" strokeWidth=".035" /><circle r=".15" fill="#91a584" />{[0, 1, 2, 3, 4, 5].map(n => <circle key={n} cx={Math.cos(n) * s} cy={Math.sin(n) * s} r={1.3 * s} fill="none" stroke="#b6c3a9" strokeWidth=".03" />)}</g>)}
    </g>}
    {ordered.map(e => <PlanElement key={e.id} e={e} selected={e.id === props.selected} />)}
    <g pointerEvents="none">
      {props.story === 0 && PAVILIONS.map(p => <g key={p.name}>
        {[-1, 0, 1].map(i => <g key={i}><rect x={p.x + i * p.w / 3 - 1.25} y={p.z + 1.25} width="2.5" height="1.5" rx=".08" fill="#ebe3d3" stroke="#a59e8f" strokeWidth=".05" />{[-1, 1].map(side => <rect key={side} x={p.x + i * p.w / 3 - .3} y={p.z + 1.75 + side * 1.3} width=".6" height=".6" fill="none" stroke="#a59e8f" strokeWidth=".06" />)}</g>)}
        <text x={p.x} y={p.z - 1.2} textAnchor="middle" fontSize=".62" letterSpacing=".13" fill="#77807a">{p.number} / {p.name.toUpperCase()}</text>
        <text x={p.x} y={p.z + .05} textAnchor="middle" fontSize=".65" fill="#9a9e94">{p.w * p.d}.00 m²</text>
        <path d={`M${p.x - p.w / 2} ${p.z - p.d / 2 - 2}h${p.w}m0 -1v2m${-p.w} -2v2`} fill="none" stroke="#899792" strokeWidth=".07" />
        <text x={p.x} y={p.z - p.d / 2 - 2.5} textAnchor="middle" fontSize=".65" fill="#687670">{p.w.toFixed(2)}</text>
      </g>)}
      {props.story === 0 && <><text x="-2" y="8" textAnchor="middle" fontSize=".6" letterSpacing=".1" fill="#87947d">SCULPTURE GARDEN</text><text x="0" y="29" textAnchor="middle" fontSize=".6" letterSpacing=".13" fill="#92968d">CAMPUS ENTRY</text>
        <path d="M-35 -31v61M-36 -24h74" stroke="#6f969d" strokeDasharray=".5 .45" strokeWidth=".06" />
        <circle cx="-35" cy="-31" r=".8" fill="white" stroke="#709ba6" strokeWidth=".09" /><text x="-35" y="-30.77" fontSize=".68" textAnchor="middle" fill="#50747c">A</text></>}
    </g>
    {props.anchor && cursor && <g pointerEvents="none" stroke="#268dd8" strokeWidth=".13" fill="#268dd811" strokeDasharray=".35 .2">
      {props.tool === 'Slab' ? <rect x={Math.min(props.anchor.x, cursor.x)} y={Math.min(props.anchor.z, cursor.z)} width={Math.abs(cursor.x - props.anchor.x)} height={Math.abs(cursor.z - props.anchor.z)} /> : <line x1={props.anchor.x} y1={props.anchor.z} x2={cursor.x} y2={cursor.z} />}
      <circle cx={props.anchor.x} cy={props.anchor.z} r=".2" fill="#2287ce" />
      <text x={(props.anchor.x + cursor.x) / 2} y={(props.anchor.z + cursor.z) / 2 - 1} stroke="none" fill="#167bb7" textAnchor="middle" fontSize=".9">{Math.hypot(cursor.x - props.anchor.x, cursor.z - props.anchor.z).toFixed(2)} m</text>
    </g>}
  </svg>
}
