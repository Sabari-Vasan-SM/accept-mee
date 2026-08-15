#!/usr/bin/env node
'use strict';

/**
 * Writes an Antigravity hooks.json that points at this repo's hook.js.
 *
 *   node install-hook.js --project /path/to/your/project   → <project>/.agents/hooks.json
 *   node install-hook.js --global                          → ~/.gemini/antigravity-cli/hooks.json
 *
 * An existing hooks.json is merged, not clobbered: we only add/replace our own
 * top-level "antigravity-companion" policy and back the file up first.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');

const POLICY_NAME = 'antigravity-companion';
const HOOK_PATH = path.resolve(__dirname, 'hook.js');
const TIMEOUT_SECONDS = Number(process.env.ANTIGRAVITY_HOOK_TIMEOUT_SECONDS) || 120;

function parseArgs(argv) {
  const args = { project: null, global: false, matcher: '*' };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--project') args.project = argv[i + 1];
    else if (argv[i] === '--global') args.global = true;
    else if (argv[i] === '--matcher') args.matcher = argv[i + 1];
  }
  return args;
}

function targetFile({ project, global: isGlobal }) {
  if (isGlobal) {
    return path.join(os.homedir(), '.gemini', 'antigravity-cli', 'hooks.json');
  }
  if (!project) return null;
  return path.join(path.resolve(project), '.agents', 'hooks.json');
}

function buildPolicy(matcher) {
  return {
    PreToolUse: [
      {
        matcher,
        hooks: [
          {
            type: 'command',
            command: `node ${HOOK_PATH} pre`,
            timeout: TIMEOUT_SECONDS,
          },
        ],
      },
    ],
    PostToolUse: [
      {
        matcher,
        hooks: [
          {
            type: 'command',
            command: `node ${HOOK_PATH} post`,
            timeout: 10,
          },
        ],
      },
    ],
  };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const file = targetFile(args);

  if (!file) {
    console.error('Usage: node install-hook.js --project /path/to/project   (or --global)');
    console.error('Optional: --matcher "run_command|write_file"   (default "*" = every tool)');
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(file), { recursive: true });

  let existing = {};
  if (fs.existsSync(file)) {
    try {
      existing = JSON.parse(fs.readFileSync(file, 'utf8'));
    } catch {
      console.error(`Refusing to overwrite ${file}: it exists but is not valid JSON.`);
      process.exit(1);
    }
    const backup = `${file}.backup-${Date.now()}`;
    fs.copyFileSync(file, backup);
    console.log(`Backed up existing config to ${backup}`);
  }

  existing[POLICY_NAME] = buildPolicy(args.matcher);
  fs.writeFileSync(file, `${JSON.stringify(existing, null, 2)}\n`);

  console.log(`Installed the companion hook into ${file}`);
  console.log(`  matcher:  ${args.matcher}`);
  console.log(`  hook:     node ${HOOK_PATH} pre`);
  console.log(`  timeout:  ${TIMEOUT_SECONDS}s`);
  console.log('\nRestart Antigravity (or the CLI) so it reloads hooks.json.');
  console.log('Then start the companion server: npm start');
}

main();
