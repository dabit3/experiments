import { useEffect, useMemo, useRef, useState } from 'react'
import type { KeyboardEvent } from 'react'
import { findTypeahead, isPrintableKey } from '../lib/keys'
import type { WidgetProps } from './types'

interface TreeNode {
  id: string
  name: string
  children?: TreeNode[]
}

export const TREE_TARGET = 'src/widgets/tree/vault/golden-key.ts'

const ROOT: TreeNode = {
  id: 'gauntlet',
  name: 'gauntlet',
  children: [
    {
      id: 'src',
      name: 'src',
      children: [
        {
          id: 'src/widgets',
          name: 'widgets',
          children: [
            {
              id: 'src/widgets/menubar',
              name: 'menubar',
              children: [
                { id: 'src/widgets/menubar/Menubar.tsx', name: 'Menubar.tsx' },
                { id: 'src/widgets/menubar/menubar.css', name: 'menubar.css' },
              ],
            },
            {
              id: 'src/widgets/combobox',
              name: 'combobox',
              children: [
                { id: 'src/widgets/combobox/Combobox.tsx', name: 'Combobox.tsx' },
                { id: 'src/widgets/combobox/countries.ts', name: 'countries.ts' },
              ],
            },
            {
              id: 'src/widgets/tree',
              name: 'tree',
              children: [
                { id: 'src/widgets/tree/Tree.tsx', name: 'Tree.tsx' },
                {
                  id: 'src/widgets/tree/vault',
                  name: 'vault',
                  children: [
                    { id: 'src/widgets/tree/vault/decoy-key.ts', name: 'decoy-key.ts' },
                    { id: TREE_TARGET, name: 'golden-key.ts' },
                    { id: 'src/widgets/tree/vault/README.md', name: 'README.md' },
                  ],
                },
                { id: 'src/widgets/tree/flatten.ts', name: 'flatten.ts' },
              ],
            },
          ],
        },
        { id: 'src/App.tsx', name: 'App.tsx' },
        { id: 'src/main.tsx', name: 'main.tsx' },
      ],
    },
    {
      id: 'docs',
      name: 'docs',
      children: [
        { id: 'docs/a11y.md', name: 'a11y.md' },
        { id: 'docs/patterns.md', name: 'patterns.md' },
      ],
    },
    { id: 'package.json', name: 'package.json' },
    { id: 'README.md', name: 'README.md' },
  ],
}

interface VisibleRow {
  node: TreeNode
  level: number
  parent: TreeNode | null
  posinset: number
  setsize: number
}

function flatten(node: TreeNode, expanded: Set<string>): VisibleRow[] {
  const rows: VisibleRow[] = []
  const walk = (n: TreeNode, level: number, parent: TreeNode | null, pos: number, size: number) => {
    rows.push({ node: n, level, parent, posinset: pos, setsize: size })
    if (n.children && expanded.has(n.id)) {
      n.children.forEach((c, i) => walk(c, level + 1, n, i + 1, n.children!.length))
    }
  }
  walk(node, 1, null, 1, 1)
  return rows
}

function FolderIcon({ open }: { open: boolean }) {
  return (
    <svg className="tree-icon folder" viewBox="0 0 20 20" aria-hidden="true">
      <path d="M2 5.5A1.5 1.5 0 0 1 3.5 4h4.2l1.8 1.8h7A1.5 1.5 0 0 1 18 7.3v7.2a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 2 14.5z" />
      {open && <path className="folder-flap" d="M2.5 9h15l-1.2 6.2a1 1 0 0 1-1 .8H4.4a1 1 0 0 1-1-.8z" />}
    </svg>
  )
}

function FileIcon({ name }: { name: string }) {
  const ext = name.split('.').pop() ?? ''
  return (
    <svg className={`tree-icon file ext-${ext}`} viewBox="0 0 20 20" aria-hidden="true">
      <path d="M5 2h6.5L16 6.5V17a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z" />
      <path className="file-fold" d="M11.5 2v4.5H16" />
    </svg>
  )
}

