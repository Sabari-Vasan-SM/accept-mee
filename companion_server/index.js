const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const qrcode = require('qrcode-terminal');
const os = require('os');
const crypto = require('crypto');

const PORT = process.env.PORT || 8765;
const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server, path: '/ws' });

// Get local network IP address
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

const localIp = getLocalIp();
const pairingToken = crypto.randomBytes(16).toString('hex');
const computerName = `${os.hostname()} (${os.type()} ${os.arch()})`;

// State store
let agentState = {
  status: 'working', // 'idle' | 'working' | 'waitingForApproval' | 'paused' | 'error' | 'completed'
  currentTask: 'Building authentication module with OAuth2 & JWT tokens',
  currentAction: 'Executing test suite: npm run test:auth',
  progress: 74,
  activeProject: 'ecommerce-admin',
  connectedComputer: computerName,
  uptimeSeconds: 1420,
  lastUpdated: new Date().toISOString()
};

let activeProjects = [
  {
    id: 'ecommerce-admin',
    name: 'Ecommerce Admin',
    icon: 'shopping_cart',
    status: 'working',
    branch: 'feat/auth-jwt',
    path: '/Users/sabarivasan/Projects/ecommerce-admin',
    activeTasks: 3
  },
  {
    id: 'school-crm',
    name: 'School CRM',
    icon: 'school',
    status: 'idle',
    branch: 'main',
    path: '/Users/sabarivasan/Projects/school-crm',
    activeTasks: 0
  },
  {
    id: 'billing-saas',
    name: 'Billing SaaS',
    icon: 'attach_money',
    status: 'offline',
    branch: 'release/v2.1',
    path: '/Users/sabarivasan/Projects/billing-saas',
    activeTasks: 0
  }
];

let connectedDevices = [
  {
    id: 'dev_macbook_pro',
    name: 'MacBook Pro (M3 Max)',
    type: 'laptop',
    ip: localIp,
    status: 'online',
    isCurrent: true,
    lastSeen: new Date().toISOString()
  },
  {
    id: 'dev_windows_pc',
    name: 'Windows Desktop Workstation',
    type: 'desktop',
    ip: '192.168.1.142',
    status: 'online',
    isCurrent: false,
    lastSeen: new Date(Date.now() - 3600000).toISOString()
  },
  {
    id: 'dev_vps_server',
    name: 'Cloud Build VPS',
    type: 'server',
    ip: '10.0.0.88',
    status: 'offline',
    isCurrent: false,
    lastSeen: new Date(Date.now() - 86400000).toISOString()
  }
];

let pendingApprovals = [
  {
    id: 'req_' + Date.now(),
    type: 'terminal_command',
    title: 'Execute Terminal Command',
    description: 'npm install @supabase/supabase-js jsonwebtoken bcrypt',
    riskLevel: 'medium', // 'low' | 'medium' | 'high'
    project: 'ecommerce-admin',
    device: 'MacBook Pro (M3 Max)',
    createdAt: new Date().toISOString(),
    details: {
      command: 'npm install @supabase/supabase-js jsonwebtoken bcrypt',
      workingDirectory: '/Users/sabarivasan/Projects/ecommerce-admin',
      impact: 'Will modify package.json and package-lock.json and download 18 packages.'
    }
  }
];

let activityHistory = [
  {
    id: 'act_1',
    type: 'file_edit',
    title: 'Created Login.tsx component',
    description: 'Added modern OAuth2 login card with glassmorphism layout',
    project: 'ecommerce-admin',
    timestamp: new Date(Date.now() - 600000).toISOString(),
    status: 'success',
    diff: '+ export const LoginCard = () => { ... }'
  },
  {
    id: 'act_2',
    type: 'terminal_command',
    title: 'Executed npm run test:unit',
    description: 'Ran 24 unit tests for user authentication flow',
    project: 'ecommerce-admin',
    timestamp: new Date(Date.now() - 300000).toISOString(),
    status: 'success',
    diff: 'PASS src/tests/auth.test.ts (24 tests passed in 1.4s)'
  },
  {
    id: 'act_3',
    type: 'approval_granted',
    title: 'Permission Approved: Database Migration',
    description: 'Applied migration: 20260815_add_users_table.sql',
    project: 'ecommerce-admin',
    timestamp: new Date(Date.now() - 120000).toISOString(),
    status: 'success',
    diff: 'ALTER TABLE users ADD COLUMN oauth_provider VARCHAR(50);'
  }
];

// Broadcast WebSocket message to all connected clients
function broadcast(type, payload) {
  const msg = JSON.stringify({ type, timestamp: new Date().toISOString(), payload });
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });
}

