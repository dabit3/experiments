export type TaskId = 'menubar' | 'combobox' | 'tabs' | 'tree' | 'dialog' | 'slider'

export interface TaskDef {
  id: TaskId
  title: string
  pattern: string
  goal: string
  keys: string[]
}

export const TASKS: TaskDef[] = [
  {
    id: 'menubar',
    title: 'Menubar',
    pattern: 'role="menubar" with roving tabindex',
    goal: 'Open the View menu and activate Zen Mode.',
    keys: ['Tab', '← →', '↓ ↑', 'Enter', 'Esc'],
  },
  {
    id: 'combobox',
    title: 'Combobox',
    pattern: 'role="combobox" + listbox, list autocomplete',
    goal: 'Type to filter the country list and pick Kazakhstan.',
    keys: ['Tab', 'letters', '↓ ↑', 'Enter', 'Esc'],
  },
  {
    id: 'tabs',
    title: 'Tab list',
    pattern: 'role="tablist", automatic activation',
    goal: 'Arrow across the tabs to the Hidden tab and claim it.',
    keys: ['Tab', '← →', 'Home End', 'Enter'],
  },
  {
    id: 'tree',
    title: 'Tree view',
    pattern: 'role="tree" with nested groups',
    goal: 'Expand src › widgets › tree › vault and select golden-key.ts.',
    keys: ['Tab', '↓ ↑', '→ expand', '← collapse', 'Enter'],
  },
  {
    id: 'dialog',
    title: 'Modal dialog',
    pattern: 'role="dialog" aria-modal with focus trap',
    goal: 'Open the dialog, Tab to the third button, press Enter, then Escape.',
    keys: ['Enter', 'Tab', 'Shift+Tab', 'Esc'],
  },
  {
    id: 'slider',
    title: 'Slider',
    pattern: 'role="slider" with aria-valuenow',
    goal: 'Set the slider to exactly 42 and press Enter to lock it in.',
    keys: ['← →', 'PgUp PgDn', 'Home End', 'Enter'],
  },
]
