'use strict';

const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const qrcode = require('qrcode-terminal');
const os = require('os');

const { loadOrCreateToken, requireToken, tokenMatches, tokenFromUpgradeUrl } = require('./lib/auth');
const { ApprovalBroker } = require('./lib/broker');
const { ActivityLog, typeForTool } = require('./lib/activity');
const { ProjectRegistry } = require('./lib/projects');
const { AgentRunner } = require('./lib/agent_runner');
const { RuleStore } = require('./lib/rules');
const { sanitize } = require('./lib/risk');
const { firstString } = require('./lib/toolmap');

const PORT = Number(process.env.PORT) || 8765;
const BIND = process.env.BIND_ADDRESS || '0.0.0.0';
const APPROVAL_TIMEOUT_MS = Number(process.env.APPROVAL_TIMEOUT_MS) || 120000;
const RESET_TOKEN = process.argv.includes('--reset-token') || process.env.ANTIGRAVITY_RESET_TOKEN === '1';

const token = loadOrCreateToken({ reset: RESET_TOKEN });

function getLocalIp() {
  for (const addrs of Object.values(os.networkInterfaces())) {
    for (const iface of addrs || []) {
      if (iface.family === 'IPv4' && !iface.internal) return iface.address;
    }
  }
  return '127.0.0.1';
}

const localIp = getLocalIp();
const deviceName = process.env.DEVICE_NAME || `${os.hostname()} (${os.type()} ${os.arch()})`;
const startedAt = Date.now();

// ---------------------------------------------------------------------------
// Real state. Nothing is seeded: every project, event and approval below comes
// from an actual hook callback or an actual command this server ran.
// ---------------------------------------------------------------------------
const rules = new RuleStore();
const broker = new ApprovalBroker({ deviceName, timeoutMs: APPROVAL_TIMEOUT_MS, rules });
const activity = new ActivityLog();
const projects = new ProjectRegistry();
const agent = new AgentRunner();

/** Wall-clock of the last real agent tool call, used to derive idle vs working. */
let lastToolCallMs = 0;
let lastToolSummary = null;

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

const server = http.createServer(app);
// Approval requests are held open on purpose; don't let Node time them out.
server.requestTimeout = 0;
server.headersTimeout = 65000;

const wss = new WebSocket.Server({ noServer: true });

// ---------------------------------------------------------------------------
// Derived agent state
// ---------------------------------------------------------------------------
function agentState() {
  const quietFor = Date.now() - lastToolCallMs;
  let status;
  if (broker.isStopped) status = 'error';
  else if (broker.pendingCount > 0) status = 'waitingForApproval';
  else if (broker.isPaused) status = 'paused';
  else if (agent.running || (lastToolCallMs > 0 && quietFor < 60000)) status = 'working';
  else if (lastToolCallMs > 0) status = 'idle';
  else status = 'idle';

  return {
    status,
    currentTask: agent.lastInstruction?.instruction || lastToolSummary || 'No agent activity yet',
    currentAction: broker.pendingCount > 0
      ? `${broker.pendingCount} approval${broker.pendingCount === 1 ? '' : 's'} waiting for you`
      : lastToolSummary || 'Waiting for the agent to call a tool',
    // Antigravity reports no completion percentage, so we don't invent one.
    // The app treats 0 as "indeterminate" and hides the bar.
    progress: 0,
    activeProject: projects.activeId || 'workspace',
    connectedComputer: deviceName,
    uptimeSeconds: Math.floor((Date.now() - startedAt) / 1000),
    lastUpdated: new Date().toISOString(),
  };
}

function devices() {
  const phones = [...wss.clients].filter((c) => c.readyState === WebSocket.OPEN);
  return [
    {
      id: 'this-desktop',
      name: deviceName,
      type: /darwin/i.test(os.type()) ? 'laptop' : 'desktop',
      ip: localIp,
      status: 'online',
      isCurrent: true,
      lastSeen: new Date().toISOString(),
    },
    ...phones.map((client, i) => ({
      id: client.clientId || `phone-${i}`,
      name: client.clientName || 'Paired phone',
      type: 'laptop',
      ip: client.remoteIp || 'unknown',
      status: 'online',
      isCurrent: false,
      lastSeen: new Date(client.connectedAt || Date.now()).toISOString(),
    })),
  ];
}

