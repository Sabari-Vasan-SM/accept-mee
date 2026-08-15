# Antigravity Companion

Approve your Antigravity AI agent's tool calls from your phone.

When the agent on your desktop wants to run `rm -rf`, install a dependency, or
apply a migration, a card appears on your phone with the exact command and a
risk badge. The agent **waits** until you tap ALLOW ONCE, ALWAYS ALLOW, or DENY.

This works through Antigravity's blocking `PreToolUse` hook — it is a real
integration, not a simulation. There is no mock mode: if the desktop isn't
reachable the app tells you so.

---

## How it works

```
Antigravity agent
      │  PreToolUse hook (blocks)
      ▼
   hook.js  ──▶  companion_server :8765  ──WebSocket──▶  phone
                          ▲                                │
                          └────── ALLOW / DENY ◀───────────┘
```

The hook POSTs the tool call to the companion server, which parks the HTTP
response and pushes the request to your phone. Your tap resolves the parked
response, the hook prints `{"decision":"allow"}`, and the agent continues.

**If anything goes wrong — server down, no answer in time, bad token — the hook
returns `ask`, and Antigravity falls back to its own approval card.** The app
can never silently approve something on your behalf.

---

## Setup

### 1. Desktop

```bash
cd companion_server && npm install && npm start
```

```bash
cd companion_server && npm run install-hook -- --project /path/to/your/project
```

Restart Antigravity so it picks up `.agents/hooks.json`.

### 2. Phone

```bash
flutter pub get && flutter run
```

Scan the QR code the server printed. Phone and desktop must be on the same
network — there is no relay.

---

## Screens

| Screen | What it shows |
|---|---|
| **Dashboard** | Agent status, urgent approvals, quick command grid, mic button |
| **Approvals** | The queue, with risk badges, the exact command, working directory, and diffs |
| **Live Activity** | Real tool calls as they happen, from the PostToolUse hook |
| **Quick Commands** | One-tap instructions (requires `ANTIGRAVITY_AGENT_CMD`, see below) |
| **Voice** | Speak an instruction, review the transcript, dispatch |
| **Projects** | Workspaces the agent has actually touched, with live git branch |
| **Devices** | This desktop and every paired phone |
| **Settings** | Host/port, pairing state, biometrics, haptics |

---

## What is real, and what isn't

Being straight about this, because the previous version of this README wasn't.

**Real:**

- The approval flow end to end. The agent genuinely blocks.
- Risk classification, secret masking, and always-allow rules (exact-match,
  persisted to `~/.antigravity-companion/rules.json`).
- Token authentication on every REST call and the WebSocket.
- Activity, projects, and git branches — all derived from real hook traffic.
- STOP, which denies everything queued and everything that follows.

**Configuration required:**

- **Instructions and quick commands.** Antigravity offers no way to inject a
  prompt into an already-running session, so these start a *new* headless run.
  Set `ANTIGRAVITY_AGENT_CMD` / `ANTIGRAVITY_AGENT_ARGS` for the server to know
  how. Unset, the phone shows an explicit error rather than a fake success.

**Still stubs:**

- **Biometric lock** — the toggle is stored but `SecurityService` always returns
  true. Wiring it up needs the `local_auth` package.
- **Speech-to-text** — `SpeechService` is a timer-driven fake. No STT package is
  installed; the waveform is generated.
- **Push notifications** — in-app only. Nothing reaches a locked phone yet; that
  needs FCM/APNs.

**Security posture:** plain HTTP/WS on your LAN, protected by a bearer token. No
TLS. Fine for a home network, not for a café. Use `BIND_ADDRESS=127.0.0.1` plus
an SSH tunnel if you need more.

---

## Tests

```bash
flutter test
```

```bash
cd companion_server && npm test
```

The server suite includes an end-to-end test that spawns the real hook against a
real server and asserts it actually blocks.

---

## Docs

- [`AGENTS.md`](AGENTS.md) — architecture and conventions, for humans and agents
- [`companion_server/README.md`](companion_server/README.md) — API, config, hook contract
