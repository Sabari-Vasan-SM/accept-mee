'use strict';

const path = require('path');
const fs = require('fs');
const { execFile } = require('child_process');

/**
 * Real project data, derived from the workspace paths that Antigravity reports
 * in every hook payload. Nothing here is seeded — a project only exists once
 * the agent has actually touched it.
 */

function gitBranch(dir) {
  return new Promise((resolve) => {
    execFile(
      'git',
      ['-C', dir, 'rev-parse', '--abbrev-ref', 'HEAD'],
      { timeout: 2000 },
      (err, stdout) => resolve(err ? null : stdout.trim() || null),
    );
  });
}

function iconFor(dir) {
  const has = (f) => fs.existsSync(path.join(dir, f));
  if (has('pubspec.yaml')) return 'flutter_dash';
  if (has('package.json')) return 'javascript';
  if (has('Cargo.toml')) return 'memory';
  if (has('go.mod')) return 'code';
  if (has('requirements.txt') || has('pyproject.toml')) return 'terminal';
  if (has('pom.xml') || has('build.gradle') || has('build.gradle.kts')) return 'coffee';
  return 'folder';
}

class ProjectRegistry {
  constructor() {
    /** @type {Map<string, object>} */
    this._projects = new Map();
    this._activeId = null;
  }

  get activeId() {
    return this._activeId;
  }

  setActive(id) {
    if (!this._projects.has(id)) return false;
    this._activeId = id;
    return true;
  }

  activePath() {
    const project = this._activeId ? this._projects.get(this._activeId) : null;
    return project ? project.path : null;
  }

  list() {
    return [...this._projects.values()].sort((a, b) => b.lastSeenMs - a.lastSeenMs).map((p) => ({
      id: p.id,
      name: p.name,
      icon: p.icon,
      status: p.status,
      branch: p.branch,
      path: p.path,
      activeTasks: p.activeTasks,
    }));
  }

  /**
   * Register (or refresh) a workspace the agent is actually working in.
   * Returns true if the project list changed in a way worth broadcasting.
   */
  async touch(workspacePaths, { status = 'working' } = {}) {
    if (!Array.isArray(workspacePaths) || workspacePaths.length === 0) return false;

    let changed = false;
    for (const dir of workspacePaths) {
      if (typeof dir !== 'string' || dir.trim() === '') continue;

      const id = path.basename(dir);
      const existing = this._projects.get(id);
      const branch = (await gitBranch(dir)) || existing?.branch || 'no branch';

      const next = {
        id,
        name: id.replace(/[-_]/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
        icon: existing?.icon || iconFor(dir),
        status,
        branch,
        path: dir,
        activeTasks: existing?.activeTasks || 0,
        lastSeenMs: Date.now(),
      };

      if (
        !existing ||
        existing.branch !== next.branch ||
        existing.status !== next.status ||
        existing.path !== next.path
      ) {
        changed = true;
      }

      this._projects.set(id, next);
      if (!this._activeId) this._activeId = id;
    }
    return changed;
  }

  /** Mark projects idle when the agent has been quiet in them. */
  ageOut(idleAfterMs = 90000) {
    let changed = false;
    const now = Date.now();
    for (const project of this._projects.values()) {
      const shouldBeIdle = now - project.lastSeenMs > idleAfterMs;
      const nextStatus = shouldBeIdle ? 'idle' : project.status;
      if (project.status !== nextStatus) {
        project.status = nextStatus;
        changed = true;
      }
    }
    return changed;
  }
}

module.exports = { ProjectRegistry, gitBranch };
