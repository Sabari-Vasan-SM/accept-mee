'use strict';

const { EventEmitter } = require('events');
const { toPermissionRequest, publicView } = require('./toolmap');
const { RuleStore } = require('./rules');

/**
 * The approval broker.
 *
 * An Antigravity PreToolUse hook POSTs a tool call here and the HTTP response
 * is deliberately NOT sent — it is parked until a phone answers, the request
 * times out, or the hook process goes away. That parked response is what makes
 * the agent on the desktop actually wait for you.
 *
 * Decisions are the Antigravity vocabulary: 'allow' | 'deny' | 'ask'.
 * 'ask' means "we couldn't reach a human, fall back to the IDE's own prompt" —
 * it is the safe outcome for a timeout, never a silent allow.
 */
class ApprovalBroker extends EventEmitter {
  /**
   * @param {object} opts
   * @param {string} opts.deviceName
   * @param {number} opts.timeoutMs How long a request waits for a human.
   * @param {RuleStore} [opts.rules]
   */
  constructor({ deviceName, timeoutMs = 120000, rules = new RuleStore() }) {
    super();
    this.deviceName = deviceName;
    this.timeoutMs = timeoutMs;
    this.rules = rules;

    /** @type {Map<string, {request: object, resolve: Function, timer: NodeJS.Timeout, settled: boolean}>} */
    this._pending = new Map();

    /** When true every new request is auto-denied (the phone's STOP button). */
    this._killSwitch = false;
    /** When true auto-allow rules are ignored, so everything reaches the phone. */
    this._paused = false;

    this._seq = 0;
  }

  get pending() {
    return [...this._pending.values()].map((entry) => publicView(entry.request));
  }

  get pendingCount() {
    return this._pending.size;
  }

  get isStopped() {
    return this._killSwitch;
  }

  get isPaused() {
    return this._paused;
  }

  setStopped(value) {
    this._killSwitch = Boolean(value);
    if (this._killSwitch) {
      // Release everything already waiting — the agent should unwind now.
      for (const id of [...this._pending.keys()]) {
        this._settle(id, 'deny', 'Stopped from the companion app');
      }
    }
    this.emit('modeChanged', { stopped: this._killSwitch, paused: this._paused });
  }

  setPaused(value) {
    this._paused = Boolean(value);
    this.emit('modeChanged', { stopped: this._killSwitch, paused: this._paused });
  }

  _nextId() {
    this._seq += 1;
    return `req_${Date.now().toString(36)}_${this._seq}`;
  }

  /**
   * Submit a tool call for approval.
   *
   * Returns the id synchronously alongside the promise, because the HTTP layer
   * needs the id to abandon the request if the hook process dies while waiting.
   *
   * @returns {{requestId: string, promise: Promise<{decision: string, reason: string, requestId: string, auto?: string}>}}
   */
  submit(payload) {
    const requestId = this._nextId();
    const request = toPermissionRequest({ ...payload, requestId }, this.deviceName);

    if (this._killSwitch) {
      const outcome = {
        decision: 'deny',
        reason: 'Agent stopped from the companion app',
        requestId,
        auto: 'stopped',
      };
      this.emit('autoDecided', { request, outcome });
      return { requestId, promise: Promise.resolve(outcome) };
    }

    if (!this._paused && this.rules.isAllowed(request._ruleKey)) {
      const outcome = {
        decision: 'allow',
        reason: 'Matched a saved "always allow" rule',
        requestId,
        auto: 'rule',
      };
      this.emit('autoDecided', { request, outcome });
      return { requestId, promise: Promise.resolve(outcome) };
    }

    const promise = new Promise((resolve) => {
      const timer = setTimeout(() => {
        // No human answered. Hand control back to the IDE rather than guessing.
        this._settle(
          requestId,
          'ask',
          'No response from the companion app — falling back to the desktop prompt',
        );
      }, this.timeoutMs);

      // Deliberately NOT unref'd: while a request is pending we are blocking a
      // real agent, so the process must stay alive to answer it.

      this._pending.set(requestId, { request, resolve, timer, settled: false });
      this.emit('requestCreated', publicView(request));
    });

    return { requestId, promise };
  }

  /**
   * Answer a pending request. Called from the phone (WS or REST).
   * @param {string} requestId
   * @param {'ALLOW_ONCE'|'ALWAYS_ALLOW'|'DENY'} decision
   */
  decide(requestId, decision, reason) {
    const entry = this._pending.get(requestId);
    if (!entry) return false;

    if (decision === 'ALWAYS_ALLOW') {
      this.rules.allow(entry.request._ruleKey, {
        tool: entry.request._tool,
        title: entry.request.title,
      });
      return this._settle(requestId, 'allow', reason || 'Always allowed from the companion app');
    }
    if (decision === 'ALLOW_ONCE') {
      return this._settle(requestId, 'allow', reason || 'Allowed once from the companion app');
    }
    return this._settle(requestId, 'deny', reason || 'Denied from the companion app');
  }

  /** The hook process died (agent cancelled, timeout hit on their side). */
  abandon(requestId) {
    const entry = this._pending.get(requestId);
    if (!entry) return false;
    clearTimeout(entry.timer);
    this._pending.delete(entry.request.id);
    entry.settled = true;
    this.emit('requestResolved', {
      approvalId: requestId,
      decision: 'abandoned',
      request: publicView(entry.request),
    });
    return true;
  }

  _settle(requestId, decision, reason) {
    const entry = this._pending.get(requestId);
    if (!entry || entry.settled) return false;

    entry.settled = true;
    clearTimeout(entry.timer);
    this._pending.delete(requestId);

    const outcome = { decision, reason, requestId };
    entry.resolve(outcome);
    this.emit('requestResolved', {
      approvalId: requestId,
      decision,
      reason,
      request: publicView(entry.request),
    });
    return true;
  }
}

module.exports = { ApprovalBroker };
