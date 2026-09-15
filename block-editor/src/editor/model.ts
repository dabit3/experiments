export type BlockType =
  | 'paragraph'
  | 'heading1'
  | 'heading2'
  | 'bullet'
  | 'numbered'
  | 'todo'
  | 'quote'
  | 'code'
  | 'divider'

export interface Block {
  id: string
  type: BlockType
  /** Inner HTML of the block's editable area (inline formatting lives here). */
  html: string
  checked?: boolean
}

export interface Doc {
  title: string
  blocks: Block[]
}

export interface BlockTypeMeta {
  type: BlockType
  label: string
  description: string
  placeholder: string
  keywords: string[]
  icon: string
}

export const BLOCK_TYPES: readonly BlockTypeMeta[] = [
  {
    type: 'paragraph',
    label: 'Text',
    description: 'Just start writing with plain text.',
    placeholder: "Type '/' for commands",
    keywords: ['text', 'paragraph', 'plain'],
    icon: 'Aa',
  },
  {
    type: 'heading1',
    label: 'Heading 1',
    description: 'Big section heading.',
    placeholder: 'Heading 1',
    keywords: ['h1', 'heading', 'title'],
    icon: 'H1',
  },
  {
    type: 'heading2',
    label: 'Heading 2',
    description: 'Medium section heading.',
    placeholder: 'Heading 2',
    keywords: ['h2', 'heading', 'subtitle'],
    icon: 'H2',
  },
  {
    type: 'bullet',
    label: 'Bullet list',
    description: 'Create a simple bulleted list.',
    placeholder: 'List item',
    keywords: ['bullet', 'list', 'ul', 'unordered'],
    icon: '•',
  },
  {
    type: 'numbered',
    label: 'Numbered list',
    description: 'Create a list with numbering.',
    placeholder: 'List item',
    keywords: ['numbered', 'list', 'ol', 'ordered'],
    icon: '1.',
  },
  {
    type: 'todo',
    label: 'To-do list',
    description: 'Track tasks with a checkbox.',
    placeholder: 'To-do',
    keywords: ['todo', 'task', 'checkbox', 'check'],
    icon: '☑',
  },
  {
    type: 'quote',
    label: 'Quote',
    description: 'Capture a quotation.',
    placeholder: 'Empty quote',
    keywords: ['quote', 'blockquote', 'cite'],
    icon: '❝',
  },
  {
    type: 'code',
    label: 'Code block',
    description: 'Capture a code snippet.',
    placeholder: 'Write some code…',
    keywords: ['code', 'snippet', 'pre', 'monospace'],
    icon: '</>',
  },
  {
    type: 'divider',
    label: 'Divider',
    description: 'Visually divide blocks.',
    placeholder: '',
    keywords: ['divider', 'hr', 'rule', 'separator', 'line'],
    icon: '—',
  },
]

export const BLOCK_META = BLOCK_TYPES.reduce(
  (acc, meta) => ({ ...acc, [meta.type]: meta }),
  {} as Record<BlockType, BlockTypeMeta>,
)

/** Slash-menu search: matches labels by substring and keywords by prefix. */
export function filterBlockTypes(query: string): BlockTypeMeta[] {
  const q = query.trim().toLowerCase()
  if (!q) return [...BLOCK_TYPES]
  return BLOCK_TYPES.filter(
    (meta) => meta.label.toLowerCase().includes(q) || meta.keywords.some((k) => k.startsWith(q)),
  )
}

export const LIST_TYPES: ReadonlySet<BlockType> = new Set(['bullet', 'numbered', 'todo'])

/** Typed at the start of an empty paragraph followed by a space. */
export const MARKDOWN_SHORTCUTS: Record<string, BlockType> = {
  '#': 'heading1',
  '##': 'heading2',
  '-': 'bullet',
  '*': 'bullet',
  '1.': 'numbered',
  '[]': 'todo',
  '[ ]': 'todo',
  '>': 'quote',
}

export function createBlock(type: BlockType = 'paragraph', html = ''): Block {
  const block: Block = { id: crypto.randomUUID(), type, html }
  if (type === 'todo') block.checked = false
  return block
}

export function emptyDoc(): Doc {
  return { title: '', blocks: [createBlock()] }
}

export function isEmptyHtml(html: string): boolean {
  return html === '' || html === '<br>'
}

/** Chrome leaves a lone `<br>` behind when all text is deleted; treat it as empty. */
export function normalizeHtml(html: string): string {
  return html === '<br>' ? '' : html
}

export function blockIndex(doc: Doc, id: string): number {
  return doc.blocks.findIndex((b) => b.id === id)
}

export function updateBlock(doc: Doc, id: string, patch: Partial<Omit<Block, 'id'>>): Doc {
  return { ...doc, blocks: doc.blocks.map((b) => (b.id === id ? { ...b, ...patch } : b)) }
}

export function insertBlocks(doc: Doc, index: number, ...blocks: Block[]): Doc {
  const next = [...doc.blocks]
  next.splice(index, 0, ...blocks)
  return { ...doc, blocks: next }
}

export function removeBlock(doc: Doc, id: string): Doc {
  return { ...doc, blocks: doc.blocks.filter((b) => b.id !== id) }
}

export function moveBlock(doc: Doc, from: number, to: number): Doc {
  const next = [...doc.blocks]
  const [moved] = next.splice(from, 1)
  next.splice(to, 0, moved)
  return { ...doc, blocks: next }
}

/** First block in `to` that differs from its counterpart in `from` (used to place the caret after undo/redo). */
export function firstChangedBlock(from: Doc, to: Doc): Block | undefined {
  return to.blocks.find((b, i) => {
    const prev = from.blocks[i]
    return !prev || prev.id !== b.id || prev.html !== b.html || prev.type !== b.type || prev.checked !== b.checked
  })
}
