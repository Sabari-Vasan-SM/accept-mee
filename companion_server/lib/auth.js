'use strict';

const crypto = require('crypto');
const fs = require('fs');
const { ensureConfigDir, configFile } = require('./paths');

const TOKEN_FILE = configFile('token');

/**
 * The pairing token is persisted so that restarting the server does not
 * invalidate an already-paired phone. Pass --reset-token (or set
 * ANTIGRAVITY_RESET_TOKEN=1) to rotate it, which un-pairs every device.
 */
function loadOrCreateToken({ reset = false } = {}) {
  ensureConfigDir();

  if (!reset) {
    try {
      const existing = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
      if (existing.length >= 32) return existing;
    } catch {
      // fall through and mint a new one
    }
  }

  const token = crypto.randomBytes(32).toString('hex');
  fs.writeFileSync(TOKEN_FILE, `${token}\n`, { mode: 0o600 });
  return token;
}

/** Constant-time compare so the token can't be guessed byte-by-byte by timing. */
function tokenMatches(expected, provided) {
  if (typeof provided !== 'string' || provided.length === 0) return false;
  const a = Buffer.from(expected);
  const b = Buffer.from(provided);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function extractToken(req) {
  const header = req.headers?.authorization;
  if (typeof header === 'string' && header.startsWith('Bearer ')) {
    return header.slice(7).trim();
  }
  if (typeof req.headers?.['x-antigravity-token'] === 'string') {
    return req.headers['x-antigravity-token'].trim();
  }
  return null;
}

/** Express middleware. Every route except /health requires the token. */
function requireToken(expected) {
  return (req, res, next) => {
    if (tokenMatches(expected, extractToken(req))) return next();
    res.status(401).json({
      error: 'unauthorized',
      message: 'Missing or invalid pairing token. Re-pair by scanning the QR code.',
    });
  };
}

/** WebSocket upgrade check — the token arrives as a query parameter. */
function tokenFromUpgradeUrl(url) {
  try {
    const parsed = new URL(url, 'http://localhost');
    return parsed.searchParams.get('token');
  } catch {
    return null;
  }
}

module.exports = {
  TOKEN_FILE,
  loadOrCreateToken,
  tokenMatches,
  extractToken,
  requireToken,
  tokenFromUpgradeUrl,
};