function snapshot() {
  return {
    agentState: agentState(),
    pendingApprovals: broker.pending,
    activeProjects: projects.list(),
    connectedDevices: devices(),
    activityHistory: activity.list(),
  };
}

// ---------------------------------------------------------------------------
// Broadcast
// ---------------------------------------------------------------------------
function broadcast(type, payload) {
  const message = JSON.stringify({ type, payload });
  for (const client of wss.clients) {
    if (client.readyState === WebSocket.OPEN) client.send(message);
  }
}

function pushAgentState() {
  broadcast('AGENT_STATUS_UPDATED', agentState());
}

function pushActivity(event) {
  broadcast('ACTIVITY_ADDED', event);
  pushAgentState();
}

broker.on('requestCreated', (request) => {
  broadcast('NEW_APPROVAL_REQUEST', request);
  pushAgentState();
});

broker.on('requestResolved', ({ approvalId, decision, reason, request }) => {
  broadcast('APPROVAL_RESOLVED', { approvalId, decision, reason });
  if (decision === 'allow' || decision === 'deny') {
    pushActivity(
      activity.add({
        type: decision === 'allow' ? 'approval_granted' : 'approval_denied',
        title: request?.title || 'Approval',
        description: reason || '',
        project: request?.project || projects.activeId || 'workspace',
        status: decision === 'allow' ? 'success' : 'cancelled',
      }),
    );
  } else {
    pushAgentState();
  }
});

broker.on('autoDecided', ({ request, outcome }) => {
  pushActivity(
    activity.add({
      type: outcome.decision === 'allow' ? 'approval_granted' : 'approval_denied',
      title: request.title,
      description: outcome.reason,
      project: request.project,
      status: outcome.decision === 'allow' ? 'success' : 'cancelled',
    }),
  );
});

broker.on('modeChanged', pushAgentState);

agent.on('started', ({ instruction, cwd }) => {
  pushActivity(
    activity.add({
      type: 'user_instruction',
      title: 'Instruction dispatched',
      description: `${instruction}${cwd ? `  ·  ${cwd}` : ''}`,
      project: projects.activeId || 'workspace',
      status: 'success',
    }),
  );
});

agent.on('output', ({ line, status }) => {
  pushActivity(
    activity.add({
      type: 'terminal_command',
      title: 'Agent output',
      description: line,
      project: projects.activeId || 'workspace',
      status,
    }),
  );
});

agent.on('finished', ({ ok, message }) => {
  pushActivity(
    activity.add({
      type: ok ? 'task_complete' : 'error_warning',
      title: ok ? 'Agent run finished' : 'Agent run failed',
      description: message,
      project: projects.activeId || 'workspace',
      status: ok ? 'success' : 'failed',
    }),
  );
});

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// Unauthenticated: the app needs a reachability probe before it has a token,
// and this deliberately leaks nothing beyond "a companion server is here".
app.get('/api/v1/health', (req, res) => {
  res.json({ ok: true, service: 'antigravity-companion', protocol: 'antigravity-bridge', version: '2.0' });
});

app.use('/api/v1', requireToken(token));

app.get('/api/v1/status', (req, res) => res.json(snapshot()));
app.get('/api/v1/approvals', (req, res) => res.json(broker.pending));
app.get('/api/v1/projects', (req, res) => res.json(projects.list()));
app.get('/api/v1/devices', (req, res) => res.json(devices()));
app.get('/api/v1/history', (req, res) => res.json(activity.list()));
app.get('/api/v1/rules', (req, res) => res.json(rules.list()));

app.delete('/api/v1/rules', (req, res) => {
  rules.clear();
  res.json({ ok: true });
});

/**
 * THE HOOK ENDPOINT.
 *
 * Called by hook.js on PreToolUse. The response is intentionally deferred until
 * a human decides — that parked response is what blocks the agent.
 */
