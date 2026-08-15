'use strict';

/**
 * Rolling log of things that really happened, fed by PostToolUse hook events,
 * approval decisions, and output from agent runs we started ourselves.
 */

const MAX_EVENTS = 300;

function typeForTool(tool, hasCommand) {
  if (hasCommand) {
    return /\btest\b|jest|pytest|vitest|go test|flutter test/i.test(tool) ? 'test_run' : 'terminal_command';
  }
  if (/write|edit|create|replace|delete/i.test(tool)) return 'file_edit';
  return 'terminal_command';
}

class ActivityLog {
  constructor(max = MAX_EVENTS) {
    this._events = [];
    this._max = max;
    this._seq = 0;
  }

  list() {
    return this._events;
  }

  add({ type, title, description = '', project = 'workspace', status = 'success', diff = null }) {
    this._seq += 1;
    const event = {
      id: `act_${Date.now().toString(36)}_${this._seq}`,
      type,
      title,
      description,
      project,
      timestamp: new Date().toISOString(),
      status,
      diff,
    };
    this._events.unshift(event);
    if (this._events.length > this._max) this._events.length = this._max;
    return event;
  }

  clear() {
    this._events = [];
  }
}

module.exports = { ActivityLog, typeForTool };
