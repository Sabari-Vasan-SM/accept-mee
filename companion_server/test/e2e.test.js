'use strict';

/**
 * End-to-end proof of the thing this whole project exists to do:
 * a real hook.js subprocess blocks until a decision arrives over HTTP,
 * then prints a decision Antigravity can act on.
 */

const test = require('node:test');
const assert = require('node:assert');
const os = require('os');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Must be set before index.js is required: it resolves the token path at load.
const TEST_HOME = fs.mkdtempSync(path.join(os.tmpdir(), 'ag-companion-'));
process.env.ANTIGRAVITY_COMPANION_HOME = TEST_HOME;
process.env.APPROVAL_TIMEOUT_MS = '4000';

const server = require('../index.js');

const HOOK = path.resolve(__dirname, '..', 'hook.js');
const token = server.token;
let baseUrl;
let port;

test.before(async () => {
  await new Promise((resolve) => {
    server.start(0, '127.0.0.1').once('listening', resolve);
  });
  port = server.server.address().port;
  baseUrl = `http://127.0.0.1:${port}/api/v1`;
});

test.after(() => {
  server.server.close();
  fs.rmSync(TEST_HOME, { recursive: true, force: true });
});

function api(pathname, { method = 'GET', body, auth = true } = {}) {
  return fetch(`${baseUrl}${pathname}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(auth ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
}

function runHook(payload, mode = 'pre') {
  const child = spawn(process.execPath, [HOOK, mode], {
    env: {
      ...process.env,
      ANTIGRAVITY_COMPANION_HOST: '127.0.0.1',
      ANTIGRAVITY_COMPANION_PORT: String(port),
      ANTIGRAVITY_COMPANION_HOME: TEST_HOME,
      ANTIGRAVITY_HOOK_TIMEOUT_SECONDS: '10',
    },
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  let stdout = '';
  child.stdout.setEncoding('utf8');
  child.stdout.on('data', (c) => {
    stdout += c;
  });

  let exited = false;
  const done = new Promise((resolve) => {
    child.on('close', () => {
      exited = true;
      resolve(stdout);
    });
  });

  child.stdin.write(JSON.stringify(payload));
  child.stdin.end();

  return { child, done, hasExited: () => exited };
}

const PAYLOAD = {
  conversationId: 'conv-e2e',
  workspacePaths: [process.cwd()],
  modelName: 'test-model',
  stepIdx: 3,
  toolCall: { name: 'run_command', args: { command: 'rm -rf ./dist' } },
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

test('health is reachable without a token', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.strictEqual(res.status, 200);
  assert.strictEqual((await res.json()).ok, true);
});

test('every other endpoint rejects a missing or wrong token', async () => {
  assert.strictEqual((await api('/status', { auth: false })).status, 401);

  const wrong = await fetch(`${baseUrl}/status`, {
    headers: { Authorization: 'Bearer not-the-real-token' },
  });
  assert.strictEqual(wrong.status, 401);

  assert.strictEqual((await api('/status')).status, 200);
});

test('a hook blocks until the phone allows, then reports allow', async () => {
  const hook = runHook(PAYLOAD);

  // Give it time to reach the server and park.
  await sleep(600);
  assert.strictEqual(hook.hasExited(), false, 'the hook must still be blocking the agent');

  const pending = await (await api('/approvals')).json();
  assert.strictEqual(pending.length, 1);
  assert.strictEqual(pending[0].riskLevel, 'high', 'rm -rf should be flagged high risk');
  assert.strictEqual(pending[0].details.command, 'rm -rf ./dist');

  const decided = await api(`/approvals/${pending[0].id}/decide`, {
    method: 'POST',
    body: { decision: 'ALLOW_ONCE' },
  });
  assert.strictEqual(decided.status, 200);

  const out = JSON.parse(await hook.done);
  assert.strictEqual(out.decision, 'allow');
  assert.strictEqual(out.allow_tool, true, 'both documented output shapes must be present');

  assert.deepStrictEqual(await (await api('/approvals')).json(), []);
});

test('a denied request tells the agent to deny, with a reason', async () => {
  const hook = runHook(PAYLOAD);
  await sleep(600);

  const [pendingRequest] = await (await api('/approvals')).json();
  await api(`/approvals/${pendingRequest.id}/decide`, {
    method: 'POST',
    body: { decision: 'DENY', reason: 'not on prod' },
  });

  const out = JSON.parse(await hook.done);
  assert.strictEqual(out.decision, 'deny');
  assert.strictEqual(out.allow_tool, false);
  assert.strictEqual(out.deny_reason, 'not on prod');
});

test('no answer within the window falls back to ask, not allow', async () => {
  const hook = runHook(PAYLOAD);
  const out = JSON.parse(await hook.done); // APPROVAL_TIMEOUT_MS is 4s here
  assert.strictEqual(out.decision, 'ask');
  assert.strictEqual(out.allow_tool, undefined);
});

test('a hook whose server is down degrades to ask instead of hanging', async () => {
  const child = spawn(process.execPath, [HOOK, 'pre'], {
    env: {
      ...process.env,
      ANTIGRAVITY_COMPANION_HOST: '127.0.0.1',
      ANTIGRAVITY_COMPANION_PORT: '1', // nothing listens here
      ANTIGRAVITY_COMPANION_HOME: TEST_HOME,
      ANTIGRAVITY_HOOK_TIMEOUT_SECONDS: '10',
    },
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  let stdout = '';
  child.stdout.setEncoding('utf8');
  child.stdout.on('data', (c) => {
    stdout += c;
  });
  child.stdin.end(JSON.stringify(PAYLOAD));

  await new Promise((resolve) => child.on('close', resolve));
  const out = JSON.parse(stdout);
  assert.strictEqual(out.decision, 'ask');
  assert.match(out.reason, /unavailable/i);
});

test('the post hook records real activity and never blocks', async () => {
  const before = (await (await api('/history')).json()).length;

  const hook = runHook(
    {
      ...PAYLOAD,
      toolCall: { name: 'write_file', args: { path: '/tmp/demo/app.js' } },
      result: 'wrote 42 lines',
    },
    'post',
  );
  const out = await hook.done;
  assert.strictEqual(out, '{}');

  const history = await (await api('/history')).json();
  assert.strictEqual(history.length, before + 1);
  assert.strictEqual(history[0].type, 'file_edit');
});

test('stop makes every subsequent tool call deny immediately', async () => {
  await api('/agent/stop', { method: 'POST' });

  const hook = runHook(PAYLOAD);
  const out = JSON.parse(await hook.done);
  assert.strictEqual(out.decision, 'deny');

  await api('/agent/resume', { method: 'POST' });
});

test('instructions report a real error when no agent command is configured', async () => {
  const res = await api('/commands', { method: 'POST', body: { instruction: 'fix the tests' } });
  assert.strictEqual(res.status, 501);
  const body = await res.json();
  assert.strictEqual(body.error, 'agent_not_configured');
});

test('status reports derived state, not invented state', async () => {
  const status = await (await api('/status')).json();
  assert.strictEqual(status.agentState.progress, 0, 'we never fabricate a progress percentage');
  assert.ok(Array.isArray(status.activeProjects));
  assert.ok(status.connectedDevices.some((d) => d.isCurrent));
});
