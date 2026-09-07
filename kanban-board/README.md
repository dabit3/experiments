# kanban-board

A Trello-style Kanban board built with Vite, React and TypeScript. Four columns
(Backlog, In Progress, Review, Done) hold nine seeded cards with colored labels
and assignee avatars. Cards can be reordered within a column or moved across
columns with real pointer drag-and-drop (powered by
[@dnd-kit](https://dndkit.com/)): the dragged card lifts and follows the cursor,
a dashed drop-placeholder marks where it will land, the target column highlights,
and every column shows a live card count. Each column has an "Add a card" input,
clicking a card opens a detail modal (title, description, labels, assignee,
delete), and the whole board is persisted to `localStorage` so it survives a
refresh. A "Reset board" button restores the seed data.

![Seed board](docs/01-seed-board.jpg)

## Run it

```bash
cd kanban-board
npm install
npm run dev
```

Then open http://localhost:5173. Other scripts: `npm run build`, `npm run lint`.

## Computer-use showcase

Devin opened the app in a maximized Chrome window and drove it with real mouse
press / move / release events (no synthetic DnD events), asserting each result
visually. All six steps passed on the first recorded run.

**Recording:** [kanban-showcase-edited.mp4](https://app.devin.ai/attachments/6d8105bf-7d8a-430c-9683-8fdf0d4de500/kanban-showcase-edited.mp4) (1 min, annotated)

1. **Drag across columns and check counts** — dragged KB-4 "Fix login redirect
   bug" from Backlog and dropped it between the two In Progress cards. Backlog
   count went 4 → 3 and In Progress 2 → 3. While held, the lifted card follows
   the cursor, the original slot becomes a dashed placeholder and the target
   column is outlined:

   ![Card mid-drag with placeholder and highlighted target column](docs/02-mid-drag.jpg)

2. **Reorder within a column** — dragged the bottom Backlog card (KB-3 "Write
   API documentation") up to the top slot; Backlog order became KB-3, KB-1, KB-2.

   ![Backlog reordered](docs/03-reordered-backlog.jpg)

3. **Drag across three columns in one motion** — pressed KB-1 "Set up CI
   pipeline" in Backlog and, in a single press-move-release, carried it past In
   Progress and Review into Done. Backlog 3 → 2, Done 2 → 3.

   ![KB-1 dropped in Done after crossing three columns](docs/04-cross-three-columns-drop.jpg)

4. **Add a card and drag it** — typed "Ship release notes" into Backlog's
   "Add a card…" input and pressed Enter (new card KB-10 appeared at the bottom
   of Backlog), then dragged it into Review above KB-7. Review 1 → 2.

5. **Edit in the modal** — clicked KB-5 "Implement dark mode" to open its
   detail modal, changed the title to "Implement dark mode (v2)", clicked Save,
   and confirmed the card on the board shows the new title.

   ![Modal with edited title](docs/05-edited-title-modal.jpg)

6. **Persistence** — pressed F5. Counts were still Backlog 2 / In Progress 3 /
   Review 2 / Done 3, KB-1 was in Done, KB-10 in Review and KB-5 kept its edited
   title, all restored from `localStorage`.

   ![Board after refresh](docs/06-final-board-after-refresh.jpg)
