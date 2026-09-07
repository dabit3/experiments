# realtime-chat — "Relay"

Relay is a Slack-style chat room that runs entirely in memory: a ~200-line Node
WebSocket server (`ws`) fans every event out to a Vite + React + TypeScript
client. Pick a display name and avatar color, then hop between `#general`,
`#random` and `#devin` — each room keeps its own history and shows an unread
badge when someone posts while you're elsewhere. Messages carry timestamps and
can be edited or deleted by their author (everyone sees the change live), hover
any message to add an emoji reaction, and the composer broadcasts a
"Nader is typing…" indicator. A live "Online" panel shows who is connected and
which room they're in, and system messages announce joins and leaves.

## Run it

```bash
cd realtime-chat
npm install
npm run dev
```

`npm run dev` uses [`concurrently`](https://github.com/open-cli-tools/concurrently)
to start both halves:

| Script           | What it does                                                            |
| ---------------- | ----------------------------------------------------------------------- |
| `npm run server` | WebSocket server on `ws://127.0.0.1:3001/ws` (`tsx watch server/index.ts`) |
| `npm run web`    | Vite dev server on `http://localhost:5173`, proxying `/ws` to the server |
| `npm run dev`    | Both of the above, in one terminal                                      |
| `npm run smoke`  | Protocol smoke test: two headless clients replay the whole scenario     |
| `npm run build`  | Type-check every project (`client`, `server`, `shared`) and build the client |
| `npm run lint`   | `oxlint`                                                                |

Open `http://localhost:5173` in two tabs (or two browsers) to see it in action.

The server binds to `127.0.0.1` and honours `PORT` (default `3001`) and `HOST`;
the Vite dev server honours `WEB_PORT` (default `5173`) and proxies the
WebSocket to whatever `PORT` is, so the client never needs to know the server
address. `GET /health` returns `{ ok, online }` for readiness checks. Set
`VITE_WS_URL` to point the client at a server that isn't behind the proxy.

## How it's put together

```
shared/protocol.ts   Room list, reaction set, and the ClientEvent / ServerEvent unions
server/index.ts      In-memory users + per-room history, broadcast helpers, event handlers
src/lib/useChat.ts   WebSocket hook: reducer over ServerEvent, auto-reconnect, unread counts
src/components/      JoinScreen, Sidebar (rooms + badges), MessageList/MessageItem
                     (hover toolbar, emoji picker, inline edit), Composer (typing), OnlineList
```

Everything the client and server exchange is a typed JSON event from
`shared/protocol.ts`, so the two sides can't drift. The server is the source of
truth: clients send intents (`message`, `edit`, `react`, …) and render whatever
comes back, which is what keeps two tabs perfectly in sync.

Reaction emoji are rendered from bundled [Twemoji](https://github.com/jdecked/twemoji)
SVGs (CC-BY 4.0) so they look identical on every platform.

## Computer-use showcase

<!-- SHOWCASE:START -->
_Recording and screenshots are added after the browser test run._
<!-- SHOWCASE:END -->
