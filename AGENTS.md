# AGENTS.md — accept-mee (Antigravity Companion)

Context for AI agents working on this repo. Read this before changing code.

> Naming note: the folder is `accept-mee`, but the Dart package, app title, and
> IntelliJ module are all **`antigravity_companion`**. Imports in tests use
> `package:antigravity_companion/...`. Don't "fix" the mismatch.

## What this is

A phone app that approves an Antigravity AI agent's tool calls. The desktop
agent **blocks** on a `PreToolUse` hook until you tap ALLOW or DENY on your
phone. This is a real integration with Antigravity's hook system, not a demo.

| Path | What it is |
|---|---|
| `lib/` | Flutter app (iOS, Android, web, macOS, Linux, Windows scaffolds) |
| `companion_server/` | Node broker + the hook binary, port **8765** |

## Run it

```bash
cd companion_server && npm install && npm start
```

```bash
cd companion_server && npm run install-hook -- --project /path/to/project
```

```bash
flutter pub get && flutter run
```

```bash
flutter test && flutter analyze
```

```bash
cd companion_server && npm test
```

Pairing tokens persist in `~/.antigravity-companion/token`, so a server restart
no longer un-pairs the phone. `npm run reset-token` rotates it deliberately.

## The core mechanism — understand this before touching anything

```
Antigravity → hook.js (PreToolUse) → POST /api/v1/approvals
                                            ↓ response is PARKED, not sent
                                       broker._pending
                                            ↓ WS NEW_APPROVAL_REQUEST
                                          phone
                                            ↓ POST /approvals/:id/decide
                                     broker.decide() resolves the promise
                                            ↓
                              parked response finally sends {"decision":"allow"}
                                            ↓
                                  hook prints it, agent proceeds
```

The parked HTTP response **is** the blocking mechanism. `companion_server/lib/broker.js`
holds a `Map` of pending `{request, resolve, timer}`. Anything that resolves one
of those promises releases a real agent on the desktop.

Consequences to keep in mind:

- `broker.submit()` returns `{requestId, promise}`, not a bare promise — the
  route needs the id synchronously so `req.on('close')` can abandon the request
  when the hook process dies.
- The pending timeout is **deliberately not `unref`'d**. While a request is
  pending we're blocking someone's IDE; the process must stay alive to answer.
- `server.requestTimeout = 0` in `index.js`. Node would otherwise kill a parked
  request.

## The fail-safe rule — do not weaken this

Every error path resolves to **`ask`** (Antigravity shows its own card), never
`allow`. Timeout, dead server, missing token, malformed payload: all `ask`.
`hook.js` self-times-out two seconds inside the `hooks.json` timeout so it gets
to print `ask` rather than being killed silently.

If you add a code path that can produce a decision, it must not be able to
produce `allow` without a human tap or a previously saved exact-match rule.

## Antigravity's hook contract

Configured in `<project>/.agents/hooks.json` or `~/.gemini/antigravity-cli/hooks.json`.
`install-hook.js` writes it and merges rather than clobbering.

Input on stdin: `{conversationId, workspacePaths[], transcriptPath, modelName}`
plus, for PreToolUse, `{toolCall: {name, args}, stepIdx}`.

Output on stdout: the docs specify `{"decision": "allow|deny|ask|force_ask|deny_unless_prior_grant"}`,
but some CLI builds read `{"allow_tool": bool, "deny_reason": string}`. **The key
sets are disjoint, so `hook.js` emits both.** Always exit 0 — a non-zero exit
reads as a hook failure, not a decision.

Arg names differ per tool, so `lib/toolmap.js` probes candidate keys
(`command`/`cmd`/`script`, `path`/`file`/`filePath`/…) rather than assuming one
schema. An unknown tool still yields a reviewable card.

## Server layout

```
companion_server/
  index.js            express + ws wiring, routes, derived agent state
  hook.js             the hook binary — dependency-free, runs per tool call
  install-hook.js     writes/merges hooks.json
  lib/broker.js       pending approvals, the parked promises, stop/pause modes
  lib/toolmap.js      Antigravity toolCall → PermissionRequest
  lib/risk.js         risk heuristics + secret masking
  lib/rules.js        persisted exact-match always-allow grants
  lib/projects.js     real workspaces + git branch, from hook payloads
  lib/activity.js     rolling log of real events
  lib/agent_runner.js spawns headless runs for instructions
  lib/auth.js         persisted token, constant-time compare
  lib/paths.js        ~/.antigravity-companion
```

