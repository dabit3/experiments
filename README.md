# experiments

Ten small apps, each built and then tested end-to-end in a real browser by Devin.
Every app is picked to stress a different kind of computer use: drag-and-drop,
freehand drawing, keyboard-driven editing, real-time games, file uploads,
context menus, multi-tab coordination, and more.

Each app lives in its own top-level directory with its own README describing the
app and the browser test scenario, plus the recording of Devin running it.

| Directory | App | Computer-use skill it showcases | PR | Recording |
|-----------|-----|---------------------------------|----|-----------|
| `kanban-board/` | Drag-and-drop Kanban board | Mouse press/drag/release, reordering, multi-column DnD | [#3](https://github.com/dabit3/experiments/pull/3) | [watch](https://app.devin.ai/attachments/895ab452-c188-4f45-8603-79334ee4b3d4/kanban-showcase-edited.mp4) |
| `pixel-painter/` | Canvas drawing app | Precise freehand mouse paths + visual verification (draws a house, writes "DEVIN") | [#1](https://github.com/dabit3/experiments/pull/1) | [watch](https://app.devin.ai/attachments/7025b1bc-f963-487f-9b19-c976f1d1d0ba/pixel-painter-showcase-edited.mp4) |
| `shop-checkout/` | Multi-step e-commerce checkout | Long forms, validation errors, Luhn card check, multi-page state | [#6](https://github.com/dabit3/experiments/pull/6) | [watch](https://app.devin.ai/attachments/c0a70c26-0aad-4173-8002-cfa80760064f/northwind-checkout-showcase-edited.mp4) |
| `mini-sheets/` | Spreadsheet with formulas | Keyboard-only navigation, shortcuts, fill-down, relative copy/paste | [#5](https://github.com/dabit3/experiments/pull/5) | [watch](https://app.devin.ai/attachments/83bc563a-b760-489d-a674-d914d11c3c84/mini-sheets-keyboard-showcase.mp4) |
| `snake-arcade/` | Snake game | Real-time arrow-key control, reading live game state (reaches score 8) | [#2](https://github.com/dabit3/experiments/pull/2) | [watch](https://app.devin.ai/attachments/7617956b-2423-4ce1-9e45-dbb63ec54cd7/snake-arcade-devin-playthrough.mp4) |
| `block-editor/` | Notion-style rich text editor | Text selection, shortcuts, slash commands, block drag, undo/redo | [#9](https://github.com/dabit3/experiments/pull/9) | [watch](https://app.devin.ai/attachments/7d370072-a0da-4384-8874-c706e610d907/block-editor-demo-edited.mp4) |
| `metrics-dashboard/` | Interactive analytics dashboard | Hover tooltips, drag-to-zoom charts, range sliders, filters | [#4](https://github.com/dabit3/experiments/pull/4) | [watch](https://app.devin.ai/attachments/5a28ff3e-411a-498c-aad7-646bbbf1d677/metrics-dashboard-showcase-edited.mp4) |
| `photo-crop/` | Image crop & filter tool | Native file-chooser upload, drag handles, file download round-trip | [#7](https://github.com/dabit3/experiments/pull/7) | [watch](https://app.devin.ai/attachments/663e37e8-c4cb-4f7e-a42a-291a75f7cdc8/photo-crop-showcase-edited.mp4) |
| `week-planner/` | Calendar with drag-to-create events | Drag-to-create, resize, right-click menus, modals | [#10](https://github.com/dabit3/experiments/pull/10) | [watch](https://app.devin.ai/attachments/3c49973b-72c2-4836-8247-1f621460452d/week-planner-showcase-edited.mp4) |
| `realtime-chat/` | WebSocket chat room | Two browser tabs acting as two users in sync | [#8](https://github.com/dabit3/experiments/pull/8) | [watch](https://app.devin.ai/attachments/2c95a9eb-3a7f-447b-8c8d-3aa4fe2bf421/relay-two-users-showcase-edited.mp4) |

## Running an app

```sh
cd <directory>
npm install
npm run dev
```