app.post('/api/v1/approvals', async (req, res) => {
  const body = req.body || {};
  if (!body.toolCall || typeof body.toolCall.name !== 'string') {
    return res.status(400).json({ error: 'bad_request', message: 'toolCall.name is required' });
  }

  lastToolCallMs = Date.now();
  const command = firstString(body.toolCall.args, ['command', 'cmd', 'script']);
  lastToolSummary = sanitize(command || body.toolCall.name).slice(0, 120);

  if (await projects.touch(body.workspacePaths)) {
    broadcast('PROJECTS_UPDATED', projects.list());
  }

  const { requestId, promise } = broker.submit(body);

  // If the hook process is killed (its own timeout fired), stop waiting.
  req.on('close', () => {
    if (!res.writableEnded) broker.abandon(requestId);
  });

  const outcome = await promise;
  if (res.writableEnded) return undefined;
  return res.json(outcome);
});

/** Called by hook.js on PostToolUse — real activity, after the fact. */
app.post('/api/v1/activity', async (req, res) => {
  const body = req.body || {};
  const tool = typeof body.tool === 'string' ? body.tool : 'tool';
  const command = typeof body.command === 'string' ? body.command : null;
  const ok = body.status !== 'failed';

  lastToolCallMs = Date.now();
  lastToolSummary = sanitize(command || tool).slice(0, 120);

  if (await projects.touch(body.workspacePaths)) {
    broadcast('PROJECTS_UPDATED', projects.list());
  }

  pushActivity(
    activity.add({
      type: typeForTool(tool, Boolean(command)),
      title: sanitize(body.title || command || tool).slice(0, 120),
      description: sanitize(body.description || '').slice(0, 2000),
      project: projects.activeId || 'workspace',
      status: ok ? 'success' : 'failed',
      diff: body.diff ? sanitize(String(body.diff)).slice(0, 4000) : null,
    }),
  );

  res.json({ ok: true });
});

app.post('/api/v1/approvals/:id/decide', (req, res) => {
  const { decision, reason } = req.body || {};
  const valid = ['ALLOW_ONCE', 'ALWAYS_ALLOW', 'DENY'];
  if (!valid.includes(decision)) {
    return res.status(400).json({ error: 'bad_request', message: `decision must be one of ${valid.join(', ')}` });
  }
  const applied = broker.decide(req.params.id, decision, reason);
  if (!applied) {
    return res.status(404).json({ error: 'not_found', message: 'That request is no longer pending.' });
  }
  return res.json({ ok: true });
});

app.post('/api/v1/commands', (req, res) => {
  const instruction = typeof req.body?.instruction === 'string' ? req.body.instruction.trim() : '';
  if (instruction === '') {
    return res.status(400).json({ error: 'bad_request', message: 'instruction is required' });
  }
  const result = agent.run(instruction, projects.activePath());
  if (!result.ok) {
    return res.status(result.error === 'agent_not_configured' ? 501 : 409).json(result);
  }
  return res.json({ ok: true, pid: result.pid });
});

app.post('/api/v1/agent/:action', (req, res) => {
  const { action } = req.params;
  switch (action) {
    case 'pause':
      // Every tool call now waits for you instead of matching saved rules.
      broker.setPaused(true);
      return res.json({ ok: true, mode: 'paused' });
    case 'resume':
      broker.setStopped(false);
      broker.setPaused(false);
      return res.json({ ok: true, mode: 'running' });
    case 'stop': {
      // Deny everything queued, refuse what comes next, kill anything we spawned.
      broker.setStopped(true);
      const killed = agent.stop();
      return res.json({ ok: true, mode: 'stopped', killedProcess: killed });
    }
    case 'retry': {
      const result = agent.retry();
      if (!result.ok) {
        return res.status(result.error === 'agent_not_configured' ? 501 : 409).json(result);
      }
      return res.json({ ok: true, pid: result.pid });
    }
    default:
      return res.status(400).json({ error: 'bad_request', message: `unknown action '${action}'` });
  }
});

app.post('/api/v1/projects/:id/select', (req, res) => {
  if (!projects.setActive(req.params.id)) {
    return res.status(404).json({ error: 'not_found', message: 'Unknown project' });
  }
  broadcast('PROJECTS_UPDATED', projects.list());
  pushAgentState();
  return res.json({ ok: true });
});

// ---------------------------------------------------------------------------
// WebSocket
// ---------------------------------------------------------------------------
server.on('upgrade', (req, socket, head) => {
  const url = req.url || '';
  if (!url.startsWith('/ws')) {
    socket.destroy();
    return;
  }
  if (!tokenMatches(token, tokenFromUpgradeUrl(url))) {
    socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
    socket.destroy();
    return;
  }
  wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
});

