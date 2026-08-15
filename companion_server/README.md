# Antigravity Companion Server

The desktop half of the companion app. It is an **approval broker**: Antigravity
asks it for permission before running a tool, it asks your phone, and it holds
the agent still until you answer.

```
Antigravity agent
      │  PreToolUse hook (blocking)
      ▼
   hook.js  ──HTTP POST /api/v1/approvals (response deliberately parked)──▶  this server
                                                                                  │ WS push
                                                                                  ▼
                                                                             your phone
                                                                                  │ ALLOW / DENY
   hook.js  ◀────────────── {"decision":"allow"} ──────────────────────────────────┘
      │
      ▼
 agent proceeds (or doesn't)
```

## Setup

```bash
npm install
npm start
```

Then install the hook into a project you work on with Antigravity:

```bash
npm run install-hook -- --project /path/to/your/project
```

That writes `<project>/.agents/hooks.json`. Use `--global` to write
`~/.gemini/antigravity-cli/hooks.json` instead, and `--matcher "run_command"` to
gate only shell commands rather than every tool. Restart Antigravity afterwards
so it reloads the config.

Finally, scan the QR code the server prints. The token is stored in
`~/.antigravity-companion/token` and survives restarts — rotate it with
`npm run reset-token`, which un-pairs every phone.

## Configuration

| Variable | Default | What it does |
|---|---|---|
| `PORT` | `8765` | HTTP + WebSocket port |
| `BIND_ADDRESS` | `0.0.0.0` | Set to `127.0.0.1` to refuse LAN connections |
| `APPROVAL_TIMEOUT_MS` | `120000` | How long a tool call waits for you before falling back to the desktop prompt |
| `DEVICE_NAME` | hostname | Name shown on the phone |
| `ANTIGRAVITY_AGENT_CMD` | *(unset)* | Command used to start a headless agent run |
| `ANTIGRAVITY_AGENT_ARGS` | `["{instruction}"]` | JSON array of argv; `{instruction}` is substituted |
| `ANTIGRAVITY_COMPANION_HOME` | `~/.antigravity-companion` | Where the token and always-allow rules live |

## The fail-safe rule

Every error path resolves to `ask`, never `allow`:

| Situation | Result |
|---|---|
| You tap ALLOW / DENY | `allow` / `deny` |
| Nobody answers within `APPROVAL_TIMEOUT_MS` | `ask` — Antigravity shows its own card |
| Companion server not running | `ask` |
| No pairing token on disk | `ask` |
| Malformed hook payload | `ask` |
| STOP pressed on the phone | `deny`, for this and every following call |

So the worst case is that the app stops helping and Antigravity behaves exactly
as it does without it. The app can never silently approve something for you.

## Always-allow rules

`ALWAYS ALLOW` writes an exact `tool + full command` key to
`~/.antigravity-companion/rules.json`. It is exact-match on purpose: allowing
`npm install lodash` does **not** allow `npm install anything-else`. Review with
`GET /api/v1/rules`, wipe with `DELETE /api/v1/rules`, or hit PAUSE on the phone
to bypass all rules temporarily.

## API

Everything except `/health` requires `Authorization: Bearer <token>`. The
WebSocket takes the token as `?token=` on `/ws`.

| Method | Path | Used by |
|---|---|---|
| `GET` | `/api/v1/health` | phone (unauthenticated reachability probe) |
| `GET` | `/api/v1/status` | phone — full snapshot |
| `POST` | `/api/v1/approvals` | **hook.js — the blocking call** |
| `GET` | `/api/v1/approvals` | phone |
| `POST` | `/api/v1/approvals/:id/decide` | phone — `ALLOW_ONCE` / `ALWAYS_ALLOW` / `DENY` |
| `POST` | `/api/v1/activity` | hook.js (PostToolUse) |
| `POST` | `/api/v1/commands` | phone — start a headless run |
| `POST` | `/api/v1/agent/:action` | phone — `pause` / `resume` / `stop` / `retry` |
| `GET` | `/api/v1/projects`, `/devices`, `/history`, `/rules` | phone |
| `POST` | `/api/v1/projects/:id/select` | phone |
| `DELETE` | `/api/v1/rules` | phone |

WebSocket pushes: `INITIAL_STATE`, `AGENT_STATUS_UPDATED`, `NEW_APPROVAL_REQUEST`,
`APPROVAL_RESOLVED`, `ACTIVITY_ADDED`, `PROJECTS_UPDATED`, `DEVICES_UPDATED`,
`COMMAND_FAILED`. The phone sends actions over REST, not the socket.

## Hook output compatibility

The Antigravity docs specify `{"decision": "allow|deny|ask"}`; some CLI builds
read `{"allow_tool": bool, "deny_reason": string}`. The key sets are disjoint,
so `hook.js` emits both and exits 0 either way.

## Limitations worth knowing

- **Instructions start a new run, they don't steer a live one.** Antigravity has
  no inbound API for injecting a prompt into a session that is already going;
  hooks are outbound only. `POST /commands` spawns a fresh headless run via
  `ANTIGRAVITY_AGENT_CMD`. Without that variable set, the phone gets an explicit
  501 rather than a fake success.
- **No completion percentage exists.** The server reports `progress: 0` and the
  app draws an indeterminate bar. Nothing fabricates a number.
- **Plain HTTP on the LAN.** The token stops casual access on a shared network,
  but there is no TLS — anyone who can sniff your Wi-Fi can read the traffic.
  Don't run this on a network you don't trust, and use `BIND_ADDRESS=127.0.0.1`
  with an SSH tunnel if you need to be careful.
- **Risk levels are heuristics.** `lib/risk.js` pattern-matches known-dangerous
  commands to colour the card. It is a prompt for your attention, not a filter.

## Tests

```bash
npm test
```

`test/e2e.test.js` spawns the real `hook.js` against a real server and asserts
that it blocks, that a decision releases it, that a timeout degrades to `ask`,
and that a dead server never hangs the IDE.
