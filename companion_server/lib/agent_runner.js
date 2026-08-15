'use strict';

const { spawn } = require('child_process');
const { EventEmitter } = require('events');
const { sanitize } = require('./risk');

/**
 * Dispatches instructions from the phone by starting a real agent process.
 *
 * Important limitation, and the reason this is configuration rather than magic:
 * Antigravity exposes no way to inject a prompt into an *already running*
 * session. Hooks are inbound only. So "send instruction" starts a NEW headless
 * agent run in the active project.
 *
 * You must tell the server how to start one, because the flag differs between
 * the Antigravity CLI, the Python SDK, and whatever wrapper you use:
 *
 *   export ANTIGRAVITY_AGENT_CMD="antigravity"
 *   export ANTIGRAVITY_AGENT_ARGS='["--headless","--prompt","{instruction}"]'
 *
 * {instruction} is substituted verbatim into a single argv slot. The command is
 * spawned WITHOUT a shell, so an instruction containing quotes, semicolons or
 * backticks is passed as one opaque argument and cannot inject a second command.
 */
class AgentRunner extends EventEmitter {
  constructor(env = process.env) {
    super();
    this.command = env.ANTIGRAVITY_AGENT_CMD || null;
    this.argsTemplate = AgentRunner._parseArgs(env.ANTIGRAVITY_AGENT_ARGS);
    /** @type {import('child_process').ChildProcess|null} */
    this._child = null;
    this._lastInstruction = null;
  }

  static _parseArgs(raw) {
    if (!raw) return ['{instruction}'];
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.every((a) => typeof a === 'string')) return parsed;
    } catch {
      // fall through
    }
    console.warn('[agent] ANTIGRAVITY_AGENT_ARGS is not a JSON array of strings; ignoring it.');
    return ['{instruction}'];
  }

  get configured() {
    return typeof this.command === 'string' && this.command.trim() !== '';
  }

  get running() {
    return this._child !== null;
  }

  get lastInstruction() {
    return this._lastInstruction;
  }

  /**
   * @returns {{ok: true, pid: number} | {ok: false, error: string, message: string}}
   */
  run(instruction, cwd) {
    if (!this.configured) {
      return {
        ok: false,
        error: 'agent_not_configured',
        message:
          'No agent command configured. Set ANTIGRAVITY_AGENT_CMD (and optionally ' +
          'ANTIGRAVITY_AGENT_ARGS) so the server knows how to start a headless run.',
      };
    }
    if (this.running) {
      return {
        ok: false,
        error: 'agent_busy',
        message: 'An agent run started from this app is already in progress. Stop it first.',
      };
    }

    const args = this.argsTemplate.map((a) => a.replace('{instruction}', instruction));

    let child;
    try {
      child = spawn(this.command, args, {
        cwd: cwd || process.cwd(),
        shell: false, // never a shell — see the class comment
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (err) {
      return { ok: false, error: 'spawn_failed', message: err.message };
    }

    this._child = child;
    this._lastInstruction = { instruction, cwd };
    this.emit('started', { instruction, cwd, pid: child.pid });

    const forward = (stream, status) => {
      let buffer = '';
      stream.setEncoding('utf8');
      stream.on('data', (chunk) => {
        buffer += chunk;
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';
        for (const line of lines) {
          if (line.trim() === '') continue;
          this.emit('output', { line: sanitize(line), status });
        }
      });
      stream.on('end', () => {
        if (buffer.trim() !== '') this.emit('output', { line: sanitize(buffer), status });
      });
    };

    forward(child.stdout, 'success');
    forward(child.stderr, 'warning');

    child.on('error', (err) => {
      this._child = null;
      this.emit('finished', { ok: false, message: err.message, code: null });
    });

    child.on('close', (code, signal) => {
      this._child = null;
      this.emit('finished', {
        ok: code === 0,
        code,
        signal,
        message:
          signal !== null
            ? `Agent run stopped (${signal})`
            : code === 0
              ? 'Agent run finished'
              : `Agent run exited with code ${code}`,
      });
    });

    return { ok: true, pid: child.pid };
  }

  retry() {
    if (!this._lastInstruction) {
      return { ok: false, error: 'nothing_to_retry', message: 'No previous instruction to retry.' };
    }
    return this.run(this._lastInstruction.instruction, this._lastInstruction.cwd);
  }

  stop() {
    if (!this._child) return false;
    this._child.kill('SIGTERM');
    const child = this._child;
    // Escalate if it ignores SIGTERM.
    const timer = setTimeout(() => {
      if (!child.killed) child.kill('SIGKILL');
    }, 5000);
    if (typeof timer.unref === 'function') timer.unref();
    return true;
  }
}

module.exports = { AgentRunner };
