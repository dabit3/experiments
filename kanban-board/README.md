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

## Run it

```bash
cd kanban-board
npm install
npm run dev
```

Then open http://localhost:5173. Other scripts: `npm run build`, `npm run lint`.

## Computer-use showcase

Devin opened the app in a real browser and drove it with actual mouse
press / move / release events (no synthetic DnD events). Step by step:

1. **Drag across columns and check counts** — dragged "Fix login redirect bug"
   from Backlog into In Progress; Backlog count went 4 → 3 and In Progress
   2 → 3.
2. **Reorder within a column** — dragged the bottom Backlog card up to the top
   slot and confirmed the new order.
3. **Drag across three columns in one motion** — picked up a Backlog card and
   carried it past In Progress and Review into Done in a single press-move-release,
   watching the placeholder and highlighted column follow the cursor.
4. **Add a card and drag it** — typed a title into Backlog's "Add a card" input,
   pressed Enter, then dragged the freshly created card into Review.
5. **Edit in the modal** — clicked a card to open its detail modal, changed the
   title, saved, and asserted the card on the board shows the new title.
6. **Persistence** — refreshed the page and asserted the moved, added and edited
   cards were all still in place (state lives in `localStorage`).

### Recording

_Recording link will be added once the browser test run is complete._

### Screenshots

_Screenshots will be added once the browser test run is complete._
