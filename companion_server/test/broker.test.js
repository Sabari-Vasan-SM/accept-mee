'use strict';

const test = require('node:test');
const assert = require('node:assert');
const os = require('os');
const path = require('path');
const fs = require('fs');

const { ApprovalBroker } = require('../lib/broker');
const { RuleStore } = require('../lib/rules');
const { classify, sanitize } = require('../lib/risk');
const { toPermissionRequest } = require('../lib/toolmap');

function tempRules() {
  const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'ag-rules-')), 'rules.json');
  return new RuleStore(file);
}

function newBroker(opts = {}) {
  return new ApprovalBroker({ deviceName: 'Test Desktop', rules: tempRules(), ...opts });
}

const RUN = (command) => ({
  toolCall: { name: 'run_command', args: { command } },
  workspacePaths: ['/tmp/demo-project'],
  conversationId: 'conv-1',
});

test('a submitted request stays pending until a decision arrives', async () => {
  const broker = newBroker();
  const { requestId, promise } = broker.submit(RUN('npm test'));

  assert.strictEqual(broker.pendingCount, 1);

  let settled = false;
  promise.then(() => {
    settled = true;
  });
  await new Promise((r) => setImmediate(r));
  assert.strictEqual(settled, false, 'must not resolve before a human answers');

  broker.decide(requestId, 'ALLOW_ONCE');
  const outcome = await promise;

  assert.strictEqual(outcome.decision, 'allow');
  assert.strictEqual(broker.pendingCount, 0);
});

test('DENY resolves as deny and carries the reason', async () => {
  const broker = newBroker();
  const { requestId, promise } = broker.submit(RUN('rm -rf build'));

  broker.decide(requestId, 'DENY', 'not now');
  const outcome = await promise;

  assert.strictEqual(outcome.decision, 'deny');
  assert.strictEqual(outcome.reason, 'not now');
});

test('ALWAYS_ALLOW persists a rule that auto-allows the identical call', async () => {
  const broker = newBroker();

  const first = broker.submit(RUN('npm run build'));
  broker.decide(first.requestId, 'ALWAYS_ALLOW');
  assert.strictEqual((await first.promise).decision, 'allow');

  const second = broker.submit(RUN('npm run build'));
  const outcome = await second.promise;
  assert.strictEqual(outcome.decision, 'allow');
  assert.strictEqual(outcome.auto, 'rule');
  assert.strictEqual(broker.pendingCount, 0, 'the phone should not be asked again');
});

test('an always-allow rule does not leak to a different command', async () => {
  const broker = newBroker();

  const first = broker.submit(RUN('npm install lodash'));
  broker.decide(first.requestId, 'ALWAYS_ALLOW');
  await first.promise;

  const second = broker.submit(RUN('npm install evil-package'));
  assert.strictEqual(broker.pendingCount, 1, 'a different command must still be asked');
  broker.decide(second.requestId, 'DENY');
  assert.strictEqual((await second.promise).decision, 'deny');
});

test('timeout falls back to ask, never to allow', async () => {
  const broker = newBroker({ timeoutMs: 40 });
  const { promise } = broker.submit(RUN('sleep 1'));

  const outcome = await promise;
  assert.strictEqual(outcome.decision, 'ask');
  assert.match(outcome.reason, /falling back/i);
});

test('stop denies what is queued and everything that follows', async () => {
  const broker = newBroker();
  const queued = broker.submit(RUN('npm start'));

  broker.setStopped(true);
  assert.strictEqual((await queued.promise).decision, 'deny');

  const later = broker.submit(RUN('echo hi'));
  const outcome = await later.promise;
  assert.strictEqual(outcome.decision, 'deny');
  assert.strictEqual(outcome.auto, 'stopped');
});

test('pause bypasses saved rules so every call reaches the phone', async () => {
  const broker = newBroker();

  const first = broker.submit(RUN('git status'));
  broker.decide(first.requestId, 'ALWAYS_ALLOW');
  await first.promise;

  broker.setPaused(true);
  const second = broker.submit(RUN('git status'));
  assert.strictEqual(broker.pendingCount, 1, 'paused mode must ignore the rule');

  broker.decide(second.requestId, 'ALLOW_ONCE');
  await second.promise;
});

test('abandon clears a request when the hook process dies', async () => {
  const broker = newBroker();
  const { requestId } = broker.submit(RUN('npm test'));

  assert.strictEqual(broker.abandon(requestId), true);
  assert.strictEqual(broker.pendingCount, 0);
  assert.strictEqual(broker.decide(requestId, 'ALLOW_ONCE'), false);
});

test('risk classifier flags destructive commands high and reads low', () => {
  assert.strictEqual(classify({ tool: 'run_command', command: 'rm -rf /' }).level, 'high');
  assert.strictEqual(classify({ tool: 'run_command', command: 'sudo apt install x' }).level, 'high');
  assert.strictEqual(classify({ tool: 'run_command', command: 'git push --force' }).level, 'high');
  assert.strictEqual(classify({ tool: 'run_command', command: 'npm install lodash' }).level, 'medium');
  assert.strictEqual(classify({ tool: 'view_file', command: '' }).level, 'low');
  assert.strictEqual(classify({ tool: 'delete_file', target: 'a.txt' }).level, 'high');
});

test('secrets are masked before a command reaches the phone', () => {
  assert.match(sanitize('deploy --token=abcd1234secret'), /token=\*{6}/);
  assert.match(sanitize('export API_KEY: sk-abcdefghijklmnopqrst'), /\*{6}/);
  assert.doesNotMatch(sanitize('curl -H "Authorization: Bearer ghp_abcdefghijklmnopqrst"'), /ghp_abcd/);
});

test('tool calls map onto the shape the Flutter app parses', () => {
  const request = toPermissionRequest(
    {
      requestId: 'req_1',
      toolCall: { name: 'run_command', args: { command: 'rm -rf node_modules', cwd: '/tmp/demo' } },
      workspacePaths: ['/tmp/demo'],
    },
    'Test Desktop',
  );

  assert.strictEqual(request.id, 'req_1');
  assert.strictEqual(request.type, 'terminal_command');
  assert.strictEqual(request.riskLevel, 'high');
  assert.strictEqual(request.device, 'Test Desktop');
  assert.strictEqual(request.details.command, 'rm -rf node_modules');
  assert.strictEqual(request.details.workingDirectory, '/tmp/demo');
  assert.strictEqual(request.project, 'demo');
  assert.ok(request.details.impact.length > 0);
});

test('an unknown tool still produces a reviewable card', () => {
  const request = toPermissionRequest(
    { requestId: 'req_2', toolCall: { name: 'some_new_tool', args: { foo: 'bar' } } },
    'Test Desktop',
  );
  assert.strictEqual(request.title, 'some_new_tool');
  assert.strictEqual(request.riskLevel, 'medium');
  assert.match(request.description, /foo/);
});
