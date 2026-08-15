# AGENTS.md — accept-mee (Antigravity Companion)

Context for AI agents working on this repo. Read this before changing code.

> Naming note: the folder is `accept-mee`, but the Dart package, app title, and
> IntelliJ module are all **`antigravity_companion`**. Imports in tests use
> `package:antigravity_companion/...`. Don't "fix" the mismatch.

## What this is

A Flutter mobile companion app that turns a phone into a remote control and
**approval center** for an AI coding agent running on a desktop. The phone
receives permission requests (`npm install`, `rm -rf`, schema migrations),
shows risk-badged cards, and sends back `ALLOW ONCE` / `ALWAYS ALLOW` / `DENY`.
It also streams agent activity, dispatches quick commands and voice
instructions, and pairs to the desktop over QR.

Two halves live in this repo:

| Path | What it is |
|---|---|
| `lib/` | Flutter app (iOS, Android, web, macOS, Linux, Windows scaffolds present) |
| `companion_server/` | Node/Express + `ws` desktop server, port **8765** |

## Run it

```bash
cd companion_server && npm install && npm start
```

```bash
flutter pub get && flutter run
```

```bash
flutter test
```

```bash
flutter analyze
```

The server prints an ASCII QR code, the LAN IP, and a freshly generated pairing
token on boot. The token is `crypto.randomBytes(16)` **regenerated every
restart** — restart the server and the phone's stored token is stale; re-pair.

Default host in `StorageService.defaultHost` is `10.0.2.2` on Android (emulator
→ host loopback) and `127.0.0.1` elsewhere. On a physical phone you must set
the LAN IP in Settings or pair by QR.

## Architecture

```
Flutter app ── REST /api/v1 + WebSocket /ws ──> companion_server :8765
```

State flows one way: `AntigravityClient` exposes broadcast **streams** →
Riverpod `StreamProvider`s → widgets. Widgets never touch the transport
directly; they call methods on the client obtained from
`antigravityClientProvider`.

### The client abstraction — the most important convention

`lib/services/antigravity_client.dart` defines the abstract `AntigravityClient`
contract. There are two implementations:

- `AntigravityRemoteClient` — real HTTP + WebSocket to the companion server.
- `AntigravityMockClient` — a full standalone simulator (471 lines) with timers
  that advance agent progress, seed approvals, and generate activity. Used for
  offline demos and by the unit tests.

`antigravityClientProvider` picks between them from
`storage.useMockClient` (Settings toggle) and immediately calls `connect(...)`.

**If you add a capability, add it to all three files** — the abstract contract,
the remote client, and the mock client. A method on only the remote client
silently breaks mock mode; a method on only the mock breaks the real app.

### Wire protocol

WebSocket messages are `{"type": ..., "payload": ...}`.

- Server → app: `INITIAL_STATE`, `AGENT_STATUS_UPDATED`, `NEW_APPROVAL_REQUEST`,
  `APPROVAL_RESOLVED`, `ACTIVITY_ADDED`
- App → server: `DECIDE_APPROVAL`, `SEND_INSTRUCTION`, `AGENT_CONTROL`,
  `SELECT_PROJECT`

REST endpoints under `/api/v1`: `health`, `status`, `approvals`,
`approvals/:id/decide`, `commands`, `agent/:action`, `projects`, `devices`,
`history`, `simulate/permission-request`.

The remote client sends most actions over **both** WS and REST (WS for
immediacy, HTTP as the fallback/ack). Keep that pattern when adding actions —
and keep the message `type` strings identical on both sides; they are plain
strings with no shared schema, so a typo fails silently.

## Layout

```
lib/
  core/constants/    app_colors, app_theme, app_typography  (Material 3, dark-only)
  core/security/     SecurityService — biometrics + command masking
  core/storage/      StorageService — SharedPreferences wrapper
  core/utils/        date_formatter, haptic_feedback_util
  features/<area>/   one screen per folder, private widgets in widgets/
  models/            plain classes, hand-written fromJson/toJson
  providers/         Riverpod providers, one file per domain
  routing/           app_router.dart — GoRouter
  services/          transport + speech + notifications
```

Routes: a `ShellRoute` (`AppShell` bottom nav) wraps `/dashboard`, `/activity`,
`/approvals`, `/projects`, `/devices`, `/settings`. `/pairing` and `/commands`
are pushed on the **root** navigator (full-screen, no bottom nav). Adding a tab
means touching both `app_router.dart` and `AppShell`.

## Conventions

- **State**: `flutter_riverpod` 2.x. `StreamProvider` for anything sourced from
  the client, `StateNotifierProvider` for local mutable state (`settingsProvider`).
  No codegen — providers are declared by hand.
- **Models**: no `freezed`, no `json_serializable`. Every model has a
  hand-written `fromJson`/`toJson` with **defensive defaults** (`as String? ??
  'fallback'`), because the server may omit fields. Match that style; don't
  introduce codegen for one model.
- `SettingsNotifier` rebuilds the whole `SettingsState` on every setter (no
  `copyWith`). Verbose but consistent — follow it or refactor all of it.
- **Storage**: all SharedPreferences keys are `antigravity_*` constants inside
  `StorageService`. Never call `SharedPreferences` directly elsewhere.
  `storageServiceProvider` throws unless overridden — `main()` overrides it in
  `ProviderScope` after `StorageService.init()`.
- **Theme**: dark only, Material 3, **solid colors, no gradients** (deliberate).
  Colors come from `AppColors`, text from `AppTypography` (Google Fonts, Plus
  Jakarta Sans — needs network on first run). Don't hardcode `Color(0x...)` in
  widgets.
- **Lints**: `flutter_lints` 6, default rule set, Dart SDK `^3.12.2`.

## Things that are simulated, not real

Don't assume these work in production — several are deliberate demo stubs:

- `SecurityService.authenticateBiometric` always returns `true` after 300 ms.
  There is no `local_auth` dependency. The Settings biometric toggle gates
  nothing real.
- `SpeechService` is a **fake** recognizer driven by `Random` and timers — no
  speech-to-text package is installed. The waveform is generated amplitude.
- `NotificationService` is in-app only (a broadcast stream + history list).
  There is no FCM/APNs or `flutter_local_notifications`; nothing fires when the
  app is backgrounded.
- The companion server holds all state in memory and serves seeded demo
  projects/devices. It is **unauthenticated** — the pairing token is printed
  and stored but no endpoint verifies it, and there is no TLS. Treat it as
  LAN-only demo software; don't expose it, and say so if asked to ship it.

## Tests

`test/widget_test.dart` is misnamed — it contains **model serialization and
mock-client behavior tests**, no widget tests. When you touch a model's
`fromJson`/`toJson` or `AntigravityMockClient` semantics, update it there.

## Housekeeping

`.gitignore` covers `build/`, `.dart_tool/`, `.idea/`, `*.iml`,
`.flutter-plugins-dependencies`, and none of them are tracked — but they do
exist on disk, so `find`/`grep` sweeps will hit `build/` and `.dart_tool/`
unless you exclude them. `android/local.properties` holds machine-local SDK
paths; keep it untracked.
