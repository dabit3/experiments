import { TOOLS, type Tool } from '../types'
import { ToolIcon } from './ToolIcon'
import { Icon } from './Icon'
import './Toolbar.css'

interface Props {
  tool: Tool
  color: string
  onToolChange: (tool: Tool) => void
  onHelp: () => void
}

export function Toolbar({ tool, color, onToolChange, onHelp }: Props) {
  return (
    <aside className="tool-rail" aria-label="Drawing tools">
      <div className="rail-handle">
        <span />
        <span />
      </div>
      {TOOLS.map((item, index) => (
        <button
          key={item.id}
          className={`rail-tool ${tool === item.id ? 'active' : ''} ${index === 2 || index === 6 ? 'group-start' : ''}`}
          onClick={() => onToolChange(item.id)}
          title={`${item.label} (${item.hotkey})`}
          aria-label={item.label}
          aria-pressed={tool === item.id}
        >
          <ToolIcon tool={item.id} />
          <span className="tool-tooltip">
            {item.label}
            <kbd>{item.hotkey}</kbd>
          </span>
        </button>
      ))}
      <div
        className="rail-colors"
        title={`Foreground ${color}; background white`}
      >
        <span />
        <span style={{ background: color }} />
      </div>
      <button
        className="rail-tool help-tool"
        aria-label="Keyboard shortcuts"
        title="Keyboard shortcuts (?)"
        onClick={onHelp}
      >
        <Icon name="help" />
      </button>
    </aside>
  )
}