// WebSocket Connection Management
wss.on('connection', (ws, req) => {
  console.log(`[WebSocket] Mobile client connected from ${req.socket.remoteAddress}`);

  // Send initial state dump
  ws.send(JSON.stringify({
    type: 'INITIAL_STATE',
    payload: {
      agentState,
      activeProjects,
      connectedDevices,
      pendingApprovals,
      activityHistory
    }
  }));

  ws.on('message', (data) => {
    try {
      const parsed = JSON.parse(data.toString());
      console.log(`[WebSocket] Received:`, parsed);

      handleClientMessage(parsed, ws);
    } catch (e) {
      console.error('[WebSocket] Parse error:', e.message);
    }
  });

  ws.on('close', () => {
    console.log('[WebSocket] Mobile client disconnected');
  });
});

function handleClientMessage(msg, ws) {
  const { type, payload } = msg;

  switch (type) {
    case 'DECIDE_APPROVAL': {
      const { approvalId, decision, reason } = payload; // decision: 'ALLOW_ONCE' | 'ALWAYS_ALLOW' | 'DENY'
      const foundIdx = pendingApprovals.findIndex(a => a.id === approvalId);
      if (foundIdx !== -1) {
        const approval = pendingApprovals[foundIdx];
        pendingApprovals.splice(foundIdx, 1);

        const isApproved = decision === 'ALLOW_ONCE' || decision === 'ALWAYS_ALLOW';
        activityHistory.unshift({
          id: 'act_' + Date.now(),
          type: isApproved ? 'approval_granted' : 'approval_denied',
          title: isApproved ? `Approved: ${approval.title}` : `Denied: ${approval.title}`,
          description: approval.description,
          project: approval.project,
          timestamp: new Date().toISOString(),
          status: isApproved ? 'success' : 'cancelled'
        });

        agentState.status = isApproved ? 'working' : 'idle';
        agentState.currentAction = isApproved ? `Executing approved action: ${approval.description}` : 'Idle - awaiting next command';
        agentState.progress = isApproved ? 82 : agentState.progress;

        broadcast('APPROVAL_RESOLVED', { approvalId, decision, reason });
        broadcast('AGENT_STATUS_UPDATED', agentState);
        broadcast('ACTIVITY_ADDED', activityHistory[0]);
      }
      break;
    }

    case 'SEND_INSTRUCTION': {
      const { instruction, source } = payload; // source: 'voice' | 'quick_command' | 'text'
      activityHistory.unshift({
        id: 'act_' + Date.now(),
        type: 'user_instruction',
        title: `Instruction: "${instruction}"`,
        description: `Triggered via ${source || 'mobile'}`,
        project: agentState.activeProject,
        timestamp: new Date().toISOString(),
        status: 'success'
      });

      agentState.status = 'working';
      agentState.currentTask = instruction;
      agentState.currentAction = `Processing: ${instruction}`;
      agentState.progress = 15;

      broadcast('AGENT_STATUS_UPDATED', agentState);
      broadcast('ACTIVITY_ADDED', activityHistory[0]);

      // Simulate step progression
      simulateTaskProgression(instruction);
      break;
    }

    case 'AGENT_CONTROL': {
      const { action } = payload; // 'pause' | 'resume' | 'stop' | 'retry'
      if (action === 'pause') {
        agentState.status = 'paused';
        agentState.currentAction = 'Agent paused by user from mobile';
      } else if (action === 'resume') {
        agentState.status = 'working';
        agentState.currentAction = 'Resumed task';
      } else if (action === 'stop') {
        agentState.status = 'idle';
        agentState.currentTask = 'None';
        agentState.currentAction = 'Agent stopped by user';
        agentState.progress = 0;
      } else if (action === 'retry') {
        agentState.status = 'working';
        agentState.progress = 10;
        agentState.currentAction = 'Retrying current task';
      }
      broadcast('AGENT_STATUS_UPDATED', agentState);
      break;
    }

    case 'SELECT_PROJECT': {
      const { projectId } = payload;
      const proj = activeProjects.find(p => p.id === projectId);
      if (proj) {
        agentState.activeProject = proj.id;
        broadcast('AGENT_STATUS_UPDATED', agentState);
      }
      break;
    }
  }
}

