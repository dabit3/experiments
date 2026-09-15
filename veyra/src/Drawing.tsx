import { useRef, useState } from 'react'
import type { MouseEvent } from 'react'
import { isWall, snap } from './model'
import type { Element, Point, Project, View } from './model'

const colors = { Concrete: '#b7b9b7', Limestone: '#eeeae1', Timber: '#cdb28c', Glass: '#b2cdd5', Plaster: '#c5c7c4', Metal: '#8c9a9f' }
export function Drawing({ project, selected, onSelect, view, tool, onPoint, start, dimensions, zoom }: {
  project: Project; selected: string | null; onSelect: (id: string | null) => void; view: View; tool: string; onPoint: (p: Point) => void; start: Point | null; dimensions: boolean; zoom: number
}) {
  const svg = useRef<SVGSVGElement>(null)
  const [hover, setHover] = useState<Point | null>(null)
  const plan = view === 'Level 1'
  const point = (e: MouseEvent<SVGSVGElement>) => {
    const root = svg.current
    if (!root) return { x: 0, z: 0 }
    const p = new DOMPoint(e.clientX, e.clientY).matrixTransform(root.getScreenCTM()?.inverse())
    return { x: snap(p.x), z: snap(p.y) }
  }
  const clickElement = (e: MouseEvent, element: Element) => {
    if (tool === 'select') { e.stopPropagation(); onSelect(element.id) }
  }
  const renderPlan = (el: Element) => {
    const active = el.id === selected
    const stroke = active ? '#0786d3' : '#4d5e65'
    return <g key={el.id} data-element-id={el.id} aria-label={el.name} className="drawing-element" transform={`translate(${el.x} ${el.z}) rotate(${el.rotation * 180 / Math.PI})`} onClick={e => clickElement(e, el)}>
      <title>{el.name}</title>
      {isWall(el) && <rect x={-el.w / 2} y={-.42} width={el.w} height={.84} fill="transparent" stroke="none"/>}
      <rect x={-el.w / 2} y={-el.d / 2} width={el.w} height={el.d} fill={active ? '#96cfee' : el.category === 'Door' ? '#fff' : colors[el.material]} stroke={stroke} strokeWidth={active ? .11 : el.category === 'Floor' ? .035 : .065} />
      {el.category === 'Curtain Wall' && Array.from({ length: Math.ceil(el.w / 1.5) + 1 }, (_, i) => <line key={i} x1={-el.w / 2 + i * el.w / Math.ceil(el.w / 1.5)} x2={-el.w / 2 + i * el.w / Math.ceil(el.w / 1.5)} y1={-.12} y2={.12} stroke={stroke} strokeWidth=".08"/>)}
      {el.category === 'Door' && <><path d={`M${-el.w / 2},0 v${-el.w} A${el.w},${el.w} 0 0 1 ${el.w / 2},0`} fill="white" stroke={stroke} strokeWidth=".04"/><path d={`M${-el.w / 2},0 v${-el.w}`} stroke={stroke} strokeWidth=".07"/></>}
      {active && <><circle cx={-el.w / 2} cy="0" r=".14" fill="#0786d3"/><circle cx={el.w / 2} cy="0" r=".14" fill="#0786d3"/></>}
    </g>
  }
  const visible = project.elements.filter(e => !project.hidden.includes(e.category) && e.category !== 'Landscape')
  const ordered = [...visible].sort((a, b) => (a.category === 'Floor' ? -1 : a.category === 'Door' ? 1 : 0) - (b.category === 'Floor' ? -1 : b.category === 'Door' ? 1 : 0))
  return <svg ref={svg} className={`drawing-canvas ${tool !== 'select' ? 'placing' : ''}`} role="img" aria-label={plan ? 'Level 1 editable floor plan' : 'Coordinated south elevation'} viewBox={`${-29 / zoom} ${-21 / zoom} ${58 / zoom} ${42 / zoom}`} onMouseMove={e => setHover(point(e))} onMouseLeave={() => setHover(null)} onClick={e => tool !== 'select' && plan ? onPoint(point(e)) : onSelect(null)}>
    <defs><pattern id="paving" width="2" height="2" patternUnits="userSpaceOnUse"><path d="M2 0H0V2" fill="none" stroke="#d8dcd8" strokeWidth=".022"/></pattern><pattern id="earth" width=".3" height=".3" patternUnits="userSpaceOnUse"><path d="M0 .3 .3 0" stroke="#afb6b7" strokeWidth=".025"/></pattern></defs>
    {plan ? <>
      <rect x="-21" y="-15" width="42" height="30" fill="url(#paving)" stroke="#c2c8c5" strokeWidth=".04"/>
      {!project.hidden.includes('Landscape') && <>
        <rect x="-15" y="13" width="13" height="4" fill="#e4eff1" stroke="#9bafb2" strokeWidth=".07"/>
        {[[-23, -10], [-23, 0], [-23, 10], [23, -10], [23, 0], [23, 10]].map(([x, z], i) => <g key={i} transform={`translate(${x} ${z})`} stroke="#94a384" strokeWidth=".035" fill="#e8eddf"><circle r="1.8"/><circle r="1.5"/><path d="M-1.5 0h3M0-1.5v3"/></g>)}
        {Array.from({ length: 6 }, (_, i) => <path key={i} d={`M5.5 ${10 + i * .45}h7`} stroke="#b1b8b5" strokeWidth=".04"/>)}
      </>}
      {ordered.filter(e => e.y < 1 && e.category !== 'Roof' && e.category !== 'Timber Fins').map(renderPlan)}
      <g fill="#74828a" textAnchor="middle" fontSize=".35" letterSpacing=".035" pointerEvents="none">
        {[[-11, -3, 'GALLERY 01', '142 m²'], [-2, -3, 'EXHIBITION HALL', '186 m²'], [9, -3, 'CULTURAL FORUM', '164 m²'], [9, 5.5, 'ARRIVAL', '68 m²']].map(([x, y, a, b]) => <g key={String(a)} transform={`translate(${x} ${y})`}><text>{a}</text><text y=".6" fontSize=".26" fill="#98a2a7">{b}</text></g>)}
      </g>
      {dimensions && <g stroke="#8d9ea6" strokeWidth=".03" fill="none">
        {[-15, -7, 3, 15].map((x, i) => <g key={x}><path d={`M${x} -13V11`} strokeDasharray=".4 .18"/><circle cx={x} cy="-13.8" r=".45" fill="#fff"/><text x={x} y="-13.66" stroke="none" fill="#778c99" fontSize=".4" textAnchor="middle">{i + 1}</text></g>)}
        {[-8.5, 0, 8.5].map((y, i) => <g key={y}><path d={`M-18 ${y}H18`} strokeDasharray=".4 .18"/><circle cx="-19" cy={y} r=".45" fill="#fff"/><text x="-19" y={y + .14} stroke="none" fill="#778c99" fontSize=".4" textAnchor="middle">{String.fromCharCode(65 + i)}</text></g>)}
        <path d="M-15-16H15M-15-16.5v1M15-16.5v1M-7-16.5v1M3-16.5v1"/>
        <g stroke="none" fill="#748992" fontSize=".36" textAnchor="middle"><text x="-11" y="-16.4">8 000</text><text x="-2" y="-16.4">10 000</text><text x="9" y="-16.4">12 000</text></g>
      </g>}
      {hover && tool !== 'select' && <g pointerEvents="none" stroke="#007bc1" strokeWidth=".045"><path d={`M${hover.x - .5} ${hover.z}h1M${hover.x} ${hover.z - .5}v1`}/>{start && <><line x1={start.x} y1={start.z} x2={hover.x} y2={hover.z} strokeWidth=".18" strokeDasharray=".3 .1"/><text x={(hover.x + start.x) / 2} y={(hover.z + start.z) / 2 - .5} stroke="none" fill="#007bc1" fontSize=".45">{Math.hypot(hover.x - start.x, hover.z - start.z).toFixed(2)} m</text></>}</g>}
      <g transform="translate(21 -17)" fill="#536776"><path d="m0-1-.3 1.8.3-.35.3.35Z"/><text y="-1.4" textAnchor="middle" fontSize=".5">N</text></g>
    </> : <>
      <rect x="-22" y="9" width="44" height=".5" fill="url(#earth)" />
      <line x1="-23" y1="9" x2="23" y2="9" stroke="#576368" strokeWidth=".055"/>
      {visible.filter(e => e.category !== 'Furniture').sort((a, b) => a.z - b.z).map(el => {
        const width = Math.abs(el.w * Math.cos(el.rotation)) + Math.abs(el.d * Math.sin(el.rotation))
        return <g key={el.id} data-element-id={el.id} className="drawing-element" aria-label={el.name} onClick={e => clickElement(e, el)}>
          <title>{el.name}</title>
          <rect x={el.x - width / 2} y={9 - el.y - el.h} width={width} height={el.h} fill={el.id === selected ? '#a9d6f0' : colors[el.material]} fillOpacity={el.category === 'Curtain Wall' ? .6 : 1} stroke={el.id === selected ? '#007dca' : '#67767b'} strokeWidth={el.id === selected ? .1 : .035}/>
          {(el.category === 'Curtain Wall' || el.category === 'Timber Fins') && Array.from({ length: Math.ceil(width / (el.category === 'Timber Fins' ? .46 : 1.5)) }, (_, i) => <line key={i} x1={el.x - width / 2 + i * (el.category === 'Timber Fins' ? .46 : 1.5)} x2={el.x - width / 2 + i * (el.category === 'Timber Fins' ? .46 : 1.5)} y1={9 - el.y - el.h} y2={9 - el.y} stroke={el.category === 'Timber Fins' ? '#997341' : '#77909a'} strokeWidth={el.category === 'Timber Fins' ? .09 : .04}/>)}
        </g>
      })}
      {dimensions && [0, 4.42, 8.58].map((h, i) => <g key={h} stroke="#879dab" strokeWidth=".035"><path d={`M-22 ${9 - h}H23`} strokeDasharray=".6 .15 .08 .15"/><circle cx="23" cy={9 - h} r=".35" fill="#fff"/><text x="23" y={8.35 - h} textAnchor="end" fill="#687e8b" stroke="none" fontSize=".38">{['LEVEL 1', 'LEVEL 2', 'ROOF'][i]} · +{h.toFixed(3)}</text></g>)}
    </>}
    <g transform={`translate(-19 ${plan ? 19 : 14})`} fill="#617581"><circle cx="0" cy="0" r=".65" fill="none" stroke="#81949e" strokeWidth=".04"/><text x="0" y=".15" fontSize=".45" textAnchor="middle">{plan ? '01' : '02'}</text><text x="1.2" y="-.1" fontSize=".62" letterSpacing=".10">{plan ? 'LEVEL 1 · FLOOR PLAN' : 'SOUTH ELEVATION'}</text><path d="M1.2 .25h16" stroke="#8c9ca5" strokeWidth=".035"/><text x="1.2" y=".8" fontSize=".31">ALDER CULTURAL PAVILION     /     1 : 100     /     ALL DIMENSIONS IN mm</text></g>
  </svg>
}