export function TreeTask({ onComplete }: WidgetProps) {
  const [expanded, setExpanded] = useState<Set<string>>(() => new Set([ROOT.id]))
  const [focusedId, setFocusedId] = useState(ROOT.id)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const itemRefs = useRef(new Map<string, HTMLLIElement>())
  const pendingFocus = useRef(false)

  const rows = useMemo(() => flatten(ROOT, expanded), [expanded])
  const index = rows.findIndex((r) => r.node.id === focusedId)

  useEffect(() => {
    if (!pendingFocus.current) return
    pendingFocus.current = false
    itemRefs.current.get(focusedId)?.focus()
  }, [focusedId, rows])

  const moveTo = (id: string) => {
    pendingFocus.current = true
    setFocusedId(id)
  }

  const toggle = (id: string, open: boolean) => {
    setExpanded((prev) => {
      const next = new Set(prev)
      if (open) next.add(id)
      else next.delete(id)
      return next
    })
  }

  const select = (node: TreeNode) => {
    setSelectedId(node.id)
    if (node.children) toggle(node.id, !expanded.has(node.id))
    else if (node.id === TREE_TARGET) onComplete()
  }

  const onKeyDown = (e: KeyboardEvent<HTMLUListElement>) => {
    if (index === -1) return
    const row = rows[index]
    const node = row.node
    const isFolder = Boolean(node.children)
    const isOpen = isFolder && expanded.has(node.id)

    switch (e.key) {
      case 'ArrowDown':
        if (index < rows.length - 1) moveTo(rows[index + 1].node.id)
        break
      case 'ArrowUp':
        if (index > 0) moveTo(rows[index - 1].node.id)
        break
      case 'ArrowRight':
        if (!isFolder) break
        if (!isOpen) toggle(node.id, true)
        else if (node.children!.length > 0) moveTo(node.children![0].id)
        break
      case 'ArrowLeft':
        if (isOpen) toggle(node.id, false)
        else if (row.parent) moveTo(row.parent.id)
        break
      case 'Home':
        moveTo(rows[0].node.id)
        break
      case 'End':
        moveTo(rows[rows.length - 1].node.id)
        break
      case 'Enter':
      case ' ':
        select(node)
        break
      case '*': {
        if (!row.parent) break
        setExpanded((prev) => {
          const next = new Set(prev)
          for (const sibling of row.parent!.children ?? []) if (sibling.children) next.add(sibling.id)
          return next
        })
        break
      }
      default: {
        if (!isPrintableKey(e)) return
        const j = findTypeahead(rows.map((r) => r.node.name), index, e.key)
        if (j === -1) return
        moveTo(rows[j].node.id)
      }
    }
    e.preventDefault()
  }

  const renderNode = (node: TreeNode, level: number, pos: number, size: number) => {
    const isFolder = Boolean(node.children)
    const isOpen = isFolder && expanded.has(node.id)
    return (
      <li
        key={node.id}
        role="treeitem"
        aria-level={level}
        aria-posinset={pos}
        aria-setsize={size}
        aria-expanded={isFolder ? isOpen : undefined}
        aria-selected={selectedId === node.id}
        tabIndex={focusedId === node.id ? 0 : -1}
        className="treeitem"
        ref={(el) => {
          if (el) itemRefs.current.set(node.id, el)
          else itemRefs.current.delete(node.id)
        }}
        onFocus={(e) => {
          if (e.target === e.currentTarget) setFocusedId(node.id)
        }}
      >
        <div className="tree-row" style={{ paddingLeft: 12 + (level - 1) * 22 }}>
          <span className={`twisty${isFolder ? '' : ' leaf'}${isOpen ? ' open' : ''}`} aria-hidden="true" />
          {isFolder ? <FolderIcon open={isOpen} /> : <FileIcon name={node.name} />}
          <span className="tree-name">{node.name}</span>
          {node.id === TREE_TARGET && selectedId === node.id && <span className="tree-badge">selected</span>}
        </div>
        {isFolder && isOpen && (
          <ul role="group" className="tree-group">
            {node.children!.map((child, i) => renderNode(child, level + 1, i + 1, node.children!.length))}
          </ul>
        )}
      </li>
    )
  }

  const selectedNode = selectedId ? rows.find((r) => r.node.id === selectedId)?.node : undefined

  return (
    <div className="tree-shell">
      <ul role="tree" aria-label="Project files" className="tree" onKeyDown={onKeyDown}>
        {renderNode(ROOT, 1, 1, 1)}
      </ul>
      <p className="widget-status" aria-live="polite">
        {selectedId ? (
          <>
            Selected <strong>{selectedId}</strong>
            {selectedId !== TREE_TARGET && !selectedNode?.children && (
              <span className="status-hint"> — not the target file</span>
            )}
          </>
        ) : (
          `${rows.length} visible nodes · → expands, ← collapses, Enter selects`
        )}
      </p>
    </div>
  )
}
