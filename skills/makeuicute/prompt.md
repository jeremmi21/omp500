---
name: makeuicute
description: >
  Make a local web UI show up properly, then make it effortless to get back to.
  A browser refuses cross-origin font, stylesheet and ES module loads over file://,
  so a UI opened by double-clicking its .html renders with the wrong fonts and dead
  modules; over http://localhost it renders exactly as authored. Modes:
  `makeuicute [path]` serves now and opens the browser;
  `makeuicute batmode [path]` freezes that host into `<build>/webui/` holding
  `serve.bat` (one double-click starts the host and opens Brave) and
  `<App Title>.txt` (the app title and its exact host link);
  `makeuicute ship` publishes to Vercel and wires the repo to GitHub so a push
  redeploys.
  Also `/makeuicute-batmode`, `/makeuicute-ship`.
  Use when a UI "looks broken locally", when custom fonts or modules silently fail
  to load, when the user wants a double-clickable way to view a build without typing
  terminal commands, when they want a local HTML/CSS/JS folder hosted, previewed,
  published, or made cute.
version: 1.0.0
priority: medium
---

# makeuicute

**One problem.** A UI opened from disk uses the `file://` protocol, whose origin is
opaque. Measured on Chromium 155 against a folder with a stylesheet, a font, a classic
script, a module script and a `fetch`:

| | `file://` | `http://localhost` |
|---|---|---|
| `<link rel=stylesheet>` | works | works |
| classic `<script src>` | works | works |
| `@font-face` with a sibling font file | works | works |
| `<script type="module">` | **never runs** | runs |
| `fetch()` / `XHR` | **blocked** | works |
| Web worker, `import()` | **blocked** | works |

So it is not "nothing loads". Relative CSS, classic scripts and fonts are fine. What
dies is everything that crosses an origin check — modules, `fetch`, workers — which is
exactly the modern half of a page. A page whose JS is a module renders its HTML with
**no interactivity at all**, and a font referenced from a parent directory rather than
the page's own folder is blocked too.

**One fix.** Serve it from `http://localhost`. Every origin check passes, modules
execute, `fetch` resolves. That is all this skill does — plus removing the terminal
from the loop.

## Modes

| Command | Does | Writes |
|---|---|---|
| `makeuicute [path]` | serves now, opens the browser, reports the URL | nothing |
| `makeuicute batmode [path]` | freezes the host into the build | `<build>/webui/` |
| `makeuicute ship` | Vercel deploy, optionally GitHub-wired | a line in the webui txt |

`path` defaults to the working directory. For batmode the working directory **is** the
build, and `webui/` lands inside it.

**Which host a build needs is a property of the build, not a preference.** A folder of
plain HTML/CSS/JS wants a static host. A project with its own dev server (Vite, Next,
Nuxt, Astro) must be run, never hosted — see batmode below for why, because the
failure is silent.

## Serve now — static content only

```bash
node <skill>/scripts/serve.mjs --root . --port 8300
```

It prints one line — `makeuicute: serving http://localhost:8300/ (root: …)` — then
holds the port until killed. Start it as a long-running process (not a foreground
bash call), read that line for readiness, then open the URL. Pick a free port; the
build's own dev server port may already be taken.

This is for a **static** folder: hand-written HTML, or a build's `dist/` output. If the
folder has a `package.json` with a `dev` script, it is a dev-server project — run
`npm run dev` instead (or `batmode`), because `serve.mjs` cannot transform its
sources.

Flags: `--host` (default `127.0.0.1` — loopback only, never the LAN), `--hide <name>`
to 404 a top-level entry, `--no-spa` to stop the `index.html` fallback.

**Do not substitute `python -m http.server`.** Python 3.13's `mimetypes` returns
`None` for `.woff2`, `.woff`, `.ttf` and `.otf`, so fonts are served as
`application/octet-stream`, and it has no SPA fallback — a built Vite or React app
404s on every client-side route. `serve.mjs` fixes both; both were verified on this
machine.

## Batmode — the frozen host

```bash
node <skill>/scripts/batmode.mjs --root . [--dev] [--serve <subdir>] [--script dev] [--title "<name>"] [--port <n>]
```

Writes `<build>/webui/`:

| File | What it is |
|---|---|
| `serve.bat` | the single launcher. Double-click it: the host starts in that window, the browser opens at the link. Closing the window stops it. |
| `server.mjs` or `devhost.mjs` | the helper for the detected flavor, copied in so `webui/` needs no install |
| `<App Title>.txt` | the app title and its exact host link |

