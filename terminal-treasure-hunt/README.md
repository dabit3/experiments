# Terminal Treasure Hunt

A fake Unix shell that runs entirely in the browser, built with Vite + React + TypeScript. There
is no real shell and no backend: the terminal is a hidden `<input>` behind a hand-rendered prompt
and caret, the filesystem is an in-memory tree of 52 files and directories, and every command is
implemented in TypeScript. Hidden somewhere in `~` is a `FLAG{...}`; `README.txt` gives the first
clue and each clue leads to the next through hidden dotfiles, a recursive grep across log files,
a base64-encoded file, and a file that only `ls -a` will show. `submit <flag>` checks the answer
and, when it is right, plays ASCII-art fireworks.

Commands: `ls` (`-l`, `-a`, `-la`), `cd`, `pwd`, `cat`, `grep` (`-r`, `-i`, `-n`, `-v`),
`find` (`-name`, `-type`), `echo`, `base64` (`-d`), `head`/`tail` (`-n`), `wc`, `tree`,
`history`, `clear`, `help`, `man <cmd>`, `submit`, `whoami`, `hostname`, `date`. Pipes (`|`),
`&&`, `;`, quotes, `~`, globs, tab completion (commands and paths) and `↑`/`↓` history all work.
`Ctrl+L` clears, `Ctrl+C` abandons the current line.

Everything is deterministic: the filesystem, log contents, flag, fireworks frames and timings are
fixed, so the same sequence of commands always produces the same output.

## Run it

```bash
cd terminal-treasure-hunt
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. `npm run build` type-checks and produces a
static bundle in `dist/`; `npm run lint` runs oxlint.

## Computer-use showcase

This app exists to demonstrate Devin **typing shell commands into a browser terminal and reading
dense text output** — long directory listings, dozens of grep hits with the match highlighted,
base64 blobs — to work out what to type next. After building it, Devin opened the app in Chrome,
maximized the window, and performed the following scenario end to end while recording, using
only the keyboard inside the terminal:

1. Start at `~`. `cat README.txt` → clue #1 says a hidden directory lives in `~`.
2. `ls -la` → the long listing reveals `.hunt/` (plus `.bashrc` / `.profile`).
3. `cat .hu<Tab>` completes to `.hunt/`, `<Tab>` again completes `note.txt` → clue #2 says a
   worker process logged the vault key's location somewhere under `var/log` with inconsistent
   capitalisation.
4. `grep -ri vault var/log` → a dense page of matches across `auth.log`, `syslog`, `nginx/*` and
   `app/*`; the `app/worker.log` line reads `VAULT key copied to projects/archive/deep/deeper/key.b64`.
5. `cat projects/archive/deep/deeper/key.b64` shows a base64 blob; `↑` recalls the command and
   it is edited to `base64 -d projects/archive/deep/deeper/key.b64` → clue #4: the real file in
   `~/projects/vault` is hidden.
6. `cd ~/projects/vault && ls -a` → `.flag` appears next to the decoys `decoy.txt` and `README`.
7. `cat .flag` → `FLAG{gr3p_th3_l0gs_d3c0de_th3_d0ts}`.
8. `submit FLAG{n1ce_try_th1s_1s_a_dec0y}` (from `decoy.txt`) → red `✗ Wrong flag`.
9. `submit FLAG{gr3p_th3_l0gs_d3c0de_th3_d0ts}` → ASCII fireworks, a **TREASURE FOUND!** banner,
   the flag in a gold chip, the clue tracker in the title bar reads **SOLVED**.

Expected results: the clue tracker fills one pip per clue (5/5 before submission), every command
above produces the output described, the wrong flag is rejected without ending the game, and the
right flag triggers the fireworks animation followed by the banner.

### Recording

**[Watch the full recording (mp4)](RECORDING_URL_PLACEHOLDER)**

![Animated preview of the recording](docs/showcase.webp)

## Project layout

```
src/
  App.tsx                     mounts the terminal
  components/
    Terminal.tsx              input handling, history, tab completion, scrollback, status bar
    OutputLines.tsx           renders styled output spans
    Fireworks.tsx             frame-stepped ASCII fireworks + banner
  shell/
    filesystem.ts             in-memory tree, clue chain, path helpers
    shell.ts                  command implementations, pipes, completion, submit
    parse.ts                  tokenizer, pipelines, flag parsing, globs
    output.ts                 styled line/span types and grep highlighting
    man.ts                    man pages / help text
    fireworks.ts              deterministic fireworks frames and ASCII art
```