wss.on('connection', (ws, req) => {
  ws.clientId = `phone_${Date.now().toString(36)}`;
  ws.remoteIp = req.socket.remoteAddress;
  ws.connectedAt = Date.now();
  ws.isAlive = true;

  ws.send(JSON.stringify({ type: 'INITIAL_STATE', payload: snapshot() }));
  broadcast('DEVICES_UPDATED', devices());

  ws.on('pong', () => {
    ws.isAlive = true;
  });

  ws.on('message', (raw) => {
    let message;
    try {
      message = JSON.parse(raw.toString());
    } catch {
      return;
    }
    const payload = message.payload || {};

    switch (message.type) {
      case 'DECIDE_APPROVAL':
        broker.decide(payload.approvalId, payload.decision, payload.reason);
        break;
      case 'SEND_INSTRUCTION': {
        const result = agent.run(String(payload.instruction || ''), projects.activePath());
        if (!result.ok) {
          ws.send(JSON.stringify({ type: 'COMMAND_FAILED', payload: result }));
        }
        break;
      }
      case 'AGENT_CONTROL':
        if (payload.action === 'pause') broker.setPaused(true);
        else if (payload.action === 'resume') {
          broker.setStopped(false);
          broker.setPaused(false);
        } else if (payload.action === 'stop') {
          broker.setStopped(true);
          agent.stop();
        } else if (payload.action === 'retry') {
          const result = agent.retry();
          if (!result.ok) ws.send(JSON.stringify({ type: 'COMMAND_FAILED', payload: result }));
        }
        break;
      case 'SELECT_PROJECT':
        if (projects.setActive(payload.projectId)) {
          broadcast('PROJECTS_UPDATED', projects.list());
          pushAgentState();
        }
        break;
      default:
        break;
    }
  });

  ws.on('close', () => broadcast('DEVICES_UPDATED', devices()));
});

const heartbeat = setInterval(() => {
  for (const client of wss.clients) {
    if (client.isAlive === false) {
      client.terminate();
      continue;
    }
    client.isAlive = false;
    client.ping();
  }
  if (projects.ageOut()) {
    broadcast('PROJECTS_UPDATED', projects.list());
    pushAgentState();
  }
}, 30000);
heartbeat.unref();

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------
const pairingPayload = JSON.stringify({
  version: '2.0',
  protocol: 'antigravity-bridge',
  host: localIp,
  port: PORT,
  token,
  deviceName,
  wsUrl: `ws://${localIp}:${PORT}/ws`,
  httpUrl: `http://${localIp}:${PORT}/api/v1`,
});

function start(port = PORT, bind = BIND) {
  return server.listen(port, bind, () => {
  const line = '='.repeat(54);
  console.log(`\n${line}`);
  console.log('ANTIGRAVITY COMPANION SERVER');
  console.log(line);
  console.log(`Host:        ${deviceName}`);
  console.log(`HTTP API:    http://${localIp}:${PORT}/api/v1`);
  console.log(`WebSocket:   ws://${localIp}:${PORT}/ws`);
  console.log(`Approval wait: ${Math.round(APPROVAL_TIMEOUT_MS / 1000)}s, then falls back to the desktop prompt`);
  console.log(
    agent.configured
      ? `Agent command: ${agent.command} ${agent.argsTemplate.join(' ')}`
      : 'Agent command: not configured (instructions and quick commands will report an error)',
  );
  if (!process.env.ANTIGRAVITY_HOOK_INSTALLED) {
    console.log('\nInstall the Antigravity hook so tool calls reach this server:');
    console.log('  npm run install-hook -- --project /path/to/your/project');
  }
  console.log('\nScan this in the companion app:\n');
  qrcode.generate(pairingPayload, { small: true });
  console.log(`Token: ${token.slice(0, 8)}… (stored in ~/.antigravity-companion/token)`);
  console.log(`${line}\n`);
  });
}

// Only boot when run directly, so tests can import the wiring and listen on
// an ephemeral port themselves.
if (require.main === module) {
  start();
}

module.exports = { app, server, start, broker, activity, projects, agent, token };