**Two flavors, detected, never guessed:**

| Target | Flavor | What `serve.bat` does |
|---|---|---|
| `package.json` with a `dev` script | **dev** | runs `npm run dev`, waits for the URL the dev server prints, opens the browser there |
| `index.html`, no dev script | **static** | runs the copied `server.mjs` over the folder |
| neither | — | **refuses**, and says where to point it |

Precedence is `--dev` → explicit `--serve <subdir>` → dev script → `index.html` →
refuse. A project with its own dev server wins over a static host, because its root
`index.html` is a template *for that server*, not a deployable page.

**Placement.** `webui/` lands in `--root`. `--dir <path>` puts it elsewhere: with
`--root measurer --dir ../webui` the launcher sits at the workspace root while the
project it runs is the subfolder — the right arrangement when one workspace holds
several projects and only one of them is the build. `serve.bat` resolves the project
relatively (`cd /d "%~dp0..\measurer"`), so the pair stays portable together.

**Never statically host a dev-server project.** This is the failure that looks like
success: a Vite `index.html` loads `/src/main.tsx`, the static host serves that file
verbatim with a `200` and `text/javascript`, and the browser cannot parse it —
`import.meta.env.DEV`, a TS non-null assertion, a bare `import("mesurer")`. The
document loads with the right `<title>`, `<div id="root">` stays **empty**, and the
network tab shows nothing wrong. Vite's own server transforms the same path into
`import.meta.env = {…}`, compiled JSX and rewritten specifiers. batmode warns loudly if
you force `--serve` onto a page that loads a `.ts`/`.tsx`/`.jsx`/`.vue`/`.svelte`
module.

The port is **frozen** at generation time so the link in the txt stays true — derived
stably from the folder name and probed upward for the static flavor; read from
`--port N` in the dev script or `server.port` in `vite.config.*` for the dev flavor.
The title comes from `index.html`'s `<title>`, then `package.json`'s `name`, then the
folder name. The launcher finds Brave in Program Files, Program Files (x86) or
LocalAppData, and falls back to the default browser.

Windows only. The artifact is a `.bat`; a POSIX launcher would be a different artifact
with different semantics, so it is not guessed at.

## Ship — Vercel and GitHub

```bash
node <skill>/scripts/ship.mjs --root . --name <slug> [--temporary|--prod] [--github] [--yes]
```

Dry by default: prints the resolved plan and the auth state it found, runs nothing.
`--yes` executes. `--temporary` gives a claimable preview URL; `--prod` links a
project, deploys production, and with `--github` runs `vercel git connect` so every
push redeploys.

**Every Vercel deploy needs credentials, `--temporary` included.** The CLI's own
logged-out hint advertises `--temporary` as the no-login path; Vercel CLI 59.3.0
rejects it with `No existing credentials found`. Verified on this machine. The real
options:

- `vercel login` once — interactive, opens a browser. Then everything works.
- `--token <VERCEL_TOKEN>` for a non-interactive run.
- No account at all: drag the folder onto `https://vercel.com/drop` in a browser. That
  is a web UI, not a CLI path, and the skill cannot automate it.

GitHub is already authenticated on this machine via `gh` (account `jeremmi21`, `repo`
scope), so `--github` needs nothing new. Creating a repo and pushing is a real,
hard-to-undo account action: show the plan and get a go-ahead before `--yes`.

## What to verify before reporting success

- **Serve**: the readiness line appeared, `curl -s -o /dev/null -w "%{http_code}"` on
  the URL returns 200, and the page's `<title>` matches the build.
- **Batmode**: run the generated `serve.bat` itself, not a hand-rolled node command.
  Then load the page and check the app root has children — `#root` empty with a
  correct `<title>` is the exact signature of a source tree served statically, and a
  browser window title alone will not catch it.
- **Ship**: dry-run first; never `--yes` against a repo you have not shown the user.

## Never pick the target for the user

`--root` is the build. Do not go hunting for a subproject that happens to have an
`index.html` and host that instead — say the root has nothing to host and ask, or pass
`--serve` only when the user named the subfolder. Hosting an arbitrary sibling folder
under the user's build is worse than hosting nothing.

## Rendering a web UI *inside* the terminal

Short answer: don't. WezTerm renders text and inline images; it cannot render HTML,
CSS or JavaScript. `wezterm imgcat` can display a screenshot, which is a still,
non-interactive picture — strictly worse than the browser window `serve.bat` already
opens. The long answer, including gpuix and the real terminal-browser options, is in
`references/tui.md`.
