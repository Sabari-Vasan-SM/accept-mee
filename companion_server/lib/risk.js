'use strict';

/**
 * Risk classification for a tool call.
 *
 * These are heuristics, not a security boundary — a determined agent can phrase
 * a destructive command so it scores low. They exist to colour the approval
 * card so the human glancing at a phone notices the dangerous ones. The human
 * is the security boundary.
 */

const HIGH_RISK = [
  { re: /\brm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s+)+/, why: 'Recursive or forced file deletion' },
  { re: /\bsudo\b/, why: 'Runs with administrator privileges' },
  { re: /\bmkfs\b|\bdd\s+if=/, why: 'Writes directly to a disk device' },
  { re: /\bgit\s+push\b.*(--force|-f)\b/, why: 'Force-push can destroy remote history' },
  { re: /\bgit\s+reset\s+--hard\b/, why: 'Discards uncommitted work' },
  { re: /\bgit\s+clean\s+-[a-zA-Z]*f/, why: 'Deletes untracked files' },
  { re: /\bDROP\s+(TABLE|DATABASE|SCHEMA)\b/i, why: 'Destroys database objects' },
  { re: /\bTRUNCATE\s+TABLE\b/i, why: 'Empties a database table' },
  { re: /\b(migrate|migration)\b.*\b(deploy|up|run|reset)\b/i, why: 'Applies a schema migration' },
  { re: /\bcurl\b[^|]*\|\s*(ba)?sh\b|\bwget\b[^|]*\|\s*(ba)?sh\b/, why: 'Pipes a remote script straight into a shell' },
  { re: /\bchmod\s+(-R\s+)?777\b/, why: 'Makes files world-writable' },
  { re: /\bkillall\b|\bpkill\b/, why: 'Terminates running processes' },
  { re: /\b(aws|gcloud|az)\s+.*\b(delete|destroy|rm)\b/, why: 'Deletes cloud infrastructure' },
  { re: /\bterraform\s+(destroy|apply)\b/, why: 'Changes live infrastructure' },
  { re: /\bdocker\s+(system\s+prune|rm|rmi)\b/, why: 'Removes containers or images' },
  { re: /\b(npm|yarn|pnpm)\s+publish\b/, why: 'Publishes a package publicly' },
];

const MEDIUM_RISK = [
  { re: /\b(npm|yarn|pnpm|pip|pip3|gem|cargo|go)\s+(install|add|get)\b/, why: 'Installs third-party dependencies' },
  { re: /\bgit\s+(push|commit|merge|rebase|checkout)\b/, why: 'Changes version control state' },
  { re: /\bdocker\b/, why: 'Interacts with containers' },
  { re: /\b(systemctl|service)\b/, why: 'Changes a system service' },
  { re: /\b(curl|wget|http|fetch)\b/, why: 'Makes a network request' },
  { re: /\bmv\b|\bcp\s+-[a-zA-Z]*r/, why: 'Moves or copies files in bulk' },
  { re: /\b(npm|yarn|pnpm)\s+run\s+(build|deploy|start)\b/, why: 'Runs a build or deploy script' },
  { re: /\.env\b|\bsecrets?\b|\bcredentials?\b/i, why: 'Touches secrets or credentials' },
];

const LOW_RISK_TOOLS = new Set([
  'view_file',
  'read_file',
  'list_directory',
  'grep_search',
  'codebase_search',
  'find_by_name',
  'view_code_item',
  'read_url_content',
]);

const WRITE_TOOLS = new Set([
  'write_file',
  'edit_file',
  'replace_file_content',
  'create_file',
  'multi_edit',
]);

const DELETE_TOOLS = new Set(['delete_file', 'remove_file']);

/**
 * @returns {{level: 'low'|'medium'|'high', reasons: string[]}}
 */
function classify({ tool, command = '', target = '' }) {
  const reasons = [];
  const haystack = `${command} ${target}`.trim();

  if (DELETE_TOOLS.has(tool)) {
    return { level: 'high', reasons: ['Deletes a file from disk'] };
  }

  for (const { re, why } of HIGH_RISK) {
    if (re.test(haystack)) reasons.push(why);
  }
  if (reasons.length > 0) return { level: 'high', reasons };

  for (const { re, why } of MEDIUM_RISK) {
    if (re.test(haystack)) reasons.push(why);
  }
  if (reasons.length > 0) return { level: 'medium', reasons };

  if (WRITE_TOOLS.has(tool)) {
    return { level: 'medium', reasons: ['Modifies a file on disk'] };
  }
  if (LOW_RISK_TOOLS.has(tool)) {
    return { level: 'low', reasons: ['Read-only operation'] };
  }

  return { level: 'medium', reasons: ['Unrecognised tool — review before allowing'] };
}

/** Mask obvious secrets before a command is shown on a phone screen. */
function sanitize(text) {
  if (typeof text !== 'string') return '';
  return text
    .replace(/((?:api[-_]?key|token|password|passwd|secret|bearer)\s*[=:]\s*)(\S+)/gi, '$1******')
    .replace(/\b(gh[pousr]_[A-Za-z0-9]{16,})\b/g, '******')
    .replace(/\b(sk-[A-Za-z0-9]{16,})\b/g, '******')
    .replace(/\b(AKIA[0-9A-Z]{12,})\b/g, '******');
}

module.exports = { classify, sanitize };
