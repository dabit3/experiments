import type { EdgeStyle } from '../types'
import { Icon, Logo } from './Icons'
import type { IconName } from './Icons'
import './Toolbar.css'

export type Tool = 'select' | 'pan'

interface ToolbarProps {
  tool: Tool
  onToolChange: (tool: Tool) => void
  edgeStyle: EdgeStyle
  onEdgeStyleChange: (style: EdgeStyle) => void
  snapToGrid: boolean
  onSnapChange: (snap: boolean) => void
  zoom: number
  onZoomIn: () => void
  onZoomOut: () => void
  onFit: () => void
  canUndo: boolean
  canRedo: boolean
  onUndo: () => void
  onRedo: () => void
  hasSelection: boolean
  onDuplicate: () => void
  onDelete: () => void
  onAutoLayout: () => void
  onImport: () => void
  onExportJSON: () => void
  onExportSVG: () => void
  onNew: () => void
}

function ToolButton({
  icon,
  label,
  title,
  active,
  disabled,
  primary,
  onClick,
  testId,
}: {
  icon: IconName
  label?: string
  title: string
  active?: boolean
  disabled?: boolean
  primary?: boolean
  onClick: () => void
  testId: string
}) {
  return (
    <button
      type="button"
      className={`tb-btn${active ? ' is-active' : ''}${label ? ' has-label' : ''}${primary ? ' is-primary' : ''}`}
      title={title}
      aria-label={title}
      aria-pressed={active}
      disabled={disabled}
      onClick={onClick}
      data-action={testId}
    >
      <Icon name={icon} />
      {label && <span>{label}</span>}
    </button>
  )
}

export function Toolbar(p: ToolbarProps) {
  return (
    <header className="toolbar">
      <div className="brand">
        <Logo size={30} />
        <span className="brand-text">
          <span className="brand-name">Flowchart Studio</span>
          <span className="brand-sub">Diagram workspace</span>
        </span>
      </div>

      <div className="tb-group" role="group" aria-label="Tools">
        <ToolButton icon="select" label="Select" title="Select tool (V)" active={p.tool === 'select'} onClick={() => p.onToolChange('select')} testId="tool-select" />
        <ToolButton icon="hand" label="Pan" title="Pan tool (H) — or hold Space and drag" active={p.tool === 'pan'} onClick={() => p.onToolChange('pan')} testId="tool-pan" />
      </div>

      <div className="tb-group" role="group" aria-label="Edge style">
        <ToolButton icon="orthogonal" label="Orthogonal" title="Orthogonal edges" active={p.edgeStyle === 'orthogonal'} onClick={() => p.onEdgeStyleChange('orthogonal')} testId="edges-orthogonal" />
        <ToolButton icon="straight" label="Straight" title="Straight edges" active={p.edgeStyle === 'straight'} onClick={() => p.onEdgeStyleChange('straight')} testId="edges-straight" />
      </div>

      <div className="tb-group" role="group" aria-label="Canvas">
        <ToolButton icon="grid" label="Snap" title={`Snap to grid: ${p.snapToGrid ? 'on' : 'off'}`} active={p.snapToGrid} onClick={() => p.onSnapChange(!p.snapToGrid)} testId="snap" />
        <ToolButton icon="layout" label="Auto layout" title="Auto layout (layered, top to bottom)" onClick={p.onAutoLayout} testId="auto-layout" />
      </div>

      <div className="tb-group" role="group" aria-label="Edit">
        <ToolButton icon="undo" title="Undo (Ctrl+Z)" disabled={!p.canUndo} onClick={p.onUndo} testId="undo" />
        <ToolButton icon="redo" title="Redo (Ctrl+Shift+Z)" disabled={!p.canRedo} onClick={p.onRedo} testId="redo" />
        <ToolButton icon="duplicate" title="Duplicate selection (Ctrl+D)" disabled={!p.hasSelection} onClick={p.onDuplicate} testId="duplicate" />
        <ToolButton icon="trash" title="Delete selection (Delete)" disabled={!p.hasSelection} onClick={p.onDelete} testId="delete" />
      </div>

      <div className="tb-group zoom-group" role="group" aria-label="Zoom">
        <ToolButton icon="zoom-out" title="Zoom out (-)" onClick={p.onZoomOut} testId="zoom-out" />
        <button type="button" className="tb-zoom" title="Fit diagram to view (Shift+1)" onClick={p.onFit} data-action="zoom-fit">
          {Math.round(p.zoom * 100)}%
        </button>
        <ToolButton icon="zoom-in" title="Zoom in (+)" onClick={p.onZoomIn} testId="zoom-in" />
        <ToolButton icon="fit" title="Fit to view (Shift+1)" onClick={p.onFit} testId="fit" />
      </div>

      <div className="tb-spacer" />

      <div className="tb-group tb-group-plain" role="group" aria-label="File">
        <ToolButton icon="new" label="New" title="Clear the canvas" onClick={p.onNew} testId="new" />
        <ToolButton icon="import" label="Import JSON" title="Import a diagram from JSON" onClick={p.onImport} testId="import-json" />
        <ToolButton icon="json" label="Export JSON" title="Download the diagram as JSON" onClick={p.onExportJSON} testId="export-json" />
      </div>
      <ToolButton icon="svg" label="Export SVG" title="Download the diagram as SVG" primary onClick={p.onExportSVG} testId="export-svg" />
    </header>
  )
}
