import { useEffect, useRef } from 'react'
import type { TaskDef } from '../tasks'
import { TASKS } from '../tasks'
import { MenubarTask } from '../widgets/MenubarTask'
import { ComboboxTask } from '../widgets/ComboboxTask'
import { TabsTask } from '../widgets/TabsTask'
import { TreeTask } from '../widgets/TreeTask'
import { DialogTask } from '../widgets/DialogTask'
import { SliderTask } from '../widgets/SliderTask'

interface Props {
  task: TaskDef
  index: number
  onComplete: () => void
}

function Widget({ id, onComplete }: { id: TaskDef['id']; onComplete: () => void }) {
  switch (id) {
    case 'menubar':
      return <MenubarTask onComplete={onComplete} />
    case 'combobox':
      return <ComboboxTask onComplete={onComplete} />
    case 'tabs':
      return <TabsTask onComplete={onComplete} />
    case 'tree':
      return <TreeTask onComplete={onComplete} />
    case 'dialog':
      return <DialogTask onComplete={onComplete} />
    case 'slider':
      return <SliderTask onComplete={onComplete} />
  }
}

export function TaskCard({ task, index, onComplete }: Props) {
  const headingRef = useRef<HTMLHeadingElement>(null)

  useEffect(() => {
    headingRef.current?.focus()
  }, [])

  return (
    <section className="card task" aria-labelledby={`task-title-${task.id}`} data-testid={`task-${task.id}`}>
      <div className="task-head">
        <p className="eyebrow">
          Task {index + 1} of {TASKS.length} · {task.pattern}
        </p>
        <h2 id={`task-title-${task.id}`} tabIndex={-1} ref={headingRef}>
          {task.title}
        </h2>
        <p className="task-goal">{task.goal}</p>
        <ul className="task-keys" aria-label="Keys for this widget">
          {task.keys.map((k) => (
            <li key={k}>
              <kbd>{k}</kbd>
            </li>
          ))}
        </ul>
      </div>
      <div className="task-widget">
        <Widget id={task.id} onComplete={onComplete} />
      </div>
    </section>
  )
}
