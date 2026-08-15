#!/usr/bin/env node
'use strict';

/**
 * Antigravity hook client.
 *
 *   node hook.js pre    → PreToolUse:  blocks the agent until your phone answers
 *   node hook.js post   → PostToolUse: reports what happened, never blocks
 *
 * Antigravity writes the hook payload to stdin as JSON and reads our decision
 * from stdout. See companion_server/README.md for the hooks.json wiring.
 *
 * Deliberately dependency-free and started with no imports beyond node core:
 * this process runs once per tool call, so startup cost is user-visible latency.
 *
 * FAIL-SAFE RULE: if anything at all goes wrong — server down, bad token,
 * timeout, malformed payload — we emit `ask`, which makes Antigravity show its
 * own approval card. We never emit `allow` on an error path, and we never hang
 * the IDE for longer than our self-timeout.
 */

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

const MODE = (process.argv[2] || 'pre').toLowerCase();

const HOST = process.env.ANTIGRAVITY_COMPANION_HOST || '127.0.0.1';
const PORT = Number(process.env.ANTIGRAVITY_COMPANION_PORT) || 8765;

// Stay a couple of seconds inside whatever timeout hooks.json declares, so we
// get to print `ask` instead of being killed with no output at all.
const HOOK_TIMEOUT_S = Number(process.env.ANTIGRAVITY_HOOK_TIMEOUT_SECONDS) || 120;
const SELF_TIMEOUT_MS = Math.max(3000, (HOOK_TIMEOUT_S - 2) * 1000);

function tokenFile() {
  const home =
    process.env.ANTIGRAVITY_COMPANION_HOME || path.join(os.homedir(), '.antigravity-companion');
  return path.join(home, 'token');
}

function readToken() {
  if (process.env.ANTIGRAVITY_COMPANION_TOKEN) return process.env.ANTIGRAVITY_COMPANION_TOKEN.trim();
  try {
    return fs.readFileSync(tokenFile(), 'utf8').trim();
  } catch {
    return null;
  }
}

/**
 * Emit a decision in both documented shapes.
 *
 * The Antigravity docs specify {"decision": "allow|deny|ask|..."} while some
 * CLI builds read {"allow_tool": bool, "deny_reason": string}. The key sets are
 * disjoint, so writing both satisfies either reader. Always exit 0 — a non-zero
 * exit is treated as a hook failure rather than a decision.
 */
function emitDecision(decision, reason) {
  const out = { decision };
  if (reason) out.reason = reason;

  if (decision === 'allow') {
    out.allow_tool = true;
  } else if (decision === 'deny') {
    out.allow_tool = false;
    out.deny_reason = reason || 'Denied from the Antigravity companion app';
  }
  // 'ask' intentionally carries no allow_tool: a reader that only understands
  // the boolean shape should fall through to its own default prompt.

  process.stdout.write(JSON.stringify(out));
  process.exit(0);
}

function readStdin() {
  return new Promise((resolve) => {
    let raw = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => {
      raw += chunk;
    });
    process.stdin.on('end', () => resolve(raw));
    process.stdin.on('error', () => resolve(raw));
  });
}

function post(pathname, body, { timeoutMs, token }) {
  return new Promise((resolve, reject) => {
    const payload = Buffer.from(JSON.stringify(body), 'utf8');
    const req = http.request(
      {
        host: HOST,
        port: PORT,
        path: pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': payload.length,
          Authorization: `Bearer ${token}`,
        },
        timeout: timeoutMs,
      },
      (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (c) => {
          data += c;
        });
        res.on('end', () => {
          if (res.statusCode !== 200) {
            reject(new Error(`server responded ${res.statusCode}: ${data.slice(0, 200)}`));
            return;
          }
          try {
            resolve(JSON.parse(data));
          } catch (err) {
            reject(err);
          }
        });
      },
    );

    req.on('timeout', () => req.destroy(new Error('timed out waiting for a decision')));
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw || '{}');
  } catch {
    if (MODE === 'post') return process.exit(0);
    return emitDecision('ask', 'Companion hook could not parse the payload');
  }

  const token = readToken();
  if (!token) {
    if (MODE === 'post') return process.exit(0);
    return emitDecision(
      'ask',
      'No companion pairing token found — start the companion server first',
    );
  }

  const toolCall = payload.toolCall || {};

  if (MODE === 'post') {
    // Never block, never delay the agent: short timeout, silence on failure.
    const args = toolCall.args || {};
    const command = args.command || args.cmd || null;
    try {
      await post(
        '/api/v1/activity',
        {
          tool: toolCall.name || 'tool',
          command,
          title: command || toolCall.name,
          description:
            typeof payload.result === 'string'
              ? payload.result.slice(0, 2000)
              : JSON.stringify(payload.result ?? {}).slice(0, 2000),
          status: payload.error || payload.isError ? 'failed' : 'success',
          workspacePaths: payload.workspacePaths,
          conversationId: payload.conversationId,
        },
        { timeoutMs: 2000, token },
      );
    } catch {
      // The companion server being down must never disturb the agent.
    }
    process.stdout.write('{}');
    return process.exit(0);
  }

  try {
    const outcome = await post(
      '/api/v1/approvals',
      {
        toolCall: { name: toolCall.name, args: toolCall.args },
        workspacePaths: payload.workspacePaths,
        conversationId: payload.conversationId,
        stepIdx: payload.stepIdx,
        modelName: payload.modelName,
      },
      { timeoutMs: SELF_TIMEOUT_MS, token },
    );

    const decision = ['allow', 'deny', 'ask'].includes(outcome?.decision) ? outcome.decision : 'ask';
    return emitDecision(decision, outcome?.reason);
  } catch (err) {
    return emitDecision('ask', `Companion app unavailable (${err.message})`);
  }
}

main().catch((err) => {
  if (MODE === 'post') process.exit(0);
  emitDecision('ask', `Companion hook error: ${err.message}`);
});
