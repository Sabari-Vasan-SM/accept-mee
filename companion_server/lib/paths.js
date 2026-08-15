'use strict';

const os = require('os');
const path = require('path');
const fs = require('fs');

/**
 * Everything the server persists lives under ~/.antigravity-companion.
 * The directory is created 0700 because it holds the pairing token.
 */
const CONFIG_DIR =
  process.env.ANTIGRAVITY_COMPANION_HOME ||
  path.join(os.homedir(), '.antigravity-companion');

function ensureConfigDir() {
  fs.mkdirSync(CONFIG_DIR, { recursive: true, mode: 0o700 });
  return CONFIG_DIR;
}

function configFile(name) {
  return path.join(CONFIG_DIR, name);
}

function readJson(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return fallback;
  }
}

function writeJson(file, value) {
  ensureConfigDir();
  const tmp = `${file}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(value, null, 2), { mode: 0o600 });
  fs.renameSync(tmp, file);
}

module.exports = { CONFIG_DIR, ensureConfigDir, configFile, readJson, writeJson };