function simulateTaskProgression(task) {
  setTimeout(() => {
    if (agentState.status === 'working') {
      agentState.progress = 45;
      agentState.currentAction = 'Generated test cases and updated routes';
      broadcast('AGENT_STATUS_UPDATED', agentState);
      broadcast('ACTIVITY_ADDED', {
        id: 'act_' + Date.now(),
        type: 'file_edit',
        title: 'Updated routes/api.ts',
        description: 'Added endpoint handlers and validation schema',
        project: agentState.activeProject,
        timestamp: new Date().toISOString(),
        status: 'success'
      });
    }
  }, 2500);

  setTimeout(() => {
    if (agentState.status === 'working') {
      agentState.progress = 75;
      agentState.currentAction = 'Running automated verification';
      broadcast('AGENT_STATUS_UPDATED', agentState);
    }
  }, 5000);

  setTimeout(() => {
    if (agentState.status === 'working') {
      agentState.progress = 100;
      agentState.status = 'completed';
      agentState.currentAction = `Successfully completed: ${task}`;
      broadcast('AGENT_STATUS_UPDATED', agentState);
      broadcast('ACTIVITY_ADDED', {
        id: 'act_' + Date.now(),
        type: 'task_complete',
        title: 'Task Completed Successfully',
        description: task,
        project: agentState.activeProject,
        timestamp: new Date().toISOString(),
        status: 'success'
      });
    }
  }, 7500);
}

// REST Endpoints
app.get('/api/v1/health', (req, res) => {
  res.json({
    status: 'ok',
    version: '1.0.0',
    computerName,
    ip: localIp,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/v1/status', (req, res) => {
  res.json({
    agentState,
    activeProjects,
    connectedDevices,
    pendingApprovalsCount: pendingApprovals.length
  });
});

app.get('/api/v1/approvals', (req, res) => {
  res.json(pendingApprovals);
});

app.post('/api/v1/approvals/:id/decide', (req, res) => {
  const { id } = req.params;
  const { decision, reason } = req.body;
  handleClientMessage({
    type: 'DECIDE_APPROVAL',
    payload: { approvalId: id, decision, reason }
  });
  res.json({ success: true, approvalId: id, decision });
});

app.post('/api/v1/commands', (req, res) => {
  const { instruction, source } = req.body;
  handleClientMessage({
    type: 'SEND_INSTRUCTION',
    payload: { instruction, source }
  });
  res.json({ success: true });
});

app.post('/api/v1/agent/:action', (req, res) => {
  const { action } = req.params;
  handleClientMessage({
    type: 'AGENT_CONTROL',
    payload: { action }
  });
  res.json({ success: true, action });
});

app.get('/api/v1/projects', (req, res) => {
  res.json(activeProjects);
});

app.get('/api/v1/devices', (req, res) => {
  res.json(connectedDevices);
});

app.get('/api/v1/history', (req, res) => {
  res.json(activityHistory);
});

// Trigger a realistic test approval scenario
app.post('/api/v1/simulate/permission-request', (req, res) => {
  const newReq = {
    id: 'req_' + Date.now(),
    type: req.body.type || 'terminal_command',
    title: req.body.title || 'Execute Terminal Command',
    description: req.body.description || 'npx prisma migrate dev --name init',
    riskLevel: req.body.riskLevel || 'high',
    project: agentState.activeProject,
    device: 'MacBook Pro (M3 Max)',
    createdAt: new Date().toISOString(),
    details: {
      command: req.body.command || 'npx prisma migrate dev --name init',
      workingDirectory: '/Users/sabarivasan/Projects/ecommerce-admin',
      impact: 'Will apply schema migration and execute database alter commands.'
    }
  };
  pendingApprovals.push(newReq);
  agentState.status = 'waitingForApproval';
  agentState.currentAction = `Awaiting approval for: ${newReq.title}`;
  broadcast('NEW_APPROVAL_REQUEST', newReq);
  broadcast('AGENT_STATUS_UPDATED', agentState);
  res.json({ success: true, request: newReq });
});

// Pairing payload
const pairingPayload = JSON.stringify({
  version: '1.0',
  protocol: 'antigravity-bridge',
  host: localIp,
  port: PORT,
  token: pairingToken,
  deviceName: computerName,
  wsUrl: `ws://${localIp}:${PORT}/ws`,
  httpUrl: `http://${localIp}:${PORT}/api/v1`
});

// Start Server
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n======================================================');
  console.log('🚀 ANTIGRAVITY COMPANION SERVER RUNNING');
  console.log('======================================================');
  console.log(`💻 Host: ${computerName}`);
  console.log(`🌐 HTTP API: http://${localIp}:${PORT}/api/v1`);
  console.log(`⚡ WebSocket: ws://${localIp}:${PORT}/ws`);
  console.log(`🔑 Pairing Token: ${pairingToken}`);
  console.log('\n📱 SCAN THIS QR CODE IN THE FLUTTER COMPANION APP:\n');
  qrcode.generate(pairingPayload, { small: true });
  console.log('======================================================\n');
});
