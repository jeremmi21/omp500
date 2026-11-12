# browser-relay — OMP Browser Relay (vendored)

**Structure.** `browser-relay/extension/` is a verbatim copy of the extension the `omp` CLI writes to
`~/.omp/browser-relay/extension`. It is loaded into Brave/Chrome as an *unpacked* extension, connects
to a local relay over `ws://127.0.0.1:<port>/ext`, and gives the omp agent CDP control of your own tabs.

**Constraints.** Manifest V3. The extension is first-party code shipped inside `omp` (MIT, © Mario
Zechner / Can Bölük / Stencil Labs, Inc.) — do not edit `background.js`, it is bundled output. Never put a
relay `--token` in this repo. `THIRD-PARTY-NOTICES.txt` is the release-wide aggregate that ships with
`omp`; it is kept here only so the copy stays byte-identical to the artifact.

**Success.** `brave://extensions` lists **OMP Browser Relay 18.19.0** as enabled, the relay log says
`Extension connected.`, and `netstat` shows an `ESTABLISHED` loopback connection to the relay port.

Pinned to omp `18.19.0` (`manifest.json` → `version_name`). `version_name` MUST equal the installed
`omp` version — the relay protocol is versioned and silently refuses a skewed extension.

| file | role |
|---|---|
| `manifest.json` | MV3 manifest; permissions `debugger`, `tabs`, `tabGroups`, `storage`, `alarms`, `scripting`, `downloads`; host `<all_urls>` |
| `background.js` | service worker: relay socket (`ws://127.0.0.1:<port>/ext?token=…`), CDP attach/detach, download pairing, `omp` tab group |
| `options.html` / `options.js` | port (default **9224**) + token; must match the relay's `--port` / `--token` |
| `LICENSE` | MIT |

## Reinstall (agent-runnable)

Renewing a device means three things: the relay process runs, the browser has the extension loaded
from a stable path, and both agree on port/token. Steps in order — stop at the first failure.

### 1. Check the CLI and the relay

```bash
omp --version                      # expect 18.19.0+; the extension pins that version
omp browser-relay --help           # ACTION: serve | install, default serve
```

Turn the relay on permanently (it then runs as a daemon at
`~/.omp/run/daemons/global/browser-relay/`):

```bash
omp config set browser.relay true
```

Or run it by hand for one session — background it, it blocks:

```bash
omp browser-relay --port 9224 &    # add --token <secret> if you want auth
```

### 2. Load the extension

Preferred: let the CLI write the extension itself, then load *its* path.

```bash
omp browser-relay install          # writes ~/.omp/browser-relay/extension + prints setup steps
omp browser-relay install --dir /abs/path/to/ext   # or target another folder
```

Use **this repo's copy** when `omp` is absent or you need the exact pinned build — the directory is
already install-ready:

```
<clone>/omp500/browser-relay/extension
```

Then, in the browser (the only manual step — current Chromium removed the `--load-extension` switch,
so no agent can do it headlessly):

1. `brave://extensions` (or `chrome://extensions`).
2. Enable **Developer mode**.
3. **Load unpacked** → select `browser-relay/extension` (a directory holding `manifest.json`).
4. Confirm the card reads **OMP Browser Relay**, enabled, service worker present.

Re-loading after an update: **Reload** on the card, or *Load unpacked* again on the same path —
Chromium keys unpacked extensions by absolute path, so keep the clone in place.

### 3. Align port and token

Click the toolbar icon → options. `Relay port` must equal the relay's `--port` (default **9224**);
`Token` must equal `--token`, or stay empty when the relay was started without one. A mismatch does
not error — the socket just never becomes usable.

### 4. Verify

```bash
# Windows
netstat -ano | findstr 9224
# macOS/Linux
lsof -nP -iTCP:9224 -sTCP:LISTEN
```

- Listening on `127.0.0.1:9224` → relay up.
- At least one `ESTABLISHED` loopback connection → extension connected.
- Relay log (daemon mode): `~/.omp/run/daemons/global/browser-relay/daemons/omp.browser.relay/output.log`
  must contain `browser relay listening on http://127.0.0.1:9224` and
  `Extension connected. The omp browser prelude can now drive your tabs.`

If the log still says `Waiting for the OMP Browser Relay extension to connect`, the extension is not
loaded, is disabled, or is pointing at another port.

## Troubleshooting

| symptom | fix |
|---|---|
| log: `Waiting for … extension to connect` | extension not loaded / disabled / wrong port — redo steps 2–3 |
| two relays, tab control flaky | old `omp browser-relay` still bound to 9224 (`netstat` shows the PID); kill it before starting another |
| everything worked, then stopped after an `omp` upgrade | `version_name` skew — reload the extension from the upgraded `omp browser-relay install` path |
| `Invalid value for manifest version` / card greyed out | you pointed *Load unpacked* at the repo root; select `browser-relay/extension` |
| token rejected / socket closes instantly | options token ≠ relay `--token`; clear both to disable auth |
| tabs get an `omp` group you don't want | start the relay with `--no-group` |

## Security

`debugger` + `<all_urls>` means the extension can read, navigate, and inject into **every** tab in the
profile, and `--token` is the only gate on the local socket. Load it in a profile you'd let an agent
drive, disable it when you're done, and keep the relay bound to `127.0.0.1` (never `0.0.0.0`).
