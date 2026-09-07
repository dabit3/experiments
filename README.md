# experiments

Ten small apps, each built and then tested end-to-end in a real browser by Devin.
Every app is picked to stress a different kind of computer use: drag-and-drop,
freehand drawing, keyboard-driven editing, real-time games, file uploads,
context menus, multi-tab coordination, and more.

Each app lives in its own top-level directory with its own README describing the
app and the browser test scenario, plus the recording of Devin running it.

| Directory | App | Computer-use skill it showcases |
|-----------|-----|---------------------------------|
| `kanban-board/` | Drag-and-drop Kanban board | Mouse press/drag/release, reordering, multi-column DnD |
| `pixel-painter/` | Canvas drawing app | Precise freehand mouse paths + visual verification |
| `shop-checkout/` | Multi-step e-commerce checkout | Long forms, validation errors, multi-page state |
| `mini-sheets/` | Spreadsheet with formulas | Keyboard navigation, shortcuts, formula entry |
| `snake-arcade/` | Snake game | Real-time arrow-key control, reading live game state |
| `block-editor/` | Notion-style rich text editor | Text selection, shortcuts, slash commands, undo/redo |
| `metrics-dashboard/` | Interactive analytics dashboard | Hover tooltips, sliders, chart zoom/pan, filters |
| `photo-crop/` | Image crop & filter tool | File upload dialog, drag handles, file download |
| `week-planner/` | Calendar with drag-to-create events | Drag-to-create, resize, right-click menus, modals |
| `realtime-chat/` | WebSocket chat room | Two browser tabs acting as two users in sync |