`index.js` only calls `start()` when `require.main === module`, so tests import
the wiring and listen on an ephemeral port.

## Conventions

- **State**: `flutter_riverpod` 2.x, no codegen. `StreamProvider` for anything
  from the client, `StateNotifierProvider` for local state. `SettingsState` uses
  `copyWith` (it used to rebuild every field by hand — don't go back).
- **Models**: hand-written `fromJson`/`toJson` with defensive defaults
  (`as String? ?? 'fallback'`). No freezed, no json_serializable. The server may
  omit fields; match this style.
- **Transport direction**: the phone sends **actions over REST** so it gets real
  status codes, and the **WebSocket is inbound only**. An earlier version sent
  everything over both and ignored both results. Don't reintroduce that.
- **Errors**: `AntigravityClient.errorStream` carries human-readable failures;
  `AppShell` listens once and shows a snackbar. Don't add per-screen try/catch.
- **Auth**: every REST call carries `Authorization: Bearer <token>`; the WS
  carries `?token=`. Only `/health` is unauthenticated.
- **Theme**: dark only, Material 3, solid colors, no gradients. Colors from
  `AppColors`, text from `AppTypography` (Google Fonts — network on first run).
- **Lints**: `flutter_lints` 6, Dart SDK `^3.12.2`.
- **Secrets**: anything the agent authored passes through `risk.sanitize()`
  before it reaches a phone screen. Keep that on any new field you surface.

## Deliberately absent

There is **no mock client**. `AntigravityMockClient` and `triggerDemoScenario`
were deleted along with the seeded server state — the app now shows a real
disconnected state instead of fabricating one. `test/support/fake_client.dart`
is a test double for widget tests only; nothing in `lib/` can reach it.

Also gone: the `useMockClient` setting, the "Trigger … Approval" buttons, and
the Quick Pair button with its hardcoded `test_token_quick_pair`.

## Still stubs — don't assume these work

- `SecurityService.authenticateBiometric` always returns `true` after 300 ms.
  No `local_auth` dependency. The Settings toggle gates nothing.
- `SpeechService` is a `Random`-and-timers fake; no STT package is installed.
- `NotificationService` is in-app only. No FCM/APNs — nothing fires when the app
  is backgrounded, which still undercuts the whole point of an approval alert.
  This is the most valuable thing left to build.

## Known limits

- **Instructions can't steer a live session.** Antigravity has no inbound API
  for that; hooks are outbound only. `POST /commands` spawns a *new* headless
  run via `ANTIGRAVITY_AGENT_CMD`, and returns 501 when it isn't configured.
  Don't paper over that with a fake success.
- **No completion percentage exists**, so the server sends `progress: 0` and
  `agent_hero_card.dart` renders an indeterminate bar. Don't invent a number.
- **Plain HTTP/WS on the LAN.** Token auth, no TLS. Same-network only.
- **Risk levels are heuristics**, not a security boundary. The human is.

## Tests

- `test/models_test.dart` — serialization, using payload shapes the broker
  actually emits.
- `test/approvals_screen_test.dart` — widget tests via `test/support/fake_client.dart`.
- `companion_server/test/broker.test.js` — decisions, rules, timeout, stop/pause.
- `companion_server/test/e2e.test.js` — spawns the **real hook binary** against a
  real server: proves it blocks, that a decision releases it, that a timeout
  degrades to `ask`, and that a dead server doesn't hang the IDE. If you change
  the broker or the hook, this is the suite that catches you.

## Housekeeping

`.gitignore` covers `build/`, `.dart_tool/`, `.idea/`, `*.iml`,
`.flutter-plugins-dependencies`, and none are tracked — but they exist on disk,
so exclude them from `find`/`grep` sweeps. `android/local.properties` holds
machine-local SDK paths; keep it untracked.
